# folder-switcher

Local OpenCode TUI plugin (v2.x): switch the current session's working directory
through a folder picker.

## Commands

- `/cd` — open the picker
- `/folder` — alias
- Command palette: "Сменить каталог сессии"

## What the picker shows

1. `..` parent directory (not at filesystem root)
2. Subdirectories of the current directory (sorted, up to 200; search filters them)
3. Up to 10 recent directories from `~/.config/opencode/folder-switcher.json`
4. "Ввести путь вручную" → prompt (`~`, absolute and relative paths supported)

Selecting a folder calls `client.session.move({ sessionID, directory })` for the
session currently open in the TUI and records it in the recents file (atomic
write: temp file + rename).

## Storage

`~/.config/opencode/folder-switcher.json`

```json
{ "recent": ["/home/user/project", "/home/user/src/lib"] }
```

Recents are unique, most recent first, capped at 10. A missing or corrupt file
is treated as an empty list.

## Notes

- No external dependencies beyond OpenCode itself.
- Read errors (EACCES/ENOENT) and move failures are reported with `dialog.alert`;
  the TUI is never crashed by the plugin.
- If no session is open (e.g. home screen), the plugin shows an alert and aborts.
- Delete this directory to uninstall; the JSON file can be removed separately.
