# Component patterns

Recipes for the recurring building blocks that show up in most prototypes. When you recognize one of these in the HTML, prefer the recipe over translating the markup atom-by-atom.

## Color helper (always include if any hex used)

Use `fileprivate` so it cannot collide with a `Color(hex:)` extension elsewhere in the user's project.

```swift
fileprivate extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6: (r, g, b, a) = (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255, 1)
        case 8: (r, g, b, a) = (Double((v >> 24) & 0xFF) / 255, Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
        default: (r, g, b, a) = (0, 0, 0, 1)
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
```

## Card

A bordered/rounded container with padding and an optional shadow.

```swift
VStack(alignment: .leading, spacing: 12) {
    // ...content...
}
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 12))
.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
```

## Primary button

`<button class="btn btn-primary">Continue</button>`:

```swift
Button {
    // action
} label: {
    Text("Continue")
        .font(.body.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
```

## Secondary / outline button

```swift
Button {
    // action
} label: {
    Text("Skip")
        .font(.body.weight(.semibold))
        .foregroundStyle(Color.accentColor)
        .frame(maxWidth: .infinity, minHeight: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 1)
        )
}
```

## List row

`<li>` with leading icon, label, trailing chevron:

```swift
HStack(spacing: 12) {
    Image(systemName: "person.circle")
        .font(.title2)
        .foregroundStyle(.secondary)
    VStack(alignment: .leading, spacing: 2) {
        Text("Account")
            .font(.body)
        Text("Manage profile")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
    Spacer()
    Image(systemName: "chevron.right")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.tertiary)
}
.padding(.vertical, 12)
.padding(.horizontal, 16)
.contentShape(Rectangle())
```

## Nav bar / header

`<header>` with title centered, leading back button, trailing action:

```swift
HStack {
    Button { /* back */ } label: {
        Image(systemName: "chevron.left")
            .font(.body.weight(.semibold))
    }
    Spacer()
    Text("Settings")
        .font(.headline)
    Spacer()
    Button { /* action */ } label: {
        Image(systemName: "ellipsis")
            .font(.body.weight(.semibold))
    }
}
.padding(.horizontal, 16)
.frame(height: 44)
```

## Avatar

`<img class="avatar">`:

```swift
Image("avatar-placeholder") // TODO: add asset
    .resizable()
    .scaledToFill()
    .frame(width: 48, height: 48)
    .clipShape(Circle())
```

## Badge / chip

`<span class="badge">New</span>`:

```swift
Text("New")
    .font(.caption.weight(.semibold))
    .foregroundStyle(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.accentColor)
    .clipShape(Capsule())
```

## Form field

`<input type="text" placeholder="Email">`:

```swift
TextField("Email", text: $email)
    .textFieldStyle(.plain)
    .padding(12)
    .background(Color(hex: "F5F5F7"))
    .clipShape(RoundedRectangle(cornerRadius: 10))
```

Add `@State private var email: String = ""` to the View.

## Tab bar (bottom)

`<nav class="tabbar">`:

```swift
TabView {
    HomeView().tabItem { Label("Home", systemImage: "house") }
    SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
    ProfileView().tabItem { Label("Profile", systemImage: "person") }
}
```

(Out of v1 scope if it implies multi-screen — call out and emit a single tab's content instead.)

## Divider

`<hr>` or a `<div>` styled as a 1px line:

```swift
Divider()
// or for a custom-color line:
Rectangle()
    .fill(Color(hex: "E5E5EA"))
    .frame(height: 1)
```
