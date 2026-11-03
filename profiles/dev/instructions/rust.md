# Rust Instructions

## Toolchain
- Rust: rustup (<https://rustup.rs>)
- Build: `cargo build`
- Test: `cargo test`
- Lint: `cargo clippy -- -D warnings`
- Format: `cargo fmt`
- Doc: `cargo doc --open`

## Commands
- Run: `cargo run`
- Check: `cargo check` (fast compile check, no binary)
- Release: `cargo build --release`
- Audit: `cargo audit` (security deps)

## Conventions
- Use `cargo new <name>` for new projects
- Error handling: Result<T, E>, anyhow/thiserror for apps
- Avoid `unsafe` unless absolutely necessary — document why
- Use `#[derive(Debug, Clone, PartialEq)]` where appropriate
- Prefer `clap` for CLI args
- Module structure: `lib.rs` for library, `main.rs` for binary

## Unsafe rules
- Every `unsafe` block must have a SAFETY comment
- No transmute unless validated
- Prefer `std::mem::replace` / `take` over manual drops

## Verify
```bash
rustc --version && cargo --version && rustup --version
```
