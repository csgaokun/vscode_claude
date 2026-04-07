/**
 * Claude API client for VS Code extension.
 *
 * This module provides a thin HTTP client for the Anthropic Messages API,
 * following a similar request/response model to Qt Creator's AI client
 * (see qt-creator/src/plugins/copilot and qt-creator/src/plugins/aiplugin).
 *
 * Key design choices borrowed from Qt Creator:
 *  - Separate client class responsible only for network I/O
 *  - Typed request/response structures
 *  - Streamed response support via async iteration
 *  - Configuration injected at construction time
 */

import * as https from "https";
import * as http from "http";

/** A single turn in a conversation. */
export interface Message {
  role: "user" | "assistant";
  content: string;
}

/** Options forwarded to the Anthropic Messages API. */
export interface ClaudeRequestOptions {
  model: string;
  maxTokens: number;
  temperature: number;
  systemPrompt?: string;
}

/** The full response returned by a non-streaming call. */
export interface ClaudeResponse {
  content: string;
  /** Total input + output tokens consumed by this request. */
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
  stopReason: string;
}

/** Yields successive text deltas during a streaming response. */
export type ClaudeStreamChunk =
  | { type: "delta"; text: string }
  | { type: "done"; usage: ClaudeResponse["usage"] };

const ANTHROPIC_API_HOST = "api.anthropic.com";
const ANTHROPIC_API_VERSION = "2023-06-01";
const MESSAGES_PATH = "/v1/messages";

/**
 * Thin wrapper around the Anthropic Messages REST API.
 *
 * Create one instance per VS Code session; reuse across requests.
 */
export class ClaudeClient {
  private readonly apiKey: string;

