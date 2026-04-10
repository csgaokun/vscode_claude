/**
 * Inline completion provider for Claude.
 *
 * Implements VS Code's InlineCompletionItemProvider interface to offer
 * context-aware code completions via Claude.
 *
 * This mirrors Qt Creator's "ghost text" / inline completion feature that was
 * adapted from Copilot's approach: collect prefix/suffix context, send to the
 * LLM with a fill-in-the-middle prompt, and display the suggestion inline.
 *
 * The provider is only activated when vscode-claude.enableInlineCompletion is
 * true (off by default) to avoid unexpected API charges.
 */

import * as vscode from "vscode";
import { ClaudeClient } from "./claudeClient";
import { collectEditorContext } from "./contextCollector";
import { logInfo, logError } from "./logger";

/** Debounce delay in ms – avoids a request on every keystroke. */
const DEBOUNCE_MS = 600;

export class InlineCompletionProvider
  implements vscode.InlineCompletionItemProvider
{
  private readonly client: ClaudeClient;
  private debounceTimer: ReturnType<typeof setTimeout> | undefined;
  private lastRequestId = 0;

  constructor(client: ClaudeClient) {
    this.client = client;
    this.client.setLogSource("local");
  }

  async provideInlineCompletionItems(
    document: vscode.TextDocument,
    position: vscode.Position,
    _context: vscode.InlineCompletionContext,
    token: vscode.CancellationToken
  ): Promise<vscode.InlineCompletionList | null> {
    // Debounce: cancel the previous timer and set a new one.
    if (this.debounceTimer !== undefined) {
      clearTimeout(this.debounceTimer);
    }

    const requestId = ++this.lastRequestId;

    await new Promise<void>((resolve) => {
      this.debounceTimer = setTimeout(resolve, DEBOUNCE_MS);
    });

    if (token.isCancellationRequested || requestId !== this.lastRequestId) {
      return null;
    }

    const editor = vscode.window.activeTextEditor;
    const ctx = collectEditorContext(editor);
    if (!ctx) {
      return null;
    }

    logInfo("local", "Inline completion request", `file="${ctx.filePath}", lang=${ctx.languageId}, line=${ctx.cursorLine}`);

    const config = vscode.workspace.getConfiguration("vscode-claude");
    const model = config.get<string>("model", "claude-3-5-haiku-20241022");

    // Build a fill-in-the-middle style prompt.
    const prompt =
      `Complete the following ${ctx.languageId} code. ` +
      `Return ONLY the completion text, no explanation, no markdown fences.\n\n` +
      `<prefix>\n${ctx.prefixLines}\n</prefix>\n` +
      `<suffix>\n${ctx.suffixLines}\n</suffix>\n\n` +
      `Completion:`;

    let completion = "";
    try {
      for await (const chunk of this.client.sendMessagesStream(
        [{ role: "user", content: prompt }],
        {
          model,
          maxTokens: 256,
          temperature: 0,
        }
      )) {
        if (token.isCancellationRequested) {
          return null;
        }
        if (chunk.type === "delta") {
          completion += chunk.text;
        }
      }
    } catch {
      // Silently ignore inline completion errors to avoid distracting the user.
      logError("local", "Inline completion failed (suppressed)");
      return null;
    }

    completion = completion.trim();
    if (!completion) {
      logInfo("local", "Inline completion returned empty result");
      return null;
    }

    logInfo("local", "Inline completion result", `completionLength=${completion.length}`);

    return {
      items: [
        new vscode.InlineCompletionItem(
          completion,
          new vscode.Range(position, position)
        ),
      ],
    };
  }
}
