/**
 * Pure helpers for the per-session MCP set plugin.
 *
 * Kept free of OpenCode imports so the logic can be unit-tested with Node.
 */

export type Effect = "allow" | "deny" | "ask"

export interface Rule {
  action: string
  resource: string
  effect: Effect
}

export interface McpSetState {
  disabled: string[]
  rules: Rule[]
}

export interface ServerView {
  name: string
  status: string
}

export const META_KEY = "mcpSets"
export const META_VERSION = 1

function isRule(value: unknown): value is Rule {
  if (!value || typeof value !== "object") return false
  const rule = value as Record<string, unknown>
  return (
    typeof rule.action === "string" &&
    typeof rule.resource === "string" &&
    (rule.effect === "allow" || rule.effect === "deny" || rule.effect === "ask")
  )
}

export function normalizeRules(value: unknown): Rule[] {
  return Array.isArray(value) ? value.filter(isRule) : []
}

export function normalizeState(value: unknown): McpSetState {
  if (!value || typeof value !== "object") return { disabled: [], rules: [] }
  const raw = value as Record<string, unknown>
  const disabled = Array.isArray(raw.disabled)
    ? raw.disabled.filter((item): item is string => typeof item === "string")
    : []
  return { disabled: [...new Set(disabled)].sort(), rules: normalizeRules(raw.rules) }
}

export function splitArgs(text: string): string[] {
  return text
    .trim()
    .split(/[\s,]+/)
    .map((item) => item.trim())
    .filter(Boolean)
}

export function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

/** Only `*` is special; everything else is literal. */
export function globMatch(pattern: string, name: string): boolean {
  if (pattern === "*") return true
  const source = pattern.split("*").map(escapeRegExp).join(".*")
  return new RegExp(`^${source}$`).test(name)
}

export function selectServers(
  patterns: string[],
  names: string[],
): { matched: string[]; unknown: string[] } {
  const matched = names.filter((name) => patterns.some((pattern) => globMatch(pattern, name)))
  const unknown = patterns.filter(
    (pattern) => !names.some((name) => globMatch(pattern, name)),
  )
  return { matched, unknown }
}

export function applyDeny(
  existing: Rule[],
  previous: Rule[],
  disabled: string[],
): { permissions: Rule[]; added: Rule[] } {
  const previousKeys = new Set(previous.map(ruleKey))
  const kept = existing.filter((rule) => !previousKeys.has(ruleKey(rule)))
  const keptKeys = new Set(kept.map(ruleKey))
  const added = disabled
    .map((name) => ({ action: `${name}_*`, resource: "*", effect: "deny" as const }))
    .filter((rule) => !keptKeys.has(ruleKey(rule)))
  return { permissions: [...kept, ...added], added }
}

export function ruleKey(rule: Rule): string {
  return `${rule.action}\u0000${rule.resource}\u0000${rule.effect}`
}

export function statusOf(value: unknown): string {
  if (typeof value === "string") return value
  if (value && typeof value === "object") {
    const status = (value as Record<string, unknown>).status
    if (typeof status === "string") return status
  }
  return "unknown"
}

export function parseServers(value: unknown): ServerView[] {
  const list = Array.isArray(value)
    ? value
    : value && typeof value === "object" && Array.isArray((value as { data?: unknown }).data)
      ? (value as { data: unknown[] }).data
      : []
  return list
    .map((item) => {
      if (!item || typeof item !== "object") return undefined
      const server = item as Record<string, unknown>
      if (typeof server.name !== "string") return undefined
      return { name: server.name, status: statusOf(server.status) }
    })
    .filter((item): item is ServerView => item !== undefined)
    .sort((a, b) => a.name.localeCompare(b.name))
}

export function formatServerList(servers: ServerView[], state: McpSetState): string {
  if (servers.length === 0) return "MCP-серверы не найдены в этом профиле."
  const lines = servers.map((server) => {
    const sessionOff = state.disabled.includes(server.name)
    const globalOff = server.status === "disabled"
    const flag = sessionOff ? "off" : globalOff ? "off*" : "on "
    return `  ${flag}  ${server.name.padEnd(28)} ${server.status}`
  })
  return [
    "MCP для этой сессии:",
    ...lines,
    "",
    "on/off — видимость в сессии; off* — отключён глобально в конфиге.",
    "Команды: /mcp list | off <server|glob> | on ... | only ... | reset",
  ].join("\n")
}

/**
 * Remove MCP instruction blocks for disabled servers from a system prompt.
 * Mutates parts in place and is deliberately conservative: only named
 * `<server name="...">` blocks and a fully emptied `<mcp_instructions>` block
 * are removed.
 */
export function stripMcpInstructions(system: unknown, disabled: string[]): void {
  if (!Array.isArray(system) || disabled.length === 0) return
  const names = new Set(disabled)
  for (const part of system) {
    if (!part || typeof part !== "object") continue
    const textPart = part as { type?: unknown; text?: unknown }
    if (textPart.type !== "text" || typeof textPart.text !== "string") continue
    let text = textPart.text
    for (const name of names) {
      text = text.replace(
        new RegExp(`<server name="${escapeRegExp(name)}">[\\s\\S]*?</server>`, "g"),
        "",
      )
    }
    if (text.includes("<mcp_instructions>") && !/<server name="/.test(text)) {
      text = text.replace(/<mcp_instructions>[\s\S]*?<\/mcp_instructions>/g, "")
    }
    textPart.text = text.trim()
  }
}
