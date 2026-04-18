# Binary `<img>` → asset catalog import

This applies only when the prototype HTML references a binary image file inside the unpacked design directory:

```html
<img src="./img/hero.png" alt="..."/>
<img src="../assets/logo.jpg"/>
```

External CDN URLs (`<img src="https://...">`) skip this whole flow — emit `AsyncImage(url: URL(string: "...")!)` directly.

In observed Claude designs, local binary `<img>` references are essentially nonexistent (icons are inlined as `<svg>`). This handler exists for the rare design that does include them.

## When to invoke

For every `<img src>` whose `src` resolves to a file under the unpack directory (i.e., line 3 of `fetch.sh` output):

1. Resolve the relative `src` against the entry HTML's directory to get an absolute on-disk path. Verify the file exists.
2. Decide an asset name: derive from the filename (e.g. `hero.png` → `hero`, `IconLogo.jpg` → `iconLogo`). Camel-case, no extension. If two different files would collide, suffix with a counter (`hero`, `hero2`).
3. Run the import recipe below.

## Import recipe

Find the project's primary asset catalog:

```
mcp__xcode-tools__XcodeGlob: pattern = "**/*.xcassets"
```

- **No catalog**: skip import. Emit `Image("\(name)")` with `// TODO: no Assets.xcassets in project — add the catalog and import \(filename) manually` and stop.
- **One catalog**: use it.
- **Multiple catalogs**: ask the user which one (or pick the one whose path is closest to the .swift file you're about to write into).

Create the imageset directory:

```
mcp__xcode-tools__XcodeMakeDir: path = "<catalog>/<assetName>.imageset"
```

Write the `Contents.json`:

```
mcp__xcode-tools__XcodeWrite:
  path: "<catalog>/<assetName>.imageset/Contents.json"
  content: |
    {
      "images" : [
        {
          "filename" : "<originalFilename>",
          "idiom" : "universal",
          "scale" : "1x"
        },
        {
          "idiom" : "universal",
          "scale" : "2x"
        },
        {
          "idiom" : "universal",
          "scale" : "3x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
```

Copy the binary file (XcodeWrite is text-only — must use shell):

```bash
cp "<src-absolute-path>" "<catalog>/<assetName>.imageset/<originalFilename>"
```

Don't bother with `XcodeInsertFile` here — files inside `.xcassets` are picked up by Xcode's folder reference automatically; no individual project registration is needed.

## Multi-resolution (1x/2x/3x)

If the prototype only ships one resolution, mark it as `1x` and leave the `2x`/`3x` slots empty (Xcode will scale automatically). If you find paired files like `hero.png` + `hero@2x.png` + `hero@3x.png`, populate all three slots:

```json
{
  "images" : [
    { "filename" : "hero.png",    "idiom" : "universal", "scale" : "1x" },
    { "filename" : "hero@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "hero@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  ...
}
```

Copy each `.png` into the imageset directory.

## Emit in SwiftUI

```swift
Image("hero")
    .resizable()                         // if the original CSS sized it (most do)
    .aspectRatio(contentMode: .fit)      // or .fill, based on CSS object-fit
    .frame(width: <css-width>, height: <css-height>)
    .clipShape(RoundedRectangle(cornerRadius: <css-border-radius>))
```

Match `object-fit`:

| CSS | SwiftUI |
|---|---|
| `object-fit: contain` (default) | `.aspectRatio(contentMode: .fit)` |
| `object-fit: cover` | `.aspectRatio(contentMode: .fill)` + `.clipped()` |
| `object-fit: fill` | `.resizable()` without `.aspectRatio(...)` |
| `object-fit: none` | No `.resizable()`; use `.frame(...)` to clip |

## External URL `<img>`

```html
<img src="https://images.unsplash.com/photo-..." width="200" height="120"/>
```

→

```swift
AsyncImage(url: URL(string: "https://images.unsplash.com/photo-...")!) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    Color.gray.opacity(0.2)
}
.frame(width: 200, height: 120)
.clipped()
```

Don't try to download and bundle CDN images — they're often huge and may be licensed for runtime use only. `AsyncImage` is the right fit.

## SVG `<img src="foo.svg">`

If the design references an SVG as a separate file (not inline), prefer:

1. Read the SVG file. If it's icon-shaped, treat it as an inline SVG and run it through `svg-to-sfsymbol.md` / `svg-path-translation.md`.
2. Otherwise (illustration, complex SVG): bundle as an asset. Xcode supports SVG in `.xcassets` since iOS 13. Set `Contents.json` `"properties": { "preserves-vector-representation": true, "template-rendering-intent": "original" }`. Copy the `.svg` into the imageset.
