/**
 * Centralized logging module for vscode-claude.
 *
 * Provides detailed operation and request logging with:
 *  - Timestamps to the second (YYYY-MM-DD HH:mm:ss)
 *  - Source distinction: "webview" (网页端) vs "local" (本地端/VS Code command)
 *
 * All log entries are written to a dedicated VS Code OutputChannel so the user
 * can inspect them via the "Output" panel (select "Claude AI Log").
 */

import * as vscode from "vscode";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Where the operation originated. */
export type LogSource = "local" | "webview";

export type LogLevel = "INFO" | "WARN" | "ERROR" | "DEBUG";

// ---------------------------------------------------------------------------
// Singleton logger
// ---------------------------------------------------------------------------

let outputChannel: vscode.OutputChannel | undefined;

/**
 * Initialise the logger.  Must be called once during extension activation.
 * Returns the output channel so it can be added to `context.subscriptions`.
 */
export function initLogger(): vscode.OutputChannel {
  if (!outputChannel) {
    outputChannel = vscode.window.createOutputChannel("Claude AI Log");
  }
  return outputChannel;
}

// ---------------------------------------------------------------------------
// Timestamp helper
// ---------------------------------------------------------------------------

/**
 * Format the current time as `YYYY-MM-DD HH:mm:ss` in the local timezone.
 */
function timestamp(): string {
  const now = new Date();
  const pad = (n: number): string => String(n).padStart(2, "0");
  return (
    `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ` +
    `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`
  );
}

// ---------------------------------------------------------------------------
// Core logging function
// ---------------------------------------------------------------------------

function write(
  level: LogLevel,
  source: LogSource,
  message: string,
  detail?: string
): void {
  if (!outputChannel) {
    // Logger not initialised – best effort to stderr so nothing is silently lost.
    console.error(`[Claude][${level}][${source}] ${message}`);
    return;
  }
  const sourceLabel = source === "webview" ? "网页端(webview)" : "本地端(local)";
  const line = `[${timestamp()}] [${level}] [${sourceLabel}] ${message}`;
  outputChannel.appendLine(line);
  if (detail) {
    // Indent detail lines for readability.
    for (const dl of detail.split("\n")) {
      outputChannel.appendLine(`    ${dl}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Public convenience methods
// ---------------------------------------------------------------------------

export function logInfo(source: LogSource, message: string, detail?: string): void {
  write("INFO", source, message, detail);
}

export function logWarn(source: LogSource, message: string, detail?: string): void {
  write("WARN", source, message, detail);
}

export function logError(source: LogSource, message: string, detail?: string): void {
  write("ERROR", source, message, detail);
}

export function logDebug(source: LogSource, message: string, detail?: string): void {
  write("DEBUG", source, message, detail);
}

// ---------------------------------------------------------------------------
// Specialised helpers
// ---------------------------------------------------------------------------

/**
 * Log an API request being sent to Claude.
 */
export function logApiRequest(
  source: LogSource,
  params: {
    model: string;
    maxTokens: number;
    temperature: number;
    messageCount: number;
    stream: boolean;
  }
): void {
  const detail = [
    `model=${params.model}`,
    `maxTokens=${params.maxTokens}`,
    `temperature=${params.temperature}`,
    `messages=${params.messageCount}`,
    `stream=${params.stream}`,
  ].join(", ");
  logInfo(source, `API request → Anthropic (${params.model})`, detail);
}

/**
 * Log an API response received from Claude.
 */
export function logApiResponse(
  source: LogSource,
  params: {
    inputTokens: number;
    outputTokens: number;
    stopReason?: string;
    durationMs?: number;
  }
): void {
  const parts = [
    `inputTokens=${params.inputTokens}`,
    `outputTokens=${params.outputTokens}`,
  ];
  if (params.stopReason) {
    parts.push(`stopReason=${params.stopReason}`);
  }
  if (params.durationMs !== undefined) {
    parts.push(`duration=${params.durationMs}ms`);
  }
  logInfo(source, "API response ← Anthropic", parts.join(", "));
}

/**
 * Log an API error from Claude.
 */
export function logApiError(source: LogSource, error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  logError(source, "API error", message);
}

/**
 * Log a user command invocation.
 */
export function logCommand(source: LogSource, commandName: string, detail?: string): void {
  logInfo(source, `Command: ${commandName}`, detail);
}

/**
 * Log a webview message received from the chat panel.
 */
export function logWebviewMessage(messageType: string, detail?: string): void {
  logInfo("webview", `Webview message received: ${messageType}`, detail);
}
