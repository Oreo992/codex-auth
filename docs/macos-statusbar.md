# macOS Status Bar Companion

`CodexAuthStatusBar` is a lightweight macOS menu bar companion for `codex-auth`.
It keeps account switching in the existing CLI and adds a small native panel for day-to-day use.

## Features

- Shows a compact template icon in the menu bar, with the active account summary in the tooltip.
- Opens a small translucent macOS panel with the active account, 5h usage, weekly usage, and last activity.
- Shows 5h and weekly remaining usage as slim progress bars beside each account.
- Colors usage bars green by default, yellow below 50%, and red below 20%.
- Lists stored accounts from `codex-auth list --skip-api`.
- Refreshes usage on demand with `codex-auth list --api`.
- Switches accounts by clicking a row, which calls `codex-auth switch <email-or-account-label>`.

On macOS 26 and newer, the panel and rows use the system SwiftUI Liquid Glass `glassEffect`.
Older macOS versions fall back to ultra-thin SwiftUI material backgrounds with the same compact layout.
The popover height adapts to the account count and caps at a scrollable list height.

## Run Locally

From the repository root:

```shell
sh scripts/macos-statusbar.sh
```

Or run the Swift package directly:

```shell
cd macos/CodexAuthStatusBar
swift run -c release CodexAuthStatusBar
```

To build a launchable `.app` bundle:

```shell
sh scripts/build-macos-statusbar-app.sh
open dist/CodexAuthStatusBar.app
```

The app is bundled as a menu-bar-only app with `LSUIElement`, so it does not show a Dock icon.

The app looks for `codex-auth` in:

- `CODEX_AUTH_BIN`, when set
- the current `PATH`
- `~/.npm-global/bin/codex-auth`
- `~/.local/bin/codex-auth`
- `/opt/homebrew/bin/codex-auth`
- `/usr/local/bin/codex-auth`

## Verify

```shell
cd macos/CodexAuthStatusBar
swift build
swift run CodexAuthStatusBarSelfTest
```

`CodexAuthStatusBarSelfTest` covers the parser that converts `codex-auth list` table output into account rows.
