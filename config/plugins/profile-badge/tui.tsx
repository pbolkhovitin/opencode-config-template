import { readFileSync } from "node:fs"
import { createSignal } from "solid-js"
import { Plugin } from "@opencode/plugin/tui"

function profileName(configPath: string | undefined, configDir: string | undefined): string {
  const source = configPath ?? configDir
  const match = source?.match(/opencode-([a-z0-9-]+)(?:[/\\](?:opencode|tui)\.jsonc?)?$/)
  return match?.[1] ?? "default"
}

function readDefaultAgent(configPath: string | undefined): string {
  if (!configPath) return "build"
  try {
    return JSON.parse(readFileSync(configPath, "utf8")).default_agent ?? "build"
  } catch {
    return "build"
  }
}

export default Plugin.define({
  id: "profile-badge",
  async setup(context) {
    const configPath = process.env.OPENCODE_CONFIG
    const profile = profileName(configPath, process.env.OPENCODE_CONFIG_DIR)
    const fallbackAgent = readDefaultAgent(configPath)

    const [mcpLabel, setMcpLabel] = createSignal("—")

    let refreshing = false

    const refreshMcp = async () => {
      if (refreshing) return
      refreshing = true
      try {
        context.data.location.mcp.server.invalidate()
        await context.data.location.mcp.server.sync().catch(() => {})
      } finally {
        refreshing = false
      }

      const servers = context.data.location.mcp.server.list()
      if (servers === undefined) {
        setMcpLabel("—")
        return
      }

      // Runtime shape: status may be a string or { status: string }.
      const statusOf = (server: { status: unknown }) => {
        const value = server.status
        return typeof value === "string"
          ? value
          : (value as { status?: string } | undefined)?.status
      }

      const active = servers.filter((server) => statusOf(server) !== "disabled")
      const connected = active.filter((server) => statusOf(server) === "connected").length
      setMcpLabel(`${connected}/${active.length}`)
    }

    await refreshMcp()

    const offMcp = context.data.on("mcp.status.changed", () => {
      void refreshMcp()
    })

    // data layer обновляет store асинхронно; polling с явным sync
    // гарантирует, что бейдж не застынет на начальном снимке.
    const timer = setInterval(() => void refreshMcp(), 2000)

    const offSlot = context.ui.slot({
      append: "prompt.footer.status",
      render: ({ sessionID }) => {
        const activeAgent = sessionID
          ? context.data.session.get(sessionID)?.agent
          : undefined

        return (
          <box flexShrink={0}>
            <text fg={context.theme.text.base}>
              {`${profile}·${activeAgent ?? fallbackAgent}·${mcpLabel()}`}
            </text>
          </box>
        )
      },
    })

    return () => {
      clearInterval(timer)
      offMcp()
      offSlot()
    }
  },
})
