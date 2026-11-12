// GigaChat provider for OpenCode (v2 plugin API).
//
// GigaChat speaks an OpenAI-compatible dialect, but:
//   1. requests must be authorized by a Bearer token that lives only 30 min and
//      is minted from a long-lived Authorization Key;
//   2. TLS is signed by the Russian Trusted Root CA (Минцифры), which is not in
//      the system trust store. The CA is installed for the OpenCode service via
//      `NODE_EXTRA_CA_CERTS` (see `opencode service get`).
//
// The Authorization Key is kept in HashiCorp Vault
// (`secret/agent/YOUR_PROJECT/gigachat api`). It is only ever present in the
// environment of the `agent-vault use ... node token.mjs` child process, and
// only the short-lived access token is returned to OpenCode. Nothing is written
// to disk and nothing is logged.
//
// The provider itself is declared in opencode.json:
//   provider.gigachat (npm @ai-sdk/openai-compatible, baseURL https://api.giga.chat/v1)

import { Plugin } from "@opencode/plugin"
import { spawnSync } from "node:child_process"

const PROVIDER_ID = "gigachat"
const SECRET_NAME = "gigachat api"
const VAULT_PROJECT = "YOUR_PROJECT"
const TOKEN_SCRIPT = new URL("./token.mjs", import.meta.url).pathname

let cached: { token: string; expires: number } | null = null

function fetchToken(): string {
  const res = spawnSync(
    "agent-vault",
    ["use", SECRET_NAME, "--project", VAULT_PROJECT, "--", "node", TOKEN_SCRIPT],
    { encoding: "utf8", timeout: 45_000 },
  )
  if (res.error) throw new Error(`gigachat: cannot run agent-vault: ${res.error.message}`)
  if (res.status !== 0) {
    throw new Error(
      `gigachat: token fetch failed (${res.status}): ${(res.stderr || "").trim().slice(0, 300)}`,
    )
  }
  let parsed: { access_token?: string; expires_at?: number }
  try {
    parsed = JSON.parse(res.stdout)
  } catch {
    throw new Error("gigachat: token script returned malformed JSON")
  }
  if (!parsed.access_token) throw new Error("gigachat: token script returned no access_token")
  cached = {
    token: parsed.access_token,
    expires: parsed.expires_at ?? Date.now() + 25 * 60_000,
  }
  return cached.token
}

function accessToken(): string {
  if (cached && cached.expires - Date.now() > 60_000) return cached.token
  return fetchToken()
}

export default Plugin.define({
  id: "gigachat",
  async setup(ctx) {
    await ctx.session.hook(
      "http.request",
      (event: any) => {
        const req = event?.request
        if (!req || typeof req !== "object") return
        const headers = new Headers(req.headers)
        if (headers.has("authorization")) return
        headers.set("Authorization", `Bearer ${accessToken()}`)
        event.request = new Request(req, { headers })
      },
      { providerID: PROVIDER_ID },
    )
  },
})
