---
description: Convert a Claude-generated HTML design into a SwiftUI View file inside the active Xcode workspace.
argument-hint: <design-url-or-tarball-path>
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, mcp__claude-in-chrome__*, mcp__xcode-tools__*
---

The user has invoked the converter with `$ARGUMENTS`.

If `$ARGUMENTS` is empty, ask for a Claude design URL (e.g. `https://api.anthropic.com/v1/design/h/<id>?open_file=<name>`) or a local `.tar.gz` path before proceeding. Design URLs may be one-shot/short-lived — fetch immediately.

Invoke the `claude-design-to-swiftui` skill and follow its workflow end to end:

1. Fetch: `"${CLAUDE_PLUGIN_ROOT}/skills/claude-design-to-swiftui/scripts/fetch.sh" "$ARGUMENTS"`
2. Render the entry HTML in Chrome at 390x844 via `claude-in-chrome` and screenshot.
3. Read the HTML and any linked CSS files.
4. Translate to SwiftUI using the reference mappings in `${CLAUDE_PLUGIN_ROOT}/skills/claude-design-to-swiftui/references/`.
5. Find the active Xcode workspace via `mcp__xcode-tools__XcodeListWindows`, then write the file with `mcp__xcode-tools__XcodeWrite`.
6. Build with `mcp__xcode-tools__BuildProject` and patch any errors via `mcp__xcode-tools__XcodeListNavigatorIssues` + `mcp__xcode-tools__XcodeUpdate`.
7. Render the preview with `mcp__xcode-tools__RenderPreview`, visually diff against the prototype screenshot, and iterate.

Required setup (remind the user if anything is missing): Xcode 26.3+ with **Settings → Intelligence → Xcode Tools = ON**, and the target Xcode project open. The `claude-in-chrome` MCP must also be installed.
