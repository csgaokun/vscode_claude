/**
 * Context collector for VS Code.
 *
 * Gathers information about the current editor state (active file, selection,
 * surrounding code) to build rich prompts for Claude.
 *
 * Qt Creator's AI plugin uses a similar "context" concept (see
 * qt-creator/src/plugins/aiplugin/aidocument.cpp) where file metadata and
 * cursor context are bundled into each request.
 */

import * as vscode from "vscode";

export interface EditorContext {
  /** Full text of the active document. */
  fileContent: string;
  /** Selected text, or empty string if nothing is selected. */
  selectedText: string;
  /** Programming language identifier (e.g. "typescript", "cpp"). */
  languageId: string;
  /** File path relative to the workspace root, or the absolute path. */
  filePath: string;
  /** 1-based line number of the cursor. */
  cursorLine: number;
  /** Lines immediately before the cursor (for completion context). */
  prefixLines: string;
  /** Lines immediately after the cursor (for completion context). */
  suffixLines: string;
}

const PREFIX_LINES = 50;
const SUFFIX_LINES = 20;

/**
 * Collect context from the currently active editor.
 *
 * Returns `undefined` when there is no active text editor.
 */
export function collectEditorContext(
  editor: vscode.TextEditor | undefined
): EditorContext | undefined {
  if (!editor) {
    return undefined;
  }

  const document = editor.document;
  const selection = editor.selection;
  const cursorPos = selection.active;

  const selectedText = document.getText(selection);
  const fileContent = document.getText();
  const lines = fileContent.split("\n");

  const prefixStart = Math.max(0, cursorPos.line - PREFIX_LINES);
  const suffixEnd = Math.min(lines.length - 1, cursorPos.line + SUFFIX_LINES);

  const prefixLines = lines.slice(prefixStart, cursorPos.line).join("\n");
  const suffixLines = lines
    .slice(cursorPos.line + 1, suffixEnd + 1)
    .join("\n");

  const workspaceFolders = vscode.workspace.workspaceFolders;
  let filePath = document.uri.fsPath;
  if (workspaceFolders?.length) {
    const root = workspaceFolders[0].uri.fsPath;
    if (filePath.startsWith(root)) {
      filePath = filePath.slice(root.length + 1);
    }
  }

  return {
    fileContent,
    selectedText,
    languageId: document.languageId,
    filePath,
    cursorLine: cursorPos.line + 1,
    prefixLines,
    suffixLines,
  };
}

/**
 * Build a system prompt that describes the assistant's role.
 *
 * Mirrors Qt Creator's pattern of including a brief role description in every
 * system prompt to keep responses focused on software development.
 */
export function buildSystemPrompt(): string {
  return [
    "You are an expert software engineering assistant integrated into Visual Studio Code.",
    "Your responses are concise, accurate, and directly actionable.",
    "When providing code, always specify the language in fenced code blocks.",
    "When explaining code, be specific about what each part does.",
    "Avoid unnecessary preamble or filler text.",
  ].join(" ");
}

/**
 * Format a code block with optional context for inclusion in a prompt.
 */
export function formatCodeBlock(code: string, languageId: string): string {
  return `\`\`\`${languageId}\n${code}\n\`\`\``;
}
