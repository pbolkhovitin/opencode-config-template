# Golang Instructions

## Toolchain
- Go: `go version` (system or via go install)
- Module: `go mod init <module>`, `go mod tidy`
- Lint: `golangci-lint run`

## Commands
- Build: `go build ./...`
- Test: `go test ./... -v -count=1`
- Coverage: `go test -coverprofile=coverage.out ./...`
- Format: `gofmt -s -w .`
- Vet: `go vet ./...`
- Install: `go install ./...`

## Conventions
- Exported functions/types = PascalCase, private = camelCase
- Error handling: always check errors, return early
- Never use `panic` for expected errors
- Use `context.Context` as first param in public functions
- Prefer `slog` for structured logging
- Package naming: lowercase, single word

## Verify
```bash
go version && golangci-lint --version
```