  constructor(apiKey: string) {
    if (!apiKey) {
      throw new Error(
        "Claude API key is required. Set vscode-claude.apiKey in settings or the ANTHROPIC_API_KEY environment variable."
      );
    }
    this.apiKey = apiKey;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /**
   * Send a message list and return the full response.
   *
   * Mirrors Qt Creator's blocking `sendRequest` helper used in its AI plugin.
   */
  async sendMessages(
    messages: Message[],
    options: ClaudeRequestOptions
  ): Promise<ClaudeResponse> {
    const body = this.buildRequestBody(messages, options, false);
    const rawBody = await this.post(body);
    return this.parseResponse(rawBody);
  }

  /**
   * Send a message list and yield text deltas as they arrive.
   *
   * Mirrors Qt Creator's streaming path where partial tokens are emitted to
   * the editor as they are received over the network.
   */
  async *sendMessagesStream(
    messages: Message[],
    options: ClaudeRequestOptions
  ): AsyncGenerator<ClaudeStreamChunk> {
    const body = this.buildRequestBody(messages, options, true);
    yield* this.postStream(body);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  private buildRequestBody(
    messages: Message[],
    options: ClaudeRequestOptions,
    stream: boolean
  ): Record<string, unknown> {
    const body: Record<string, unknown> = {
      model: options.model,
      max_tokens: options.maxTokens,
      temperature: options.temperature,
      messages,
      stream,
    };
    if (options.systemPrompt) {
      body.system = options.systemPrompt;
    }
    return body;
  }

  /** POST the request body and return the raw response text. */
  private post(body: Record<string, unknown>): Promise<string> {
    return new Promise((resolve, reject) => {
      const payload = JSON.stringify(body);
      const req = https.request(
        {
          hostname: ANTHROPIC_API_HOST,
          path: MESSAGES_PATH,
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(payload),
            "x-api-key": this.apiKey,
            "anthropic-version": ANTHROPIC_API_VERSION,
          },
        },
        (res: http.IncomingMessage) => {
          const chunks: Buffer[] = [];
          res.on("data", (chunk: Buffer) => chunks.push(chunk));
          res.on("end", () => {
            const text = Buffer.concat(chunks).toString("utf-8");
            if (res.statusCode !== undefined && res.statusCode >= 400) {
              reject(
                new Error(`Anthropic API error ${res.statusCode}: ${text}`)
              );
            } else {
              resolve(text);
            }
          });
        }
      );
      req.on("error", reject);
      req.write(payload);
      req.end();
    });
  }

  /** POST with streaming enabled; parse Server-Sent Events and yield chunks. */
  private async *postStream(
    body: Record<string, unknown>
  ): AsyncGenerator<ClaudeStreamChunk> {
    const payload = JSON.stringify(body);

    // Collect SSE lines via a manually-managed async generator over Node.js
    // IncomingMessage so we don't depend on a third-party streaming library
    // (keeping the dependency footprint minimal, as Qt Creator does).
    const lineQueue: string[] = [];
    let resolveNext: ((value: IteratorResult<string>) => void) | null = null;
    let done = false;
    let networkError: Error | null = null;

    const req = https.request(
      {
        hostname: ANTHROPIC_API_HOST,
        path: MESSAGES_PATH,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(payload),
          "x-api-key": this.apiKey,
          "anthropic-version": ANTHROPIC_API_VERSION,
        },
      },
      (res: http.IncomingMessage) => {
        if (res.statusCode !== undefined && res.statusCode >= 400) {
          const errChunks: Buffer[] = [];
          res.on("data", (c: Buffer) => errChunks.push(c));
          res.on("end", () => {
            const text = Buffer.concat(errChunks).toString("utf-8");
            networkError = new Error(
              `Anthropic API error ${res.statusCode}: ${text}`
            );
            done = true;
            if (resolveNext) {
              resolveNext({ value: undefined as unknown as string, done: true });
            }
          });
          return;
        }

        let buffer = "";
        res.on("data", (chunk: Buffer) => {
          buffer += chunk.toString("utf-8");
          const lines = buffer.split("\n");
          buffer = lines.pop() ?? "";
          for (const line of lines) {
            lineQueue.push(line);
            if (resolveNext) {
              const r = resolveNext;
              resolveNext = null;
              r({ value: lineQueue.shift()!, done: false });
            }
          }
        });
        res.on("end", () => {
          done = true;
          if (resolveNext) {
            resolveNext({ value: undefined as unknown as string, done: true });
          }
        });
      }
    );

    req.on("error", (err: Error) => {
      networkError = err;
      done = true;
      if (resolveNext) {
        resolveNext({ value: undefined as unknown as string, done: true });
      }
    });
    req.write(payload);
    req.end();

    // Async iterator that reads from lineQueue / waits for more data.
    const lineIterator: AsyncIterator<string> = {
      next(): Promise<IteratorResult<string>> {
        if (lineQueue.length > 0) {
          return Promise.resolve({ value: lineQueue.shift()!, done: false });
        }
        if (done) {
          return Promise.resolve({
            value: undefined as unknown as string,
            done: true,
          });
        }
        return new Promise<IteratorResult<string>>((resolve) => {
          resolveNext = resolve;
        });
      },
    };

    // Parse SSE stream – each event looks like:
    //   event: content_block_delta
    //   data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hello"}}
    let inputTokens = 0;
    let outputTokens = 0;

    let line: IteratorResult<string>;
    while (!(line = await lineIterator.next()).done) {
      if (networkError) {
        throw networkError;
      }

      const raw = line.value.trim();
      if (!raw.startsWith("data: ")) {
        continue;
      }
      const jsonText = raw.slice(6);
      if (jsonText === "[DONE]") {
        break;
      }

      let event: Record<string, unknown>;
      try {
        event = JSON.parse(jsonText) as Record<string, unknown>;
      } catch {
        continue;
      }

      const eventType = event.type as string | undefined;

      if (eventType === "content_block_delta") {
        const delta = event.delta as Record<string, unknown> | undefined;
        if (delta?.type === "text_delta" && typeof delta.text === "string") {
          yield { type: "delta", text: delta.text };
        }
      } else if (eventType === "message_delta") {
        const usage = event.usage as Record<string, unknown> | undefined;
        if (usage) {
          outputTokens = (usage.output_tokens as number | undefined) ?? 0;
        }
      } else if (eventType === "message_start") {
        const msg = event.message as Record<string, unknown> | undefined;
        const usage = msg?.usage as Record<string, unknown> | undefined;
        if (usage) {
          inputTokens = (usage.input_tokens as number | undefined) ?? 0;
        }
      } else if (eventType === "message_stop") {
        break;
      }
    }

    if (networkError) {
      throw networkError;
    }

    yield { type: "done", usage: { inputTokens, outputTokens } };
  }

  /** Parse a non-streaming Messages API response. */
  private parseResponse(rawBody: string): ClaudeResponse {
    const data = JSON.parse(rawBody) as Record<string, unknown>;
    const content = data.content as Array<Record<string, unknown>>;
    const text = content
      .filter((b) => b.type === "text")
      .map((b) => b.text as string)
      .join("");
    const usage = data.usage as Record<string, number>;
    return {
      content: text,
      usage: {
        inputTokens: usage.input_tokens ?? 0,
        outputTokens: usage.output_tokens ?? 0,
      },
      stopReason: (data.stop_reason as string | undefined) ?? "end_turn",
    };
  }
}
