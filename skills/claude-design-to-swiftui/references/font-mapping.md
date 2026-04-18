# Google Fonts → SwiftUI font mapping

Claude designs commonly load fonts from Google Fonts via:

```html
<link href="https://fonts.googleapis.com/css2?family=Newsreader:..&family=Geist:..&family=Geist+Mono:..&family=Fraunces:.." rel="stylesheet"/>
```

For each family in the `family=` chain (parse the `&family=` segments, URL-decode `+` to space), pick the closest match below. **Default behavior is system-font mapping** — bundling the actual `.ttf` is opt-in (see "Custom font registration" at the bottom).

## System-font mapping (default)

The mapping picks SF system equivalents by the font's design (serif vs sans-serif vs monospace) and visual character (rounded vs default). This loses brand identity but ships zero new bundle weight and works across all iOS versions.

| Google Font | SwiftUI mapping | Notes |
|---|---|---|
| **Geist** | `.font(.system(.body, design: .default))` | Sans-serif, neutral; SF Pro is the closest native equivalent |
| **Geist Mono** | `.font(.system(.body, design: .monospaced))` | SF Mono |
| **Inter** | `.font(.system(.body, design: .default))` | Sans-serif, similar metrics to SF Pro |
| **DM Sans** | `.font(.system(.body, design: .default))` | Sans-serif |
| **IBM Plex Sans** | `.font(.system(.body, design: .default))` | Sans-serif; slightly more geometric than SF — acceptable trade |
| **IBM Plex Mono** | `.font(.system(.body, design: .monospaced))` | SF Mono |
| **IBM Plex Serif** | `.font(.system(.body, design: .serif))` | New York is SF's serif equivalent |
| **Newsreader** | `.font(.system(.body, design: .serif))` | Editorial serif → New York |
| **Fraunces** | `.font(.system(.body, design: .serif))` | Display serif → New York; consider `.fontWeight(.semibold)` for character |
| **Instrument Serif** | `.font(.system(.body, design: .serif))` | Editorial serif → New York |
| **Playfair Display** | `.font(.system(.largeTitle, design: .serif))` | Display serif, headline use → New York larger sizes |
| **Source Serif 4** | `.font(.system(.body, design: .serif))` | New York |
| **Lora** | `.font(.system(.body, design: .serif))` | New York |
| **Merriweather** | `.font(.system(.body, design: .serif))` | New York |
| **JetBrains Mono** | `.font(.system(.body, design: .monospaced))` | SF Mono |
| **Fira Code** | `.font(.system(.body, design: .monospaced))` | SF Mono (no native ligatures) |
| **Source Code Pro** | `.font(.system(.body, design: .monospaced))` | SF Mono |
| **Roboto** | `.font(.system(.body, design: .default))` | SF Pro |
| **Roboto Mono** | `.font(.system(.body, design: .monospaced))` | SF Mono |
| **Roboto Serif** | `.font(.system(.body, design: .serif))` | New York |
| **Open Sans** | `.font(.system(.body, design: .default))` | SF Pro |
| **Lato** | `.font(.system(.body, design: .default))` | SF Pro |
| **Montserrat** | `.font(.system(.body, design: .default))` | SF Pro (Montserrat is geometric — slight mismatch but acceptable) |
| **Poppins** | `.font(.system(.body, design: .rounded))` | SF Rounded — closer match than `.default` for Poppins's rounded character |
| **Nunito** | `.font(.system(.body, design: .rounded))` | SF Rounded |
| **Quicksand** | `.font(.system(.body, design: .rounded))` | SF Rounded |
| **Work Sans** | `.font(.system(.body, design: .default))` | SF Pro |
| **Manrope** | `.font(.system(.body, design: .default))` | SF Pro |
| **Space Grotesk** | `.font(.system(.body, design: .default))` | SF Pro |
| **Space Mono** | `.font(.system(.body, design: .monospaced))` | SF Mono |
| **Plus Jakarta Sans** | `.font(.system(.body, design: .default))` | SF Pro |
| **Outfit** | `.font(.system(.body, design: .default))` | SF Pro |
| **Bricolage Grotesque** | `.font(.system(.body, design: .default))` | SF Pro |

For any Google Font not in the table, classify by the font's visible characteristics — does the design use it for body text (sans-serif → `.default`) or editorial headlines (serif → `.serif`)? Default to `.default` if unsure.

## Required: top-of-file fonts comment

When any Google Fonts are detected, emit a comment block at the top of the generated `.swift` file (after `import SwiftUI`):

```swift
import SwiftUI

// Fonts detected in prototype (mapped to SF equivalents):
//   Newsreader        → .system(design: .serif)       (used for headlines)
//   Geist             → .system(design: .default)
//   Geist Mono        → .system(design: .monospaced)
// To use the originals, see references/font-mapping.md "Original-font fidelity".
```

This makes the mapping discoverable and lets the user override per-font without reading the skill source.

## Per-usage sizing

The Google Fonts mapping only picks the **family** (design). Apply size and weight from the CSS at each usage site, per `typography-mapping.md`:

```swift
Text("Hello")
    .font(.system(size: 20, weight: .semibold, design: .serif))   // Newsreader-Semibold 20px
```

## Original-font fidelity (manual user steps)

The Xcode 26.3 MCP (`xcrun mcpbridge`) does not expose tools for adding files to `.xcodeproj` build phases or for editing `Info.plist`. Custom-font registration cannot be automated through this skill.

If the user explicitly asks for original fonts ("use the actual fonts", "register the Google Fonts", etc.), still emit `.font(.custom("PostScriptName", size:))` calls in the generated SwiftUI — but **also** emit a top-of-file `// MARK: - Manual font setup required` comment block listing the steps the user must do in Xcode by hand:

```swift
// MARK: - Manual font setup required
// This view uses .font(.custom(...)) for the original Google Font families.
// To make those fonts available, you must:
//   1. Download the .ttf files from fonts.google.com for each family + weight used below.
//   2. Drag the .ttf files into your Xcode target (check "Copy items if needed" and target membership).
//   3. Open the target's Info.plist and add a "Fonts provided by application" (UIAppFonts) array
//      with each filename, e.g. ["Newsreader-Regular.ttf", "Newsreader-SemiBold.ttf", ...].
//   4. The PostScript name used in .font(.custom(...)) below is typically <Family>-<Weight>
//      without spaces (verify in Font Book if a font doesn't load).
```

Then list each `.font(.custom(...))` call's PostScript name in a comment so the user can match them to downloads:

```swift
// Custom fonts referenced:
//   Newsreader-Regular     (Newsreader 400)
//   Newsreader-SemiBold    (Newsreader 600)
//   Geist-Regular          (Geist 400)
//   GeistMono-Regular      (Geist Mono 400)
```

This still beats v0.2.x (which silently swapped to system fonts and never told the user). The user gets working SwiftUI plus a copy-pasteable checklist.

Until/unless a future MCP version adds project-mutation tools (or this plugin gains an out-of-band path via AppleScript / `project.pbxproj` editing), this is the boundary.

## Notes on weight matching

System fonts have weights `.ultraLight`, `.thin`, `.light`, `.regular`, `.medium`, `.semibold`, `.bold`, `.heavy`, `.black`. CSS `font-weight` numerals map per `typography-mapping.md`. When the Google Font specifies a non-400 weight (e.g. `Newsreader:wght@600`), match the SwiftUI weight at each usage site — don't try to bake "the family's typical weight" into the mapping.
