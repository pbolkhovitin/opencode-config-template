// Local V2 adapter for opencode-pty.
// The package's npm spec "opencode-pty/v2" is not resolvable by
// `opencode plugin check`, so load the V2 entrypoint directly.
// Requires ~/.config/opencode/node_modules/opencode-pty (v0.4.0+).
export { default } from "../node_modules/opencode-pty/dist/src/v2/index.js"
