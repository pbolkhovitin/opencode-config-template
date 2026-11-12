// GigaChat OAuth token fetcher.
// Runs as a child of `agent-vault use ... -- node token.mjs`, or directly
// when GIGACHAT_AUTH_KEY is set. The long-lived Authorization Key lives only in
// this process env (VAULT_PASSWORD or GIGACHAT_AUTH_KEY) and never reaches the
// OpenCode process.
//
// stdout: {"access_token":"...","expires_at":<ms>}
// stderr: human-readable errors only (no secrets).

import https from "node:https"
import { randomUUID } from "node:crypto"
import { readFileSync } from "node:fs"

const OAUTH_URL = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
const CA_PATH =
  process.env.GIGACHAT_CA_PATH ||
  `${process.env.HOME}/.local/share/certs/russian-trusted/russian_trusted_root_ca_pem.crt`

const key = process.env.VAULT_PASSWORD || process.env.GIGACHAT_AUTH_KEY
const scope = process.env.VAULT_SCOPE || process.env.GIGACHAT_SCOPE || "GIGACHAT_API_PERS"

if (!key) {
  console.error("gigachat-token: VAULT_PASSWORD/GIGACHAT_AUTH_KEY is empty (set env or use agent-vault)")
  process.exit(2)
}

let ca
try {
  ca = readFileSync(CA_PATH)
} catch {
  console.error(`gigachat-token: CA bundle not found at ${CA_PATH}`)
  process.exit(3)
}

const form = new URLSearchParams({ scope }).toString()

const req = https.request(
  OAUTH_URL,
  {
    method: "POST",
    ca,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json",
      RqUID: randomUUID(),
      Authorization: `Basic ${key}`,
      "Content-Length": Buffer.byteLength(form),
    },
  },
  (res) => {
    let data = ""
    res.on("data", (chunk) => (data += chunk))
    res.on("end", () => {
      if (res.statusCode !== 200) {
        console.error(`gigachat-token: oauth ${res.statusCode}: ${data.slice(0, 300)}`)
        process.exit(4)
      }
      let parsed
      try {
        parsed = JSON.parse(data)
      } catch {
        console.error("gigachat-token: oauth response is not JSON")
        process.exit(5)
      }
      if (!parsed.access_token) {
        console.error("gigachat-token: oauth response has no access_token")
        process.exit(5)
      }
      process.stdout.write(
        JSON.stringify({ access_token: parsed.access_token, expires_at: parsed.expires_at }),
      )
    })
  },
)

req.on("error", (err) => {
  console.error(`gigachat-token: request failed: ${err.message}`)
  process.exit(6)
})

req.setTimeout(20000, () => {
  console.error("gigachat-token: oauth request timed out")
  req.destroy()
})

req.write(form)
req.end()
