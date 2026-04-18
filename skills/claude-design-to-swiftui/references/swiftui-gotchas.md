# SwiftUI gotchas the build will catch

Compile-time problems specific to SwiftUI that aren't obvious from the CSS-to-SwiftUI translation. If a build error mentions any of the symptoms below, jump to the matching fix instead of debugging from scratch.

## Expression-too-complex / type-checker timeout

**Symptom:** "The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions" — or a build that takes 30+ seconds and then fails on a `body` or `#Preview` that looks fine.

**Common triggers:**
- `ForEach(Array(items.enumerated()), id: \.offset) { ... }` inside a `ZStack`/`VStack` with several other modifiers — the tuple destructuring + nested closures explodes the type-inference search
- More than ~6 chained modifiers on a single view
- Deeply nested ternary expressions to pick colors/sizes
- A `ZStack` with many children where each child has its own modifier chain

**Fix:** extract subviews. The compiler type-checks each `View` body in isolation, so splitting the work breaks the combinatorial blowup.

```swift
// Before — type-checker chokes
struct Card: View {
    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ItemRow(item: item)
                    .offset(y: CGFloat(index) * 60)
                    .opacity(index == selected ? 1 : 0.5)
            }
        }
    }
}

// After — extract the row, drop Array(...enumerated()) when you don't need the index
struct Card: View {
    var body: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { index in
                rowAt(index)
            }
        }
    }

    @ViewBuilder
    private func rowAt(_ index: Int) -> some View {
        ItemRow(item: items[index])
            .offset(y: CGFloat(index) * 60)
            .opacity(index == selected ? 1 : 0.5)
    }
}
```

Or extract a full `private struct CardRow: View` if the row gets non-trivial. **Prefer indices over `Array(...).enumerated()` when you don't need both** — the tuple form is the worst offender.

## `ForEach` with non-Identifiable data

**Symptom:** "Initializer 'init(_:content:)' requires that 'X' conform to 'Identifiable'" or "Generic parameter 'ID' could not be inferred."

**Fix:** add `id: \.self` if the elements are `Hashable`, or `id: \.someUniqueProperty`. Don't make the model `Identifiable` just for a `ForEach` — that ripples through callers.

```swift
ForEach(items, id: \.self) { item in ... }
ForEach(users, id: \.email) { user in ... }
```

## `#Preview` won't render even though the file builds

**Symptom:** the file compiles, but the SwiftUI Preview canvas shows "Preview not loaded" or "Build failed for previews."

**Common causes:**
- Preview references a value that doesn't have a default initializer (e.g. a custom `@Environment` key with no default)
- Preview body itself has the expression-complexity problem above
- The view depends on assets in `Assets.xcassets` that haven't been added yet (an `Image("Foo")` where `Foo` isn't in the catalog returns a debug-only assertion in the preview process but builds fine)

**Fix:** wrap the preview body in a small wrapper struct if it's complex; supply mock data; verify referenced assets exist.

## `Color(hex:)` doesn't compile

**Symptom:** "Type 'Color' has no member 'init(hex:)'" — SwiftUI's `Color` doesn't ship with a hex initializer.

**Fix:** the file already emits a `fileprivate extension Color { init(hex: String) { ... } }` at the bottom. If the build can't find it, the extension was dropped or placed inside the view struct. Make sure it's at file scope (after `#Preview {}`).

## `LinearGradient` requires an initializer

**Symptom:** "Cannot convert value of type 'LinearGradient' to expected argument type" when passing a gradient where a `Color` is expected.

**Fix:** `.foregroundStyle(LinearGradient(...))` works (both are `ShapeStyle`); `.foregroundColor(LinearGradient(...))` does NOT (expects `Color`). Use `.foregroundStyle` for any non-`Color` style. Same applies to `.fill(...)` (fine) vs `.background(Color(...))` (only `Color`).

## `Image(systemName:)` size doesn't change

**Symptom:** SF Symbol renders at default size even after `.frame(...)`.

**Fix:** SF Symbols size by font metrics, not frame. Use `.font(.system(size: 24))` or `.imageScale(.large)`. `.frame(...)` only affects the view's hit area.

## Tall content cut off at viewport in `RenderPreview`

This isn't a build error, but it affects auto-diff. See **SKILL.md step 7** for the workaround (force the preview frame to the full content height before calling `RenderPreview`).

## When in doubt, build incrementally

If you've translated a complex view and the build hangs, comment out the bottom half of the `body` and rebuild. Bisect until you find the offending chunk, then split it into a subview. Faster than reading compiler errors that don't pinpoint the line.
