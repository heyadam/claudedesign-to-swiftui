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
// To use the original fonts, see references/font-mapping.md "Custom font registration".
```

This makes the mapping discoverable and lets the user override per-font without reading the skill source.

## Per-usage sizing

The Google Fonts mapping only picks the **family** (design). Apply size and weight from the CSS at each usage site, per `typography-mapping.md`:

```swift
Text("Hello")
    .font(.system(size: 20, weight: .semibold, design: .serif))   // Newsreader-Semibold 20px
```

## Custom font registration (opt-in, off by default)

Most users won't want their bundle to grow by 8 font families just to match the prototype exactly. The skill defaults to system mapping. If the user explicitly asks for original fonts ("use the actual fonts", "register the Google Fonts", etc.), do this for each family:

1. Determine the variants used in the prototype (parse the URL: `family=Newsreader:wght@400;600` → 400 + 600 weights).
2. For each variant, derive the Google Fonts download URL (or use `curl https://fonts.googleapis.com/css2?...` to get the @font-face CSS, then download each `src: url(...)` `.ttf`/`.woff2`).
3. Save the font files to a temp dir on disk.
4. Use `mcp__xcode-tools__XcodeInsertFile` for each font, targeting a `Fonts/` group inside the main app target. Capture the inserted paths.
5. Use `mcp__xcode-tools__AddInfoPlist` with key `UIAppFonts` and value `["Newsreader-Regular.ttf", "Newsreader-SemiBold.ttf", ...]` (an array of filenames).
6. Replace `.font(.system(...))` calls with `.font(.custom("Newsreader-Regular", size: ...))` (use the PostScript name, not the filename — typically `<Family>-<Weight>` without spaces).

After registering, also update the top-of-file fonts comment to indicate the originals are now bundled.

## Notes on weight matching

System fonts have weights `.ultraLight`, `.thin`, `.light`, `.regular`, `.medium`, `.semibold`, `.bold`, `.heavy`, `.black`. CSS `font-weight` numerals map per `typography-mapping.md`. When the Google Font specifies a non-400 weight (e.g. `Newsreader:wght@600`), match the SwiftUI weight at each usage site — don't try to bake "the family's typical weight" into the mapping.
