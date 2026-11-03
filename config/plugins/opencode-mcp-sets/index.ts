import { Plugin } from "@opencode/plugin"

import {
  META_KEY,
  META_VERSION,
  applyDeny,
  formatServerList,
  normalizeRules,
  normalizeState,
  parseServers,
  selectServers,
  splitArgs,
  stripMcpInstructions,
  type McpSetState,
  type ServerView,
} from "./lib.ts"

function unwrap<T>(value: unknown): T {
  if (value && typeof value === "object" && "data" in value) {
    return (value as { data: T }).data
  }
  return value as T
}

function promptText(prompt: unknown): string {
  if (!prompt || typeof prompt !== "object") return ""
  const value = prompt as { text?: unknown; parts?: unknown }
  if (typeof value.text === "string") return value.text
  if (Array.isArray(value.parts)) {
    return value.parts
      .map((part) => {
        if (!part || typeof part !== "object") return ""
        const item = part as { type?: unknown; text?: unknown }
        return item.type === "text" && typeof item.text === "string" ? item.text : ""
      })
      .join(" ")
  }
  return ""
}

function usage(): string {
  return [
    "Использование:",
    "  /mcp list                     показать серверы и состояние",
    "  /mcp off <server|glob> ...     скрыть серверы в этой сессии",
    "  /mcp on <server|glob> ...      вернуть серверы в этой сессии",
    "  /mcp only <server|glob> ...    оставить только указанные",
    "  /mcp reset                    вернуть все серверы",
    "",
    "Пример: /mcp off gitlab-official-*",
  ].join("\n")
}

async function readSession(ctx: any, sessionID: string): Promise<any> {
  return unwrap<any>(await ctx.session.get({ sessionID }))
}

async function readState(ctx: any, sessionID: string): Promise<McpSetState> {
  const session = await readSession(ctx, sessionID)
  return normalizeState(session?.metadata?.[META_KEY])
}

async function readServers(ctx: any): Promise<ServerView[]> {
  return parseServers(await ctx.mcp.list())
}

function mergeDisabled(current: string[], matched: string[], mode: string, names: string[]): string[] {
  const set = new Set(current)
  if (mode === "off") {
    matched.forEach((name) => set.add(name))
  } else if (mode === "on") {
    matched.forEach((name) => set.delete(name))
  } else if (mode === "only") {
    names.filter((name) => !matched.includes(name)).forEach((name) => set.add(name))
  } else if (mode === "reset") {
    set.clear()
  }
  return [...set].sort()
}

async function applyCommand(ctx: any, sessionID: string, text: string): Promise<string> {
  const args = splitArgs(text.replace(/^\/mcp(?:-set)?\s*/i, ""))
  const mode = (args.shift() ?? "list").toLowerCase()

  if (mode === "list" || mode === "status") {
    const [servers, state] = await Promise.all([readServers(ctx), readState(ctx, sessionID)])
    return formatServerList(servers, state)
  }

  if (!["off", "on", "only", "reset"].includes(mode)) return usage()

  const servers = await readServers(ctx)
  const names = servers.map((server) => server.name)
  const patterns = mode === "reset" ? [] : args

  if (mode !== "reset" && patterns.length === 0) return usage()

  const selected = selectServers(patterns, names)
  if (selected.unknown.length > 0) {
    return [
      `Не найдены MCP-серверы: ${selected.unknown.join(", ")}`,
      `Доступны: ${names.length > 0 ? names.join(", ") : "—"}`,
    ].join("\n")
  }

  const session = await readSession(ctx, sessionID)
  const current = normalizeState(session?.metadata?.[META_KEY])
  const disabled = mergeDisabled(current.disabled, selected.matched, mode, names)
  const existing = normalizeRules(session?.permissions)
  const { permissions, added } = applyDeny(existing, current.rules, disabled)
  const metadata = {
    ...(session?.metadata ?? {}),
    [META_KEY]: { version: META_VERSION, disabled, rules: added },
  }

  await ctx.session.update({ sessionID, permissions, metadata })

  const state = { disabled, rules: added }
  return [
    `MCP обновлён (${mode}).`,
    formatServerList(servers, state),
    "",
    "Соединения серверов не переподключаются: меняется только видимость в этой сессии.",
  ].join("\n")
}

export default Plugin.define({
  id: "opencode-mcp-sets",
  async setup(ctx) {
    await ctx.command.transform((editor) => {
      editor.add({
        name: "mcp",
        description: "Включить/выключить MCP-серверы для текущей сессии",
        execute: async ({ sessionID, prompt }) => {
          const result = await applyCommand(ctx, sessionID, promptText(prompt))
          await ctx.session.synthetic({ sessionID, text: result })
        },
      })
    })

    // Fallback for cases where permissions hide the server but the MCP
    // instruction block still reaches the model request. This also keeps
    // non-Code-Mode tool lists honest.
    await ctx.session.hook("context", async (event) => {
      const state = await readState(ctx, event.sessionID)
      if (state.disabled.length === 0) return

      const disabled = new Set(state.disabled)
      for (const tool of Object.keys(event.tools ?? {})) {
        for (const name of disabled) {
          if (tool === name || tool.startsWith(`${name}_`) || tool.startsWith(`${name}.`)) {
            delete event.tools[tool]
            break
          }
        }
      }
      stripMcpInstructions(event.system, state.disabled)
    })
  },
})
