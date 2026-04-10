/**
 * Claude chat webview panel.
 *
 * Provides a sidebar-style HTML/CSS/JS chat panel similar to the floating
 * "AI chat" window in Qt Creator's AI plugin.  The webview uses VS Code's
 * webview API so it respects the active theme and can communicate with the
 * extension host via postMessage.
 */

import * as vscode from "vscode";
import { ClaudeClient, Message } from "./claudeClient";
import {
  buildSystemPrompt,
  formatCodeBlock,
} from "./contextCollector";
import { logInfo, logError, logWebviewMessage } from "./logger";

export class ChatPanel {
  public static readonly viewType = "vscode-claude.chat";
  private static instance: ChatPanel | undefined;

  private readonly panel: vscode.WebviewPanel;
  private readonly client: ClaudeClient;
  private conversationHistory: Message[] = [];
  private disposables: vscode.Disposable[] = [];
  /**
   * Tracks whether the current message was initiated from the webview UI
   * or from a local VS Code command.  Set before calling sendUserMessage.
   */
  private messageSource: "local" | "webview" = "local";

  // ---------------------------------------------------------------------------
  // Factory
  // ---------------------------------------------------------------------------

  public static createOrShow(client: ClaudeClient): ChatPanel {
    const column = vscode.window.activeTextEditor
      ? vscode.ViewColumn.Beside
      : vscode.ViewColumn.One;

    if (ChatPanel.instance) {
      logInfo("local", "ChatPanel: revealing existing panel");
      ChatPanel.instance.panel.reveal(column);
      return ChatPanel.instance;
    }

    logInfo("local", "ChatPanel: creating new panel");
    const panel = vscode.window.createWebviewPanel(
      ChatPanel.viewType,
      "Claude Chat",
      column,
      {
        enableScripts: true,
        retainContextWhenHidden: true,
      }
    );

    ChatPanel.instance = new ChatPanel(panel, client);
    return ChatPanel.instance;
  }

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  private constructor(panel: vscode.WebviewPanel, client: ClaudeClient) {
    this.panel = panel;
    this.client = client;

    this.panel.webview.html = this.buildHtml();

    this.panel.onDidDispose(() => this.dispose(), null, this.disposables);

    this.panel.webview.onDidReceiveMessage(
      (msg: WebviewMessage) => this.handleWebviewMessage(msg),
      null,
      this.disposables
    );
  }

  // ---------------------------------------------------------------------------
  // Public helpers called by commands
  // ---------------------------------------------------------------------------

  /** Pre-fill the chat input with a question and submit it. */
  public async ask(question: string): Promise<void> {
    this.panel.reveal();
    this.messageSource = "local";
    await this.sendUserMessage(question);
  }

  // ---------------------------------------------------------------------------
  // Message handling
  // ---------------------------------------------------------------------------

  private async handleWebviewMessage(msg: WebviewMessage): Promise<void> {
    switch (msg.type) {
      case "send":
        logWebviewMessage("send", `textLength=${msg.text.length}`);
        this.messageSource = "webview";
        await this.sendUserMessage(msg.text);
        break;
      case "clear":
        logWebviewMessage("clear", "Conversation history cleared");
        this.conversationHistory = [];
        this.postToWebview({ type: "cleared" });
        break;
      case "insertCode":
        logWebviewMessage("insertCode", `codeLength=${msg.code.length}`);
        await this.insertCodeIntoEditor(msg.code);
        break;
    }
  }

