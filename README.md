# claudedesign-to-swiftui

Turn a **Claude-generated HTML design prototype** (a URL from `api.anthropic.com/v1/design/h/...` or a local `.tar.gz`) into a **SwiftUI `View` file** written directly into your active Xcode workspace — built, previewed, and visually diff'd against the prototype until it matches.

One prototype in, one self-contained `.swift` file out.

## What it does, end to end

1. **Fetches** the design (URL or tarball) and unpacks it.
2. **Renders** the HTML in Chrome at iPhone 15 Pro size (390×844) and screenshots it.
3. **Reads** the HTML + every linked CSS file.
4. **Translates** the DOM and styles to SwiftUI using bundled reference mappings (layout, typography, styling, component patterns) plus two worked examples.
5. **Writes** the generated file into your open Xcode workspace (via Apple's native Xcode MCP).
6. **Builds** the project and patches any errors from the navigator diagnostics.
7. **Renders** the SwiftUI preview and **visually diffs** it against the prototype screenshot, iterating until they match.

Output is a **single `.swift` file**: one `View` struct + a `#Preview` + (if needed) a `fileprivate` `Color(hex:)` extension. No external packages, no multi-screen navigation, no JS interactivity — visual layout fidelity only.

## Requirements

| | |
|---|---|
| **Claude Code** | latest |
| **Xcode** | **26.3 or later** |
| **Xcode setting** | Settings → Intelligence → **Xcode Tools = ON** |
| **Xcode state** | target project/workspace **open** when you run the command |
| **MCP: `xcode-tools`** | bundled in this plugin's `.mcp.json` (ships with Xcode 26.3+ as `xcrun mcpbridge`) |
| **MCP: `claude-in-chrome`** | **user-installed** — used to render and screenshot the HTML prototype |

If either MCP is missing, the skill degrades gracefully: it'll emit the `.swift` file via the standard `Write` tool and ask you to preview/diff manually.

## Install

```
/plugin marketplace add heyadam/claudedesign-to-swiftui
/plugin install claudedesign-to-swiftui@claudedesign-to-swiftui
```

Replace `heyadam` with the GitHub owner of the repo (e.g. `adampresson`).

To install a specific version, tag it in git and reference the tag:
```
/plugin marketplace add heyadam/claudedesign-to-swiftui@v0.1.0
```

### Verify the install
```
/plugin list
```
You should see `claudedesign-to-swiftui` listed and the `/convert` command available.

## Usage

```
/convert <design-url-or-tarball-path>
```

**Examples:**

```
/convert https://api.anthropic.com/v1/design/h/abc123?open_file=index.html
```

```
/convert ~/Downloads/my-prototype.tar.gz
```

Running `/convert` with no argument will prompt you for a URL or path.

> **Design URLs are short-lived / one-shot.** If yours 404s, generate a fresh one from Claude and retry.

### What happens next

- The skill prints the resolved entry HTML, renders it in Chrome, and shows you the screenshot.
- It picks a meaningful filename (e.g. `OnboardingView.swift`) based on the prototype's purpose. If your workspace has multiple groups it'll ask which to write into.
- It builds, fixes any errors, renders the preview, and compares. You'll see a concrete discrepancy list (layout, sizing, colors, typography) each iteration.
- After three iterations without convergence, it stops and hands you the remaining diff.

## What's inside the plugin

- **Command** — `/convert` (`commands/convert.md`): the entry point; orchestrates the skill.
- **Skill** — `claude-design-to-swiftui` (`skills/claude-design-to-swiftui/SKILL.md`): the full workflow.
  - `scripts/fetch.sh` — download + unpack + entry-HTML resolution.
  - `references/layout-mapping.md` — flex / grid / block → `VStack` / `HStack` / `ZStack` / `Grid` / `ScrollView`.
  - `references/styling-mapping.md` — CSS padding / background / border / shadow → SwiftUI modifiers.
  - `references/typography-mapping.md` — font-family / size / weight → `.font()` / `.fontWeight()` / `.lineSpacing()`.
  - `references/component-patterns.md` — cards, buttons, list rows, nav bars.
  - `examples/01-landing-card/` and `examples/02-list-with-rows/` — before/after HTML → SwiftUI pairs.
- **MCP bundle** — `.mcp.json` registers the `xcode-tools` server automatically when the plugin is installed.

## Translation rules at a glance

- Preserve DOM hierarchy — a wrapping `<div>` becomes a wrapping `VStack` (or the container that fits).
- Inline literal pixel values (`padding: 16px` → `.padding(16)`). No design tokens in v1.
- Hex colors go through a `fileprivate extension Color { init(hex:) }` at the bottom of the file.
- SF Symbols (`Image(systemName:)`) only when the prototype has an unambiguous iconographic glyph. Otherwise `Image("...")` with a `// TODO: add asset` comment.
- Content taller than 844pt → wrapped in `ScrollView`.

## Scope and non-goals

**In scope**
- One HTML prototype → one SwiftUI `View` file.
- Visual layout fidelity (structure, spacing, color, type, placement).
- Automatic build + preview + diff loop.

**Out of scope**
- Multi-screen navigation flows, full app scaffolds.
- Prototypes whose value is JS behavior (animations, drag/drop, state machines).
- Figma, Sketch, or screenshot-only inputs (HTML source required).
- Asset extraction (images/fonts) — placeholders only.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `xcrun mcpbridge` not found | Xcode < 26.3 | Update Xcode, or let the skill fall back to `Write` + manual preview. |
| Tools disabled / no workspace found | Xcode Tools off, or project not open | Settings → Intelligence → **Xcode Tools = ON**, then open your project. |
| Design URL returns 404 | URL was short-lived / already consumed | Ask Claude to regenerate the design and run `/convert` with the fresh URL. |
| Chrome render step skipped | `claude-in-chrome` MCP not installed | Install it, or run in degraded mode (paste a screenshot back manually). |
| Preview doesn't match after 3 iterations | Layout edge case not covered by the reference mappings | The skill will stop and show the remaining diff — patch by hand from there. |

## Uninstall

```
/plugin uninstall claudedesign-to-swiftui
/plugin marketplace remove claudedesign-to-swiftui
```

## Development

Clone the repo, then point a local marketplace at the folder:

```
git clone https://github.com/heyadam/claudedesign-to-swiftui.git
cd claudedesign-to-swiftui
/plugin marketplace add $(pwd)
/plugin install claudedesign-to-swiftui@claudedesign-to-swiftui
```

Edits to files under `commands/`, `skills/`, or `.claude-plugin/` take effect on the next Claude Code session (or `/plugin reload`).

Validate before publishing:
```
/plugin validate
```

## Versioning & releases

Tag releases with semver:
```
git tag v0.1.0 && git push --tags
```

Users can then pin a specific version by appending `@v0.1.0` when adding the marketplace.

## License

MIT. See [`LICENSE`](LICENSE).

## Author

**Adam Presson** — <me@heyadam.com>
