# Styling mapping: CSS properties → SwiftUI modifiers

Order modifiers as they would conceptually apply: content first, then padding, then frame/background/overlay/border, then clip, then shadow.

## Spacing

| CSS                                | SwiftUI                                       |
|------------------------------------|-----------------------------------------------|
| `padding: 16px`                    | `.padding(16)`                                |
| `padding: 8px 16px`                | `.padding(.vertical, 8).padding(.horizontal, 16)` |
| `padding-top: 12px`                | `.padding(.top, 12)`                          |
| `margin: 16px`                     | Use parent stack `spacing:` or `.padding()` on the child |
| `margin-bottom: 8px` between siblings | Use stack `spacing: 8`                     |

SwiftUI has no `margin` — all space comes from the parent's `spacing` or the child's `.padding`.

## Background & color

| CSS                                | SwiftUI                                                    |
|------------------------------------|------------------------------------------------------------|
| `background: #f5f5f5`              | `.background(Color(hex: "F5F5F5"))`                        |
| `background: white`                | `.background(Color.white)`                                 |
| `background: rgba(0,0,0,0.5)`      | `.background(Color.black.opacity(0.5))`                    |
| `background: linear-gradient(...)` | `.background(LinearGradient(colors: [...], startPoint: .top, endPoint: .bottom))` |
| `color: #333`                      | `.foregroundStyle(Color(hex: "333333"))`                   |
| `opacity: 0.8`                     | `.opacity(0.8)`                                            |

Always include a `Color(hex:)` extension at the bottom of the emitted file when any hex colors are used (see `component-patterns.md`).

## Border & corner

| CSS                                | SwiftUI                                                    |
|------------------------------------|------------------------------------------------------------|
| `border-radius: 12px`              | `.clipShape(RoundedRectangle(cornerRadius: 12))`           |
| `border: 1px solid #ddd`           | `.overlay(RoundedRectangle(cornerRadius: 0).stroke(Color(hex: "DDDDDD"), lineWidth: 1))` |
| `border: 1px solid X` + radius     | `.overlay(RoundedRectangle(cornerRadius: r).stroke(X, lineWidth: 1))` then `.clipShape(...)` |
| `outline: 2px solid blue`          | `.overlay(...stroke...)` (SwiftUI has no outline analog)   |

`.cornerRadius(_:)` is deprecated in newer SwiftUI; prefer `.clipShape(RoundedRectangle(cornerRadius:))`.

## Shadow

| CSS                                              | SwiftUI                                                |
|--------------------------------------------------|--------------------------------------------------------|
| `box-shadow: 0 2px 8px rgba(0,0,0,0.1)`          | `.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)` |
| `box-shadow: 0 0 0 3px blue` (focus ring)        | `.overlay(RoundedRectangle(cornerRadius: r).stroke(.blue, lineWidth: 3))` |

CSS shadow `radius` ≈ 2× the visual blur of SwiftUI's `radius`, so halve the CSS value when copying.

## Visibility & layout escape

| CSS                                | SwiftUI                                       |
|------------------------------------|-----------------------------------------------|
| `display: none`                    | Omit the view, or wrap in `if condition { ... }` |
| `visibility: hidden`               | `.opacity(0)` (still occupies space)          |
| `position: fixed; bottom: 0`       | `.safeAreaInset(edge: .bottom) { ... }` or overlay on root |
| `z-index: 10`                      | Place later in `ZStack` or use `.zIndex(10)`  |

## Cursor / pointer / hover

These don't map — SwiftUI has no hover state on iOS. Drop silently. If the prototype's hover styling is the *primary* visual state (e.g., a button "pressed" look), apply it as the default state and add a `// TODO: pressed-state styling` comment.