  private async sendUserMessage(text: string): Promise<void> {
    if (!text.trim()) {
      logInfo("webview", "sendUserMessage skipped – empty text");
      return;
    }

    // Determine the source: if the message was triggered from the webview
    // directly, it is "webview"; commands that call ask() are "local".
    // The client's logSource is already set appropriately by the caller.
    const source = this.messageSource;
    logInfo(source, "Sending user message to Claude", `historySize=${this.conversationHistory.length + 1}, textLength=${text.length}`);
    this.client.setLogSource(source);

    this.conversationHistory.push({ role: "user", content: text });
    this.postToWebview({ type: "userMessage", text });
    this.postToWebview({ type: "assistantStart" });

    const config = vscode.workspace.getConfiguration("vscode-claude");
    const options = {
      model: config.get<string>("model", "claude-3-5-sonnet-20241022"),
      maxTokens: config.get<number>("maxTokens", 4096),
      temperature: config.get<number>("temperature", 0.1),
      systemPrompt: buildSystemPrompt(),
    };

    let fullResponse = "";
    try {
      for await (const chunk of this.client.sendMessagesStream(
        this.conversationHistory,
        options
      )) {
        if (chunk.type === "delta") {
          fullResponse += chunk.text;
          this.postToWebview({ type: "delta", text: chunk.text });
        } else if (chunk.type === "done") {
          this.postToWebview({
            type: "assistantDone",
            usage: chunk.usage,
          });
        }
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      logError(source, "Chat request failed", message);
      this.postToWebview({ type: "error", message });
      // Remove the user message from history if the request failed
      this.conversationHistory.pop();
      return;
    }

    logInfo(source, "Chat response complete", `responseLength=${fullResponse.length}`);

    this.conversationHistory.push({
      role: "assistant",
      content: fullResponse,
    });
  }

  private async insertCodeIntoEditor(code: string): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      logInfo("webview", "insertCode – no active editor");
      vscode.window.showWarningMessage(
        "No active editor to insert code into."
      );
      return;
    }
    logInfo("webview", "Inserting code into editor", `codeLength=${code.length}, file=${editor.document.uri.fsPath}`);
    await editor.edit((eb) => {
      eb.replace(editor.selection, code);
    });
  }

  // ---------------------------------------------------------------------------
  // Webview communication
  // ---------------------------------------------------------------------------

  private postToWebview(msg: ExtensionMessage): void {
    this.panel.webview.postMessage(msg);
  }

  // ---------------------------------------------------------------------------
  // HTML
  // ---------------------------------------------------------------------------

  private buildHtml(): string {
    const nonce = getNonce();
    return /* html */ `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Content-Security-Policy"
    content="default-src 'none'; style-src 'nonce-${nonce}'; script-src 'nonce-${nonce}';">
  <title>Claude Chat</title>
  <style nonce="${nonce}">
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      display: flex;
      flex-direction: column;
      height: 100vh;
      font-family: var(--vscode-font-family);
      font-size: var(--vscode-font-size);
      color: var(--vscode-foreground);
      background: var(--vscode-editor-background);
    }
    #messages {
      flex: 1;
      overflow-y: auto;
      padding: 12px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .message { display: flex; flex-direction: column; gap: 4px; }
    .message-label {
      font-size: 0.75em;
      font-weight: 600;
      opacity: 0.7;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .user-label { color: var(--vscode-terminal-ansiGreen); }
    .assistant-label { color: var(--vscode-terminal-ansiBlue); }
    .message-body {
      background: var(--vscode-editor-inactiveSelectionBackground);
      border-radius: 6px;
      padding: 10px 12px;
      white-space: pre-wrap;
      word-break: break-word;
      line-height: 1.5;
    }
    .user-body { background: var(--vscode-input-background); }
    pre {
      background: var(--vscode-textCodeBlock-background, #1e1e1e);
      border-radius: 4px;
      padding: 10px;
      overflow-x: auto;
      position: relative;
    }
    code { font-family: var(--vscode-editor-font-family); font-size: 0.9em; }
    .copy-btn {
      position: absolute;
      top: 6px;
      right: 6px;
      background: var(--vscode-button-background);
      color: var(--vscode-button-foreground);
      border: none;
      border-radius: 3px;
      padding: 2px 8px;
      cursor: pointer;
      font-size: 0.75em;
      opacity: 0.8;
    }
    .copy-btn:hover { opacity: 1; }
    .insert-btn {
      position: absolute;
      top: 6px;
      right: 60px;
      background: var(--vscode-button-secondaryBackground);
      color: var(--vscode-button-secondaryForeground);
      border: none;
      border-radius: 3px;
      padding: 2px 8px;
      cursor: pointer;
      font-size: 0.75em;
      opacity: 0.8;
    }
    .insert-btn:hover { opacity: 1; }
    .usage-info {
      font-size: 0.7em;
      opacity: 0.5;
      text-align: right;
      margin-top: 2px;
    }
    .error-msg {
      color: var(--vscode-errorForeground);
      background: var(--vscode-inputValidation-errorBackground);
      border: 1px solid var(--vscode-inputValidation-errorBorder);
      border-radius: 4px;
      padding: 8px 12px;
    }
    .typing-indicator { opacity: 0.6; font-style: italic; }
    #input-area {
      display: flex;
      flex-direction: column;
      gap: 8px;
      padding: 10px 12px;
      border-top: 1px solid var(--vscode-panel-border);
    }
    #input-row { display: flex; gap: 6px; }
    #user-input {
      flex: 1;
      resize: none;
      background: var(--vscode-input-background);
      color: var(--vscode-input-foreground);
      border: 1px solid var(--vscode-input-border);
      border-radius: 4px;
      padding: 8px;
      font-family: inherit;
      font-size: inherit;
      min-height: 60px;
    }
    #user-input:focus { outline: 1px solid var(--vscode-focusBorder); }
    .btn {
      background: var(--vscode-button-background);
      color: var(--vscode-button-foreground);
      border: none;
      border-radius: 4px;
      padding: 8px 14px;
      cursor: pointer;
      font-size: 0.9em;
      white-space: nowrap;
      align-self: flex-end;
    }
    .btn:hover { background: var(--vscode-button-hoverBackground); }
    .btn-secondary {
      background: var(--vscode-button-secondaryBackground);
      color: var(--vscode-button-secondaryForeground);
    }
    .btn-secondary:hover { background: var(--vscode-button-secondaryHoverBackground); }
    #toolbar { display: flex; gap: 6px; justify-content: flex-end; }
  </style>
</head>
<body>
  <div id="messages"></div>
  <div id="input-area">
    <div id="toolbar">
      <button class="btn btn-secondary" id="clear-btn">Clear</button>
    </div>
    <div id="input-row">
      <textarea id="user-input" rows="3"
        placeholder="Ask Claude anything... (Shift+Enter for newline, Enter to send)"></textarea>
      <button class="btn" id="send-btn">Send</button>
    </div>
  </div>

  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    const messagesEl = document.getElementById('messages');
    const inputEl = document.getElementById('user-input');
    const sendBtn = document.getElementById('send-btn');
    const clearBtn = document.getElementById('clear-btn');

    let currentAssistantEl = null;
    let currentBodyEl = null;

    // -------------------------------------------------------------------------
    // Sending messages
    // -------------------------------------------------------------------------
    function sendMessage() {
      const text = inputEl.value.trim();
      if (!text) return;
      inputEl.value = '';
      inputEl.style.height = 'auto';
      vscode.postMessage({ type: 'send', text });
    }

    sendBtn.addEventListener('click', sendMessage);
    inputEl.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });
    clearBtn.addEventListener('click', () => vscode.postMessage({ type: 'clear' }));

    // Auto-resize textarea
    inputEl.addEventListener('input', () => {
      inputEl.style.height = 'auto';
      inputEl.style.height = Math.min(inputEl.scrollHeight, 200) + 'px';
    });

    // -------------------------------------------------------------------------
    // Receiving messages from the extension
    // -------------------------------------------------------------------------
    window.addEventListener('message', (event) => {
      const msg = event.data;
      switch (msg.type) {
        case 'userMessage':
          appendUserMessage(msg.text);
          break;
        case 'assistantStart':
          startAssistantMessage();
          break;
        case 'delta':
          appendDelta(msg.text);
          break;
        case 'assistantDone':
          finalizeAssistantMessage(msg.usage);
          break;
        case 'error':
          appendError(msg.message);
          break;
        case 'cleared':
          messagesEl.innerHTML = '';
          break;
      }
    });

    // -------------------------------------------------------------------------
    // DOM helpers
    // -------------------------------------------------------------------------
    function appendUserMessage(text) {
      const wrapper = document.createElement('div');
      wrapper.className = 'message';
      wrapper.innerHTML =
        '<span class="message-label user-label">You</span>' +
        '<div class="message-body user-body"></div>';
      wrapper.querySelector('.message-body').textContent = text;
      messagesEl.appendChild(wrapper);
      scrollToBottom();
    }

    function startAssistantMessage() {
      currentAssistantEl = document.createElement('div');
      currentAssistantEl.className = 'message';

      const label = document.createElement('span');
      label.className = 'message-label assistant-label';
      label.textContent = 'Claude';

      currentBodyEl = document.createElement('div');
      currentBodyEl.className = 'message-body typing-indicator';
      currentBodyEl.textContent = '…';

      currentAssistantEl.appendChild(label);
      currentAssistantEl.appendChild(currentBodyEl);
      messagesEl.appendChild(currentAssistantEl);
      scrollToBottom();
    }

    let rawMarkdown = '';
    function appendDelta(text) {
      if (!currentBodyEl) return;
      rawMarkdown += text;
      currentBodyEl.className = 'message-body';
      currentBodyEl.innerHTML = renderMarkdown(rawMarkdown);
      scrollToBottom();
    }

    function finalizeAssistantMessage(usage) {
      if (!currentAssistantEl) return;
      if (usage) {
        const info = document.createElement('div');
        info.className = 'usage-info';
        info.textContent =
          'Tokens: ' + usage.inputTokens + ' in / ' + usage.outputTokens + ' out';
        currentAssistantEl.appendChild(info);
      }
      // Add copy/insert buttons to code blocks
      currentAssistantEl.querySelectorAll('pre').forEach((pre) => {
        const code = pre.querySelector('code');
        if (!code) return;

        const copyBtn = document.createElement('button');
        copyBtn.className = 'copy-btn';
        copyBtn.textContent = 'Copy';
        copyBtn.addEventListener('click', () => {
          navigator.clipboard.writeText(code.textContent || '');
          copyBtn.textContent = 'Copied!';
          setTimeout(() => { copyBtn.textContent = 'Copy'; }, 1500);
        });

        const insertBtn = document.createElement('button');
        insertBtn.className = 'insert-btn';
        insertBtn.textContent = 'Insert';
        insertBtn.addEventListener('click', () => {
          vscode.postMessage({ type: 'insertCode', code: code.textContent || '' });
        });

        pre.style.position = 'relative';
        pre.appendChild(insertBtn);
        pre.appendChild(copyBtn);
      });

      rawMarkdown = '';
      currentAssistantEl = null;
      currentBodyEl = null;
      scrollToBottom();
    }

    function appendError(message) {
      const el = document.createElement('div');
      el.className = 'error-msg';
      el.textContent = '⚠ ' + message;
      messagesEl.appendChild(el);
      currentAssistantEl = null;
      currentBodyEl = null;
      rawMarkdown = '';
      scrollToBottom();
    }

    function scrollToBottom() {
      messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    // -------------------------------------------------------------------------
    // Minimal Markdown renderer (no external dependencies)
    // Handles: code blocks, inline code, bold, italic, links, line breaks
    // -------------------------------------------------------------------------
    function renderMarkdown(text) {
      // Escape HTML first
      function escHtml(s) {
        return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
      }

      // Extract fenced code blocks before processing inline
      const codeBlocks = [];
      text = text.replace(/\`\`\`(\\w*)\\n?([\\s\\S]*?)\`\`\`/g, (_, lang, code) => {
        codeBlocks.push({ lang, code });
        return '\\0CODE' + (codeBlocks.length - 1) + '\\0';
      });

      // Inline code
      text = text.replace(/\`([^\`]+)\`/g, (_, c) => '<code>' + escHtml(c) + '</code>');

      // Bold + italic
      text = text.replace(/\\*\\*\\*(.+?)\\*\\*\\*/g, '<strong><em>$1</em></strong>');
      text = text.replace(/\\*\\*(.+?)\\*\\*/g, '<strong>$1</strong>');
      text = text.replace(/\\*(.+?)\\*/g, '<em>$1</em>');

      // Headers
      text = text.replace(/^### (.+)$/gm, '<h3>$1</h3>');
      text = text.replace(/^## (.+)$/gm, '<h2>$1</h2>');
      text = text.replace(/^# (.+)$/gm, '<h1>$1</h1>');

      // Unordered list items
      text = text.replace(/^[\\-\\*] (.+)$/gm, '<li>$1</li>');
      text = text.replace(/(<li>.*<\\/li>)/s, '<ul>$1</ul>');

      // Links
      text = text.replace(/\\[([^\\]]+)\\]\\(([^)]+)\\)/g, '<a href="$2">$1</a>');

      // Paragraph breaks
      text = text.replace(/\\n\\n/g, '</p><p>');
      text = '<p>' + text + '</p>';
      text = text.replace(/<p>\\s*<\\/p>/g, '');

      // Line breaks within paragraphs
      text = text.replace(/\\n/g, '<br>');

      // Restore code blocks
      text = text.replace(/\\0CODE(\\d+)\\0/g, (_, i) => {
        const { lang, code } = codeBlocks[parseInt(i)];
        return '<pre><code class="language-' + escHtml(lang) + '">' + escHtml(code) + '</code></pre>';
      });

      return text;
    }
  </script>
</body>
</html>`;
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  private dispose(): void {
    logInfo("local", "ChatPanel disposed");
    ChatPanel.instance = undefined;
    this.panel.dispose();
    for (const d of this.disposables) {
      d.dispose();
    }
    this.disposables = [];
  }
}

