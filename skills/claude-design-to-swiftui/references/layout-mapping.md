# Layout mapping: HTML/CSS → SwiftUI

Lookup table for translating layout containers. Apply the first row whose CSS pattern matches.

## Container by display mode

| CSS                                           | SwiftUI container                                    | Notes                                              |
|-----------------------------------------------|------------------------------------------------------|----------------------------------------------------|
| `display: flex; flex-direction: column`       | `VStack(alignment:, spacing:)`                       | Default flex direction in many resets is row.       |
| `display: flex; flex-direction: row`          | `HStack(alignment:, spacing:)`                       |                                                    |
| `display: flex` (no direction)                | `HStack(...)`                                        | CSS default is row.                                |
| `display: grid`                               | `Grid { GridRow { ... } }` or `LazyVGrid`            | `LazyVGrid` for repeating columns of cards.        |
| `display: block` with stacked children        | `VStack(alignment: .leading, spacing: 0)`            | Block is the default — most `<div>` containers.    |
| `display: inline-block` siblings              | `HStack(spacing: 0)`                                 |                                                    |
| `position: absolute` overlay on parent        | `ZStack(alignment: ...)`                             | Map `top/left` offsets via `.offset(x:y:)`.        |
| `position: absolute` small decoration on a single element (e.g. a degree symbol after a number, a badge dot on an icon) | `.overlay(alignment:) { decoration.offset(...) }` on the parent element | Don't use `HStack` + `.kerning()` — kerning won't reproduce absolute pixel offsets, and an `HStack` adds layout that the original didn't have. `.overlay` lets the decoration float in its own coordinate space without affecting the parent's intrinsic size. |
| `overflow: auto` / `overflow-y: scroll`       | `ScrollView(.vertical)`                              | Use `.horizontal` for `overflow-x`.                |
| `<ul>` / `<ol>` of repeated rows              | `List { ForEach(...) { ... } }` or `ScrollView+VStack` | Use `List` for native row styling; `VStack` for custom. |

## Spacing & alignment

| CSS                                  | SwiftUI                                                  |
|--------------------------------------|----------------------------------------------------------|
| `gap: 12px` (flex/grid)              | `spacing: 12` on the stack                               |
| `justify-content: center` (row flex) | `HStack { Spacer(); ...; Spacer() }` or `.frame(maxWidth: .infinity)` |
| `justify-content: space-between`     | `HStack { a; Spacer(); b }`                              |
| `justify-content: flex-end`          | `HStack { Spacer(); content }`                           |
| `align-items: center` (row flex)     | `HStack(alignment: .center)` (default)                   |
| `align-items: flex-start`            | `HStack(alignment: .top)`                                |
| `align-items: stretch` on column     | `.frame(maxWidth: .infinity)` on children                |
| `text-align: center`                 | `.multilineTextAlignment(.center)` + `.frame(maxWidth: .infinity)` |

## Sizing

| CSS                              | SwiftUI                                       |
|----------------------------------|-----------------------------------------------|
| `width: 100%`                    | `.frame(maxWidth: .infinity)`                 |
| `height: 100%`                   | `.frame(maxHeight: .infinity)`                |
| `width: 200px`                   | `.frame(width: 200)`                          |
| `min-height: 44px`               | `.frame(minHeight: 44)`                       |
| `max-width: 600px`               | `.frame(maxWidth: 600)`                       |
| `aspect-ratio: 16 / 9`           | `.aspectRatio(16/9, contentMode: .fit)`       |

## Decision tree for a new container

1. Does it have `display: flex` or `display: grid`? → use stack/grid per the table above.
2. Are children absolutely positioned over each other? → `ZStack`.
3. Is it scrollable? → wrap in `ScrollView`.
4. Is it a list of repeating rows? → `List` (native styling) or `ForEach` in a `VStack` (custom).
5. Otherwise (default block flow with stacked children) → `VStack(alignment: .leading, spacing: 0)`.
