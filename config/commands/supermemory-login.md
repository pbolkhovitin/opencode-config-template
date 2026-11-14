---
description: Authenticate with Supermemory via browser
---

# Supermemory Login

Run this command to authenticate the user with Supermemory:

```bash
bunx opencode-supermemory@latest login
```

This will:
1. Start a local callback server on 127.0.0.1:19880
2. Open the browser to Supermemory's OAuth consent page
3. After the user approves, save OAuth credentials to ~/.supermemory-opencode/credentials.json

OpenCode picks up the new credentials without a restart.

Wait for the command to complete, then inform the user whether authentication succeeded or failed.

If the user wants to log out instead, tell them to use the /supermemory-logout command.