// ---------------------------------------------------------------------------
// Types for webview <-> extension messages
// ---------------------------------------------------------------------------

type WebviewMessage =
  | { type: "send"; text: string }
  | { type: "clear" }
  | { type: "insertCode"; code: string };

type ExtensionMessage =
  | { type: "userMessage"; text: string }
  | { type: "assistantStart" }
  | { type: "delta"; text: string }
  | { type: "assistantDone"; usage: { inputTokens: number; outputTokens: number } }
  | { type: "error"; message: string }
  | { type: "cleared" };

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

function getNonce(): string {
  let text = "";
  const possible =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  for (let i = 0; i < 32; i++) {
    text += possible.charAt(Math.floor(Math.random() * possible.length));
  }
  return text;
}

/**
 * Build a pre-filled question from the current editor context.
 *
 * Used by commands like "Explain Code" and "Review Code" that inject
 * the selected text automatically into the chat, mirroring Qt Creator's
 * behaviour of auto-populating the AI prompt from the active editor.
 */
export function buildQuestionWithContext(
  template: string,
  context: {
    selectedText: string;
    languageId: string;
    filePath: string;
  }
): string {
  const code = formatCodeBlock(context.selectedText, context.languageId);
  return `${template}\n\nFile: \`${context.filePath}\`\n\n${code}`;
}
