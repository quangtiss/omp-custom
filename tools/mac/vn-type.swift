// vn-type: type Unicode one character at a time as real key events.
// usage: vn-type <interval_ms> <text>
import Cocoa

let args = CommandLine.arguments
guard args.count >= 3, let intervalMs = Double(args[1]) else {
    FileHandle.standardError.write("usage: vn-type <interval_ms> <text>\n".data(using: .utf8)!)
    exit(2)
}
let text = Array(args[2])
let delayMs = max(0, intervalMs)
let src = CGEventSource(stateID: .hidSystemState)

for (i, ch) in text.enumerated() {
    if ch == "\n" {
        let d = CGEvent(keyboardEventSource: src, virtualKey: 36, keyDown: true)
        let u = CGEvent(keyboardEventSource: src, virtualKey: 36, keyDown: false)
        d?.post(tap: .cgAnnotatedSessionEventTap)
        u?.post(tap: .cgAnnotatedSessionEventTap)
        usleep(useconds_t(delayMs * 1000))
        continue
    }
    var utf16 = Array(String(ch).utf16)
    guard let down = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true),
          let up = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false) else { continue }
    down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
    up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
    down.post(tap: .cgAnnotatedSessionEventTap)
    up.post(tap: .cgAnnotatedSessionEventTap)
    if i < text.count - 1 { usleep(useconds_t(delayMs * 1000)) }
}
