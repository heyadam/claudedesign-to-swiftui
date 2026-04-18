# Typography mapping: CSS → SwiftUI

## Font size → preferred text style

Prefer Apple's preferred text styles when the size roughly matches — they scale with Dynamic Type. Fall back to fixed `.system(size:)` only when the prototype demands a specific pixel size.

| CSS `font-size`     | Preferred style       | Fallback fixed                      |
|---------------------|-----------------------|-------------------------------------|
| 11–12px             | `.caption2` / `.caption` | `.system(size: 12)`              |
| 13–14px             | `.footnote` / `.subheadline` | `.system(size: 13)`           |
| 15–17px             | `.callout` / `.body`  | `.system(size: 16)`                 |
| 17–20px             | `.body` / `.headline` | `.system(size: 17, weight: .semibold)` |
| 20–22px             | `.title3`             | `.system(size: 20, weight: .semibold)` |
| 22–28px             | `.title2`             | `.system(size: 22, weight: .bold)`  |
| 28–34px             | `.title`              | `.system(size: 28, weight: .bold)`  |
| 34px+               | `.largeTitle`         | `.system(size: 34, weight: .bold)`  |

Apply with `.font(.body)`, `.font(.title2)`, etc.

## Font weight

| CSS                  | SwiftUI                          |
|----------------------|----------------------------------|
| `font-weight: 300`   | `.fontWeight(.light)`            |
| `font-weight: 400`   | `.fontWeight(.regular)` (default) |
| `font-weight: 500`   | `.fontWeight(.medium)`           |
| `font-weight: 600`   | `.fontWeight(.semibold)`         |
| `font-weight: 700` / `bold` | `.fontWeight(.bold)`      |
| `font-weight: 800` / `900`  | `.fontWeight(.heavy)` / `.fontWeight(.black)` |

Or roll into `.font(.system(size: ..., weight: ...))`.

## Font family

| CSS `font-family`                        | SwiftUI                           |
|------------------------------------------|-----------------------------------|
| `system-ui` / `-apple-system` / `sans-serif` | `.font(.system(...))` (default)  |
| `'SF Pro Display', sans-serif`           | `.font(.system(...))` (it's the system font) |
| `'SF Mono', monospace` / `monospace`     | `.font(.system(.body, design: .monospaced))` |
| `serif` / `'New York'`                   | `.font(.system(.body, design: .serif))` |
| `'Helvetica Neue'`, `'Arial'`            | `.font(.system(...))` (close enough; iOS users expect SF) |
| Custom web font (e.g., `'Inter'`)        | `.font(.custom("Inter-Regular", size: 16))` + add font to Xcode project + Info.plist `UIAppFonts` |

For custom fonts, leave a `// TODO: register 'Inter' font in Info.plist UIAppFonts and add the .ttf to the Xcode target` comment.

## Color

`color: ...` → `.foregroundStyle(...)`. See `styling-mapping.md` for the color value syntax.

## Line height & spacing

| CSS                          | SwiftUI                                   |
|------------------------------|-------------------------------------------|
| `line-height: 1.5` (font-size: 16) | `.lineSpacing(8)` (additional line gap, in points: `(line-height − 1) × font-size`) |
| `letter-spacing: 0.5px`      | `.tracking(0.5)`                          |
| `text-transform: uppercase`  | Apply `.uppercased()` to the string itself |
| `text-decoration: underline` | `.underline()`                            |
| `text-decoration: line-through` | `.strikethrough()`                     |

## Text alignment

| CSS                     | SwiftUI                                                  |
|-------------------------|----------------------------------------------------------|
| `text-align: left`      | `.multilineTextAlignment(.leading)` (default)            |
| `text-align: center`    | `.multilineTextAlignment(.center)` + `.frame(maxWidth: .infinity)` |
| `text-align: right`     | `.multilineTextAlignment(.trailing)` + `.frame(maxWidth: .infinity, alignment: .trailing)` |
| `white-space: nowrap`   | `.lineLimit(1)` + `.fixedSize(horizontal: true, vertical: false)` |
| `text-overflow: ellipsis` | `.lineLimit(1)` + `.truncationMode(.tail)`             |
