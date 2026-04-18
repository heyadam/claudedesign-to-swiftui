# Inline SVG → SF Symbol mapping

Claude designs put UI icons inline as `<svg>` elements (typically 12–24px square in a JSX `iconSvg` map or similar). For each unique inline SVG, **try this table first** before falling back to `Path` translation (`svg-path-translation.md`).

Match on the icon's visual intent — what the user perceives — not byte-equal path data. The path data in the table is a rough fingerprint to help you recognize the shape; small variations (different stroke widths, slightly different corner radii, viewBox 0-12 vs 0-24) still count as a match.

When you match, emit `Image(systemName: "<name>")`. Apply size via `.font(.system(size: 12))` or `.frame(width: 12, height: 12)` to match the prototype's intrinsic size.

## Common iOS UI icons

| Visual | Path-data fingerprint (any viewBox) | SF Symbol |
|---|---|---|
| 3 horizontal lines (hamburger / list) | `M2 3h8M2 6h8M2 9h8` or 3 horizontal `<line>`/`<rect>` | `line.3.horizontal` |
| 3 horizontal lines, last one shorter | `M2 3h8M2 6h8M2 9h5` | `text.alignleft` |
| Bell | rounded bell silhouette with clapper | `bell` (filled: `bell.fill`) |
| Calendar | rect with grid + small marks at top | `calendar` |
| Magnifying glass / search | circle + diagonal handle | `magnifyingglass` |
| Plus | `M6 2v8M2 6h8` (cross) | `plus` |
| Minus | single horizontal stroke centered | `minus` |
| X / close | `M2 2L10 10M10 2L2 10` (two diagonals) | `xmark` |
| Checkmark | `M2 6L5 9L10 3` (down-right then up-right) | `checkmark` |
| Chevron right | `M4 2L8 6L4 10` | `chevron.right` |
| Chevron left | `M8 2L4 6L8 10` | `chevron.left` |
| Chevron up | `M2 8L6 4L10 8` | `chevron.up` |
| Chevron down | `M2 4L6 8L10 4` | `chevron.down` |
| Arrow right | line + arrowhead pointing right | `arrow.right` |
| Arrow left | line + arrowhead pointing left | `arrow.left` |
| Arrow up | line + arrowhead pointing up | `arrow.up` |
| Arrow down | line + arrowhead pointing down | `arrow.down` |
| Heart | classic two-lobed heart | `heart` (filled: `heart.fill`) |
| Star | 5-point star | `star` (filled: `star.fill`) |
| Gear / settings | toothed circle | `gearshape` |
| House / home | triangle roof + square body | `house` (filled: `house.fill`) |
| Person / user | circle head + rounded body | `person` (filled: `person.fill`) |
| Person in circle | head+body inside circle outline | `person.crop.circle` |
| Trash / delete | bin with lid | `trash` |
| Pencil / edit | diagonal pencil | `pencil` |
| Camera | rect with lens circle + viewfinder bump | `camera` |
| Image / photo | rect with mountain + sun | `photo` |
| Paperclip / attachment | curved paperclip | `paperclip` |
| Share (iOS) | square with up arrow exiting top | `square.and.arrow.up` |
| Three dots horizontal | `•••` aligned | `ellipsis` |
| Three dots vertical | `•` stacked | `ellipsis` (rotated) or use `Image(systemName: "ellipsis").rotationEffect(.degrees(90))` |
| Info circle | `i` inside a circle | `info.circle` |
| Question circle | `?` inside a circle | `questionmark.circle` |
| Lock closed | rectangle with shackle on top | `lock` (filled: `lock.fill`) |
| Lock open | shackle tilted out | `lock.open` |
| Eye | eye with pupil | `eye` (closed: `eye.slash`) |
| Cloud | cloud silhouette | `cloud` (filled: `cloud.fill`) |
| Sun | circle + radial rays | `sun.max` |
| Moon | crescent | `moon` |

## Filled vs outline

If the SVG uses `fill="currentColor"` or any non-`none` fill, prefer the `.fill` variant when available (e.g. `bell.fill` over `bell`). If it uses `stroke` only with `fill="none"`, use the outline form.

## Color

Apply via `.foregroundStyle(...)` — SF Symbols inherit foreground color. Don't use `.font(.system(size:))` for color; that's for sizing only.

## When to use this table vs `Path` fallback

Use the SF Symbol if:
- The icon is a recognizable common UI glyph (anything in the table above)
- A user would not be surprised to see the iOS-native version of that icon
- The match is "close enough" — exact pixel fidelity isn't required for icons

Fall back to `Path` (`svg-path-translation.md`) when:
- The icon is brand-specific or custom (a logo, an app-specific shape)
- The visual identity matters (e.g. a deliberately stylized arrow that doesn't look like `arrow.right`)
- No reasonable match exists in this table

When in doubt, lean SF Symbol. iOS users expect their UI to look native, and one slightly-off chevron is better than a hand-drawn `Path` that looks foreign.

## Edge cases

- **Multiple paths in one SVG** (e.g. an icon with a base shape + accent dot): try matching as a whole first. If no match, fall back to `Path`.
- **Animated SVG** (`<animate>`, `<animateTransform>`): drop the animation; match the static form. Add a `// TODO: prototype had animation` comment.
- **`<use>` references**: resolve and inline before matching.
- **Gradient fills** (`<linearGradient>` inside SVG): SF Symbols don't support gradients. Either use a single `.foregroundStyle(LinearGradient(...))` on the SF Symbol, or fall back to `Path` with the gradient as a fill style.
