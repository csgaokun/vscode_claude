# vscode-claude

Claude AI assistant for Visual Studio Code, adapted from [Qt Creator's AI plugin](https://doc.qt.io/qtcreator/index.html) patterns.

## Features

| Command | Keybinding | Description |
|---------|-----------|-------------|
| **Claude: Open Claude Chat Panel** | `Ctrl+Shift+C` | Persistent chat panel with streaming responses |
| **Claude: Ask Claude** | `Ctrl+Shift+A` | Quick input box for a one-off question |
| **Claude: Explain Selected Code** | Right-click menu | Explain highlighted code in detail |
| **Claude: Review Selected Code** | Right-click menu | Bug, security and style review of selected code |
| **Claude: Generate Code from Description** | — | Describe what you want; Claude inserts it |

Inline completion (off by default) can be enabled via the setting below.

## Setup

1. Install the extension (`.vsix`).
2. Open VS Code Settings (`Ctrl+,`) and search for **Claude AI**.
3. Paste your [Anthropic API key](https://console.anthropic.com) into **vscode-claude.apiKey**, or set the `ANTHROPIC_API_KEY` environment variable.

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `vscode-claude.apiKey` | `""` | Anthropic API key |
| `vscode-claude.model` | `claude-3-5-sonnet-20241022` | Claude model |
| `vscode-claude.maxTokens` | `4096` | Max tokens per response |
| `vscode-claude.temperature` | `0.1` | Response temperature (0 = deterministic) |
| `vscode-claude.enableInlineCompletion` | `false` | Enable ghost-text completions |

## Building from source

```bash
npm install
npm run compile    # transpile TypeScript → out/
npm run lint       # ESLint
```

## Design notes

The extension architecture is inspired by Qt Creator's AI plugin:

* **`ClaudeClient`** — thin HTTP wrapper around the Anthropic Messages API
  (mirrors Qt Creator's `LlmRequest` / `AiRequest` classes).
* **`contextCollector`** — gathers active-file metadata, cursor position, and
  selected text before each request (mirrors `AiDocument` context helpers).
* **`ChatPanel`** — webview-based chat UI with streaming token display and
  copy/insert buttons on code blocks.
* **`InlineCompletionProvider`** — fill-in-the-middle completions via
  `vscode.InlineCompletionItemProvider` (mirrors Qt Creator's ghost-text
  suggestion pipeline).
