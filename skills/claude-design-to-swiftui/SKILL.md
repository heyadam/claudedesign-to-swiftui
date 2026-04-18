---
name: claude-design-to-swiftui
description: This skill should be used when the user asks to "convert a Claude design to SwiftUI", "turn a prototype into iOS code", "convert HTML to SwiftUI", or provides a Claude design URL (e.g. https://api.anthropic.com/v1/design/h/<id>?open_file=<name>) or .tar.gz archive to translate. Fetches the design, renders the prototype, generates a single SwiftUI View file, writes it into the active Xcode workspace, builds it, renders the SwiftUI preview, and visually diffs against the prototype until they match.
---

# HTML prototype → SwiftUI View

This skill converts a Claude-generated HTML/CSS prototype (delivered as a design URL from `api.anthropic.com/v1/design/h/...`, or a local `.tar.gz` archive) into a single SwiftUI View file inside the user's active Xcode workspace.

The output is **one self-contained `.swift` file**: one `View` struct + a `#Preview`. No multi-screen navigation, no JS interactivity, no asset extraction — visual layout fidelity only.

## Required MCP servers

This skill calls into two MCP servers. If either is missing, stop and tell the user how to enable it.

- **`xcode-tools`** (Apple's native Xcode MCP, ships with Xcode 26.3+ as `xcrun mcpbridge`). Bundled in this plugin's `.mcp.json`. The user must enable it once: **Xcode → Settings (⌘,) → Intelligence → Xcode Tools → ON**. Xcode must be running with the target project open.
- **`claude-in-chrome`** (user-installed). Used to render the HTML prototype for screenshotting.

## Workflow

Follow these steps in order. Do not skip the build or visual-diff steps.

### 1. Fetch the design

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/claude-design-to-swiftui/scripts/fetch.sh" <design-url-or-tarball-path>
```

Accepts either a Claude design URL (`https://api.anthropic.com/v1/design/h/<id>?open_file=<name>`) or a local `.tar.gz` path. The script downloads (if needed), unpacks to a temp directory, and prints the **entry HTML path** on stdout. Entry resolution: URL-decoded `open_file=` query param → `index.html` → first `*.html`. Capture the printed path.

Note: design URLs are one-shot/short-lived. Fetch immediately; if it 404s, ask the user for a fresh URL.

### 2. Render the prototype in Chrome

Use `claude-in-chrome` to render the prototype at iPhone-class viewport:

1. `mcp__claude-in-chrome__tabs_create_mcp` → open `file://<entry-html-path>`.
2. `mcp__claude-in-chrome__resize_window` → 390x844 (iPhone 15 Pro logical size).
3. `mcp__claude-in-chrome__computer` (screenshot action) → capture the rendered page.

Keep this screenshot — the **prototype reference** for step 7's diff loop.

### 3. Read the HTML/CSS source

Read the entry HTML and every linked stylesheet (`<link rel="stylesheet">`) and inline `<style>` block. Build a mental model of:

- The DOM tree (containers, leaves, text)
- The styles applied to each container (layout mode, spacing, colors, typography, borders, shadows)
- Repeated patterns that should become reusable subviews

Skip `<script>` tags — JS behavior is out of scope.

### 4. Translate to SwiftUI

Walk the DOM top-down using the reference mappings (loaded on demand):

- **Layout containers** → `references/layout-mapping.md` (flex/grid/block → VStack/HStack/ZStack/Grid/ScrollView)
- **CSS properties** → `references/styling-mapping.md` (padding, background, border, shadow → SwiftUI modifiers)
- **Typography** → `references/typography-mapping.md` (font-family/size/weight → `.font()` / `.fontWeight()` / `.lineSpacing()`)
- **Common patterns** (cards, buttons, list rows, nav bars) → `references/component-patterns.md`

When unsure how a chunk maps, see `examples/01-landing-card/` and `examples/02-list-with-rows/` for end-to-end before/after pairs.

Translation rules:
- Preserve hierarchy — wrapping `<div>` becomes a wrapping `VStack` (or whatever container fits).
- Inline literal pixel values (`padding: 16px` → `.padding(16)`); don't abstract into design tokens for v1.
- Use `Color(hex:)` from a **`fileprivate extension Color`** at the bottom of the file (so it doesn't collide with helpers in the user's project).
- `Image(systemName: ...)` only when the prototype has a clear iconographic glyph; otherwise `Image("placeholder-name")` with a `// TODO: add asset` comment.
- Wrap in `ScrollView` if content is taller than 844pt.

### 5. Locate the Xcode workspace and write the file

1. Call `mcp__xcode-tools__XcodeListWindows` to find the open workspace and its on-disk root path.
2. Pick a meaningful filename based on the prototype's purpose (e.g., `OnboardingView.swift`, `SettingsListView.swift`). If multiple workspace folders exist, ask the user which target group to write into. If only one obvious group exists, write there.
3. Call `mcp__xcode-tools__XcodeWrite` with the chosen path and the generated SwiftUI source.

Required file structure:

```swift
import SwiftUI

struct MeaningfulName: View {
    var body: some View {
        // ...translated layout...
    }
}

#Preview {
    MeaningfulName()
}

// At file bottom, only if any hex colors are used:
fileprivate extension Color {
    init(hex: String) { /* ... */ }
}
```

The file must compile standalone — no external packages, no references to types defined elsewhere in the user's project.

### 6. Build and fix until clean

1. Call `mcp__xcode-tools__BuildProject` for the active scheme.
2. If errors:
   - Call `mcp__xcode-tools__XcodeListNavigatorIssues` to read structured diagnostics.
   - Patch the file with `mcp__xcode-tools__XcodeUpdate`.
   - Re-run `BuildProject`.
   - Loop. If the same error recurs after two patch attempts, surface it to the user with the diagnostic and your interpretation.
3. Continue once the build succeeds.

### 7. Render the SwiftUI preview and visually diff

1. Call `mcp__xcode-tools__RenderPreview` for the file you just wrote — it returns the actual rendered preview as an image.
2. Compare against the prototype screenshot from step 2:
   - Layout: containers in the right positions, with the right spacing?
   - Sizing: widths/heights/proportions correct?
   - Colors: backgrounds/text/borders match?
   - Typography: font sizes/weights look right?
   - Iconography & images: placeholders in roughly the right spots?
3. Produce a concrete list of discrepancies with proposed patches (specific line edits, not vague "make it more X").
4. Apply patches via `mcp__xcode-tools__XcodeUpdate`, then go back to step 6 (build) → step 7 (re-render).
5. Loop until the diff is acceptable. After three iterations without convergence, stop and present the remaining diff to the user.

When done, show the user: the prototype screenshot, the final preview screenshot, and the path to the file you wrote.

## Fallback when MCP servers are unavailable

If `xcode-tools` MCP is not available (e.g., Xcode < 26.3, MCP not enabled, or no project open):
- Use the standard `Write` tool to emit the `.swift` file. Ask the user where to put it.
- Skip steps 6 (build) and 7 (auto-diff). Instead, ask the user to open it in Xcode, run the SwiftUI Preview manually, screenshot it, and paste it back. Then do the visual diff manually.

If `claude-in-chrome` MCP is not available:
- Tell the user the prototype reference screenshot can't be captured automatically. Offer to skip the screenshot step and proceed without a visual reference (degraded mode), or ask them to open the HTML themselves and paste a screenshot.

## When NOT to use this skill

- Multi-screen flows or navigation hierarchies — this emits one View only.
- Prototypes whose primary value is JS interactivity (animations, drag/drop, state machines).
- Requests to generate a full Xcode project from scratch.
- Conversions from Figma, Sketch, or screenshot-only inputs (no HTML source).
