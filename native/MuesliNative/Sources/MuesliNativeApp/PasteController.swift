import AppKit
import ApplicationServices
import Foundation
import MuesliCore

enum PasteController {
    /// The NSPasteboard.org transient type marker — tells clipboard managers this content is temporary.
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
    /// The NSPasteboard.org restored type marker — tells clipboard managers this is a restore, not a new copy.
    private static let restoredType = NSPasteboard.PasteboardType("org.nspasteboard.RestoredType")

    /// Bundle identifiers of apps that use Cmd+Shift+V instead of Cmd+V for paste.
    private static let shiftPasteApps: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
    ]

    static func paste(text: String) {
        guard !text.isEmpty else { return }

        let pasteboard = NSPasteboard.general

        // 1. Save current clipboard state (plain text only for v1)
        let savedText = pasteboard.string(forType: .string)
        let savedChangeCount = pasteboard.changeCount

        // 2. Place polished text on clipboard with transient marker
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        pasteboard.setData(Data(), forType: transientType)

        // 3. Re-validate frontmost app and simulate paste after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            simulatePaste(for: bundleId)

            // 4. Restore original clipboard after 200ms (industry standard per Keyboard Maestro)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Only restore if no other app has written to the clipboard since we did
                // (changeCount incremented once by our clearContents+setString)
                let currentCount = NSPasteboard.general.changeCount
                guard currentCount == savedChangeCount + 1 else {
                    fputs("[muesli-native] clipboard changed externally, skipping restore\n", stderr)
                    return
                }

                NSPasteboard.general.clearContents()
                if let saved = savedText {
                    NSPasteboard.general.setString(saved, forType: .string)
                    NSPasteboard.general.setData(Data(), forType: restoredType)
                }
            }
        }
    }

    /// Type text directly via CGEvent keyboard simulation without touching the clipboard.
    /// Each Character is posted as a keydown+keyup pair with its UTF-16 code units.
    static func typeText(_ text: String) {
        guard !text.isEmpty else { return }
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            fputs("[muesli-native] failed to create event source for typeText\n", stderr)
            return
        }
        for char in text {
            var utf16 = Array(char.utf16)
            utf16.withUnsafeMutableBufferPointer { buf in
                guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                      let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
                else { return }
                keyDown.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: buf.baseAddress)
                keyUp.keyboardSetUnicodeString(stringLength: buf.count, unicodeString: buf.baseAddress)
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }

    private static func simulatePaste(for bundleId: String? = nil) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            fputs("[muesli-native] failed to create event source for paste\n", stderr)
            return
        }
        let keyCode: CGKeyCode = 9 // V key on US layout
        let useShift = bundleId.map { shiftPasteApps.contains($0) } ?? false

        let commandDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        commandDown?.flags = useShift ? [.maskCommand, .maskShift] : .maskCommand
        let commandUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        commandUp?.flags = useShift ? [.maskCommand, .maskShift] : .maskCommand
        commandDown?.post(tap: .cghidEventTap)
        commandUp?.post(tap: .cghidEventTap)
    }
}
