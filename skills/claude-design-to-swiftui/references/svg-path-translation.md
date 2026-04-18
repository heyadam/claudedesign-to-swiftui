# SVG → SwiftUI `Path` translation

Use this when an inline `<svg>` doesn't match anything in `svg-to-sfsymbol.md`. The output is a `fileprivate struct FooIcon: View` placed at the bottom of the file (next to the `Color` extension).

## Output shape

```swift
fileprivate struct FooIcon: View {
    var body: some View {
        Canvas { ctx, size in
            // for complex multi-element SVGs only
        }
        // OR (preferred for single-path SVGs):
        Path { p in
            // ...path commands translated below...
        }
        .fill(Color.primary)               // if SVG fill != "none"
        .stroke(Color.primary, lineWidth: 1.5)  // if SVG stroke != "none"
        .frame(width: 24, height: 24)      // match SVG viewBox dimensions
    }
}
```

If both fill and stroke are present, use `Path { ... }` twice (once filled, once stroked, in a `ZStack`).

## SVG `viewBox` → SwiftUI coordinate space

SVG `viewBox="0 0 24 24"` maps directly to a 24×24 SwiftUI canvas. Use `.frame(width: 24, height: 24)` on the `Path` to lock the size. If the prototype renders the SVG at a different size (e.g. 12×12), apply the frame at that size instead and the path will scale proportionally **only if** you wrap in `GeometryReader` and scale yourself, OR if you use `.scaleEffect(0.5)`. Simpler: redraw at the target size by dividing all coordinates.

## Path command translation

SVG path data uses single-letter commands. Translate as follows. **Capital = absolute coordinates, lowercase = relative.** Always emit absolute coordinates in SwiftUI; pre-resolve relative ones during translation.

| SVG command | Args | SwiftUI `Path` equivalent |
|---|---|---|
| `M x y` | move to | `p.move(to: CGPoint(x: x, y: y))` |
| `L x y` | line to | `p.addLine(to: CGPoint(x: x, y: y))` |
| `H x` | horizontal line | `p.addLine(to: CGPoint(x: x, y: <currentY>))` |
| `V y` | vertical line | `p.addLine(to: CGPoint(x: <currentX>, y: y))` |
| `C x1 y1 x2 y2 x y` | cubic Bézier | `p.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))` |
| `S x2 y2 x y` | smooth cubic (mirror previous control) | Reflect the previous `C`'s control2 around the current point to compute control1, then `p.addCurve(...)` |
| `Q x1 y1 x y` | quadratic Bézier | `p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x1, y: y1))` |
| `T x y` | smooth quadratic (mirror previous control) | Reflect previous `Q`'s control, then `p.addQuadCurve(...)` |
| `A rx ry x-rot large-arc sweep x y` | elliptical arc | Convert to one or more cubic Béziers (use Apple's `Path.addArc` only if the arc is circular and axis-aligned; otherwise approximate with `addCurve`) |
| `Z` / `z` | close path | `p.closeSubpath()` |

Track the current point and previous control point as you walk the path.

### Worked example

SVG: `<svg viewBox="0 0 12 12"><path d="M2 3h8M2 6h8M2 9h5"/></svg>` (3 horizontal lines, last shorter — typically maps to `text.alignleft` SF Symbol, but as a `Path` example):

```swift
fileprivate struct ListIcon: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 2, y: 3))
            p.addLine(to: CGPoint(x: 10, y: 3))
            p.move(to: CGPoint(x: 2, y: 6))
            p.addLine(to: CGPoint(x: 10, y: 6))
            p.move(to: CGPoint(x: 2, y: 9))
            p.addLine(to: CGPoint(x: 7, y: 9))
        }
        .stroke(Color.primary, lineWidth: 1.5)
        .frame(width: 12, height: 12)
    }
}
```

## Other SVG primitives

| SVG element | SwiftUI |
|---|---|
| `<rect x y width height/>` | `Rectangle()` in a `.frame(...)` with `.position(...)` — or as part of a Path: `p.addRect(CGRect(x:y:width:height:))` |
| `<rect ... rx="r"/>` | `RoundedRectangle(cornerRadius: r)` or `p.addRoundedRect(in:cornerSize:)` |
| `<circle cx cy r/>` | `Circle()` with `.frame(width: 2*r, height: 2*r).position(x: cx, y: cy)` — or in a Path: `p.addEllipse(in: CGRect(x: cx-r, y: cy-r, width: 2*r, height: 2*r))` |
| `<ellipse cx cy rx ry/>` | `Ellipse()` similarly, or `p.addEllipse(in: CGRect(x: cx-rx, y: cy-ry, width: 2*rx, height: 2*ry))` |
| `<line x1 y1 x2 y2/>` | `p.move(to: CGPoint(x: x1, y: y1)); p.addLine(to: CGPoint(x: x2, y: y2))` |
| `<polygon points="x1,y1 x2,y2 ..."/>` | `p.move` to first point, `p.addLine` to each subsequent, `p.closeSubpath()` |
| `<polyline ...>` | Same as polygon but no `closeSubpath()` |
| `<g transform="translate(x,y)">` | Adjust coordinates of children by (x,y) during translation; don't emit a separate transform |
| `<g transform="rotate(deg)">` | Apply `.rotationEffect(.degrees(deg))` to the wrapping subview |

## Fill and stroke attributes

| SVG attribute | SwiftUI |
|---|---|
| `fill="#hex"` | `.fill(Color(hex: "..."))` |
| `fill="currentColor"` | `.fill(Color.primary)` (or whatever foreground style the parent applies) |
| `fill="none"` | Don't apply `.fill()` — only stroke |
| `stroke="#hex"` | `.stroke(Color(hex: "..."), lineWidth: <stroke-width>)` |
| `stroke-width="2"` | `lineWidth: 2` in the `.stroke(...)` call |
| `stroke-linecap="round"` | `style: StrokeStyle(lineWidth: 2, lineCap: .round)` |
| `stroke-linejoin="round"` | `style: StrokeStyle(..., lineJoin: .round)` |
| `stroke-dasharray="4,2"` | `style: StrokeStyle(..., dash: [4, 2])` |
| `opacity="0.5"` | `.opacity(0.5)` on the wrapping shape |
| `fill-rule="evenodd"` | `.fill(Color..., style: FillStyle(eoFill: true))` |

## When to bail

If the SVG has any of:
- `<filter>` (drop shadows, blurs)
- `<mask>` or `<clipPath>` with non-trivial geometry
- `<image>` (raster embedded in SVG)
- `<text>` (text inside SVG — render as SwiftUI `Text` instead)
- `<animate>`, `<animateTransform>` (already noted in `svg-to-sfsymbol.md` — drop)
- More than ~5 `<path>` elements in a single SVG

…stop trying to translate and fall back: emit a placeholder `Image(systemName: "questionmark.square.dashed")` with a `// TODO: complex SVG, see prototype` comment, and inline the SVG source as a comment block so the user can hand-port it.

## Reuse identical SVGs

If the same `<svg>` source (after whitespace normalization) appears multiple times in the prototype, generate one `fileprivate struct FooIcon: View` and reference it everywhere. Don't emit a struct per usage site.
