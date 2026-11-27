---
name: desktop-input
description: "Use when driving a macOS GUI that the agent's own computer tools cannot handle: typing text that must appear key by key (Vietnamese included), or finding the on-screen position of a button in a canvas app (Google Sheets/Docs menus, Figma, Electron) where no accessibility element exists. Ships two CLIs: vn-type and ocr."
---
# desktop-input (macOS)

Two small binaries that fill the two gaps of the built-in `computer` tool. Nothing else.

| Gap | Fix |
|---|---|
| `computer` inserts text in one shot — the user cannot watch it type | `vn-type` posts one real key event per character |
| `computer` cannot type Vietnamese on some targets | `vn-type` sends Unicode directly, no input-method needed |
| Canvas apps expose no element, so there are no coordinates to click | `ocr` returns the on-screen box of a text label |

**macOS only.** `vn-type` uses `CGEvent`, `ocr` uses the Vision framework. On Linux or Windows use the native tools (`xdotool`/`wtype`, `tesseract`) instead.

Installed by `install.sh` to `$HOME/.local/bin`. Rebuild by hand:

```sh
swiftc -O tools/mac/vn-type.swift -o ~/.local/bin/vn-type
swiftc -O tools/mac/ocr.swift    -o ~/.local/bin/ocr
```

## vn-type — visible typing

```sh
vn-type <interval_ms> "<text>"
vn-type 40 "Sản phẩm"
```

- One `CGEvent` per character, `interval_ms` between them (25–90 is readable; 55 is a good default).
- `\n` becomes a real Return key press.
- Characters are sent as Unicode, so Vietnamese diacritics work with no IME and no clipboard.

**It types into whatever has keyboard focus.** That is the whole risk. Before calling it, prove two things:

1. the element is focused in the app's accessibility tree, and
2. the window is the focused window of a frontmost app.

```sh
agent-desktop get "<ref>" --property states     # must contain "focused"   (if agent-desktop is installed)
```

Without check 2 the text lands in the address bar or another app. Symptom: the window title becomes the text you sent.

Never run it as a long background job while issuing other commands — two writers produce scrambled input.

## ocr — coordinates for canvas apps

```sh
ocr <png>                # prints: x<TAB>y<TAB>w<TAB>h<TAB>text
ocr shot.png | grep -i "Chèn"
```

Capture first, then OCR, then click the returned box centre. Vision's text boxes are top-left origin in image pixels, so add the window origin for desktop coordinates.

Always filter to the one line you need (`grep`, `awk`) — the full list is hundreds of lines and costs tokens.

## Facts worth not rediscovering

- **Gmail compose collapses `\n\n` into one newline.** Three newlines (`\n\n\n`) are required for a blank line between paragraphs. `press("enter")` does nothing inside that contenteditable; `cmd+a` does work.
- **`⌘J` is Chrome's Downloads**, not the Sheets name box, despite the accessibility label "Hộp tên (⌘ + J)". Typing after it destroys cell A1.
- **`setValue` on the Sheets name box appends instead of replacing** — the value ends up concatenated. Select the range with a click and drag or with `⌘A` instead.
- Chrome ships helper processes named like the browser. Counting processes by name reports phantom "second instances"; match on the bundle's main binary only.