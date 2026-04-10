/**
 * VS Code extension entry point for vscode-claude.
 *
 * Registers all commands and providers and wires them together with the
 * Claude API client. The overall architecture closely mirrors Qt Creator's
 * AI plugin (qt-creator/src/plugins/aiplugin/aiplugin.cpp):
 *
 *  - A single shared LLM client per session
 *  - Commands that collect editor context and dispatch requests
 *  - A persistent chat panel for interactive conversation
 *  - An optional inline completion provider
 */

import * as vscode from "vscode";
import { ClaudeClient } from "./claudeClient";
import {
  buildSystemPrompt,
  collectEditorContext,
} from "./contextCollector";
import { ChatPanel, buildQuestionWithContext } from "./chatPanel";
import { InlineCompletionProvider } from "./inlineCompletion";
import { initLogger, logCommand, logInfo, logError } from "./logger";

// ---------------------------------------------------------------------------
// Activation
// ---------------------------------------------------------------------------

export function activate(context: vscode.ExtensionContext): void {
  // Initialise the centralised logger.
  const logChannel = initLogger();
  context.subscriptions.push(logChannel);
  logInfo("local", "Extension activated – vscode-claude initialising");

  // Resolve the API key from settings or the environment variable, just as
  // Qt Creator reads its Anthropic key from the plugin settings or env.
  const getApiKey = (): string => {
    const config = vscode.workspace.getConfiguration("vscode-claude");
    return (
      config.get<string>("apiKey", "") ||
      process.env["ANTHROPIC_API_KEY"] ||
      ""
    );
  };

  /**
   * Create (or re-create) a ClaudeClient.  We create a new instance whenever
   * a command is invoked so that key/config changes take effect immediately
   * without requiring a reload – the same approach Qt Creator uses when it
   * reads credentials fresh from settings on every request.
   */
  const createClient = (): ClaudeClient | undefined => {
    const apiKey = getApiKey();
    if (!apiKey) {
      vscode.window
        .showErrorMessage(
          "Claude API key is not configured. Set `vscode-claude.apiKey` in settings or the `ANTHROPIC_API_KEY` environment variable.",
          "Open Settings"
        )
        .then((choice) => {
          if (choice === "Open Settings") {
            vscode.commands.executeCommand(
              "workbench.action.openSettings",
              "vscode-claude.apiKey"
            );
          }
        });
      return undefined;
    }
    return new ClaudeClient(apiKey);
  };

  // ---------------------------------------------------------------------------
  // Command: Open Chat Panel
  // ---------------------------------------------------------------------------
  context.subscriptions.push(
    vscode.commands.registerCommand("vscode-claude.openChat", () => {
      logCommand("local", "openChat", "Opening Claude chat panel");
      const client = createClient();
      if (!client) return;
      ChatPanel.createOrShow(client);
    })
  );

  // ---------------------------------------------------------------------------
  // Command: Ask Claude (free-form question)
  // ---------------------------------------------------------------------------
  context.subscriptions.push(
    vscode.commands.registerCommand("vscode-claude.askClaude", async () => {
      logCommand("local", "askClaude", "Prompting user for a question");
      const client = createClient();
      if (!client) return;

      const question = await vscode.window.showInputBox({
        prompt: "Ask Claude anything",
        placeHolder: "e.g. How do I implement a binary search tree in TypeScript?",
      });
      if (!question) {
        logInfo("local", "askClaude cancelled – no question entered");
        return;
      }

      logInfo("local", "askClaude submitting question", `question="${question.substring(0, 200)}"`);
      const panel = ChatPanel.createOrShow(client);
      await panel.ask(question);
    })
  );

  // ---------------------------------------------------------------------------
  // Command: Explain Code
  // ---------------------------------------------------------------------------
  context.subscriptions.push(
    vscode.commands.registerCommand("vscode-claude.explainCode", async () => {
      logCommand("local", "explainCode", "Explaining selected code");
      const client = createClient();
      if (!client) return;

      const ctx = collectEditorContext(vscode.window.activeTextEditor);
      if (!ctx?.selectedText) {
        logInfo("local", "explainCode cancelled – no code selected");
        vscode.window.showWarningMessage(
          "Please select some code first, then run Explain Code."
        );
        return;
      }

      logInfo("local", "explainCode submitting", `file="${ctx.filePath}", lang=${ctx.languageId}, selectionLength=${ctx.selectedText.length}`);
      const question = buildQuestionWithContext(
        "Please explain the following code in detail. Describe what it does, any important patterns used, and potential issues.",
        ctx
      );

      const panel = ChatPanel.createOrShow(client);
      await panel.ask(question);
    })
  );

  // ---------------------------------------------------------------------------
  // Command: Review Code
  // ---------------------------------------------------------------------------
  context.subscriptions.push(
    vscode.commands.registerCommand("vscode-claude.reviewCode", async () => {
      logCommand("local", "reviewCode", "Reviewing selected code");
      const client = createClient();
      if (!client) return;

      const ctx = collectEditorContext(vscode.window.activeTextEditor);
      if (!ctx?.selectedText) {
        logInfo("local", "reviewCode cancelled – no code selected");
        vscode.window.showWarningMessage(
          "Please select some code first, then run Review Code."
        );
        return;
      }

      logInfo("local", "reviewCode submitting", `file="${ctx.filePath}", lang=${ctx.languageId}, selectionLength=${ctx.selectedText.length}`);
      const question = buildQuestionWithContext(
        "Please review the following code. Identify bugs, security issues, performance concerns, and style improvements. Be specific and concise.",
        ctx
      );

      const panel = ChatPanel.createOrShow(client);
      await panel.ask(question);
    })
  );

  // ---------------------------------------------------------------------------
  // Command: Generate Code
  // ---------------------------------------------------------------------------
  context.subscriptions.push(
    vscode.commands.registerCommand("vscode-claude.generateCode", async () => {
      logCommand("local", "generateCode", "Generating code from description");
      const client = createClient();
      if (!client) return;

      const ctx = collectEditorContext(vscode.window.activeTextEditor);
      const languageId = ctx?.languageId ?? "plaintext";

      const description = await vscode.window.showInputBox({
        prompt: `Describe the ${languageId} code you want Claude to generate`,
        placeHolder:
          "e.g. A function that debounces async calls with a configurable delay",
      });
      if (!description) {
        logInfo("local", "generateCode cancelled – no description entered");
        return;
      }

      logInfo("local", "generateCode submitting", `lang=${languageId}, description="${description.substring(0, 200)}"`);

      const config = vscode.workspace.getConfiguration("vscode-claude");
      const model = config.get<string>("model", "claude-3-5-sonnet-20241022");
      const maxTokens = config.get<number>("maxTokens", 4096);
      const temperature = config.get<number>("temperature", 0.1);

      // Show progress while Claude generates the code.
      await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: "Claude is generating code…",
          cancellable: true,
        },
        async (_, cancelToken) => {
          let generated = "";
          try {
            const messages = [
              {
                role: "user" as const,
                content:
                  `Generate ${languageId} code for the following: ${description}\n\n` +
                  "Return ONLY the code in a fenced code block, with no extra explanation.",
              },
            ];
            for await (const chunk of client.sendMessagesStream(messages, {
              model,
              maxTokens,
              temperature,
              systemPrompt: buildSystemPrompt(),
            })) {
              if (cancelToken.isCancellationRequested) return;
              if (chunk.type === "delta") {
                generated += chunk.text;
              }
            }
          } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            logError("local", "generateCode API error", message);
            vscode.window.showErrorMessage(`Claude error: ${message}`);
            return;
          }

          logInfo("local", "generateCode response received", `generatedLength=${generated.length}`);

          // Strip markdown fences if present, then insert into editor.
          const codeMatch = generated.match(
            /```(?:\w+)?\n([\s\S]+?)\n```/
          );
          const code = codeMatch ? codeMatch[1] : generated.trim();

          const editor = vscode.window.activeTextEditor;
          if (editor) {
            await editor.edit((eb) => {
              eb.replace(editor.selection, code);
            });
          } else {
            // No editor open – show in a new untitled document.
            const doc = await vscode.workspace.openTextDocument({
              content: code,
              language: languageId,
            });
            await vscode.window.showTextDocument(doc);
          }
        }
      );
    })
  );

  // ---------------------------------------------------------------------------
  // Inline completion provider (opt-in)
  // ---------------------------------------------------------------------------
  const registerInlineProvider = (): vscode.Disposable | undefined => {
    const config = vscode.workspace.getConfiguration("vscode-claude");
    if (!config.get<boolean>("enableInlineCompletion", false)) {
      return undefined;
    }
    const apiKey = getApiKey();
    if (!apiKey) return undefined;
    const client = new ClaudeClient(apiKey);
    return vscode.languages.registerInlineCompletionItemProvider(
      { pattern: "**" },
      new InlineCompletionProvider(client)
    );
  };

  let inlineProviderDisposable = registerInlineProvider();
  if (inlineProviderDisposable) {
    context.subscriptions.push(inlineProviderDisposable);
  }

  // Re-register the inline provider when the user changes the config.
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (
        e.affectsConfiguration("vscode-claude.enableInlineCompletion") ||
        e.affectsConfiguration("vscode-claude.apiKey")
      ) {
        inlineProviderDisposable?.dispose();
        inlineProviderDisposable = registerInlineProvider();
        if (inlineProviderDisposable) {
          context.subscriptions.push(inlineProviderDisposable);
        }
      }
    })
  );
}

// ---------------------------------------------------------------------------
// Deactivation
// ---------------------------------------------------------------------------

export function deactivate(): void {
  logInfo("local", "Extension deactivated – vscode-claude shutting down");
  // Nothing to clean up – VS Code disposes context.subscriptions automatically.
}
