import SwiftUI
import MuesliCore

enum MuesliTheme {
    // MARK: - Colors — Warm Beige Palette

    // Backgrounds: warm cream → latte layering
    static let backgroundDeep   = Color.adaptive(dark: 0x1A1714, light: 0xF5F0EB)
    static let backgroundBase   = Color.adaptive(dark: 0x211E19, light: 0xFAF6F1)
    static let backgroundRaised = Color.adaptive(dark: 0x2A2620, light: 0xFFF8F2)
    static let backgroundHover  = Color.adaptive(dark: 0x332E27, light: 0xF0E8DE)

    // MARK: - Surfaces (interactive elements)

    static let surfacePrimary   = Color.adaptive(dark: 0x3A3429, light: 0xEDE5D8)
    static let surfaceSelected  = Color.adaptive(dark: 0x3E3525, light: 0xF5E6D0)
    static let surfaceBorder    = Color.adaptiveAlpha(
        dark: .white, darkAlpha: 0.08,
        light: .black, lightAlpha: 0.06
    )

    // MARK: - Text hierarchy — warm tones

    static let textPrimary = Color.adaptiveAlpha(
        dark: .white, darkAlpha: 0.90,
        light: .black, lightAlpha: 0.85
    )
    static let textSecondary = Color.adaptiveAlpha(
        dark: .white, darkAlpha: 0.58,
        light: .black, lightAlpha: 0.50
    )
    static let textTertiary = Color.adaptiveAlpha(
        dark: .white, darkAlpha: 0.35,
        light: .black, lightAlpha: 0.30
    )

    // MARK: - Accent — warm terracotta/coral

    static let accent           = Color.adaptive(dark: 0xE8956A, light: 0xC2694A)
    static let accentSubtle     = Color.adaptive(dark: 0xE8956A, light: 0xC2694A).opacity(0.12)

    // MARK: - Semantic — warm palette

    static let recording        = Color(hex: 0xD4634B)
    static let transcribing     = Color(hex: 0xD4A54B)
    static let success          = Color(hex: 0x6BAF7B)

    // MARK: - Typography (SF Rounded for fun, friendly feel)

    static func title1() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title2() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func title3() -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 15, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 14, weight: .regular) }
    static func callout() -> Font { .system(size: 13, weight: .regular) }
    static func caption() -> Font { .system(size: 12, weight: .regular) }
    static func captionMedium() -> Font { .system(size: 12, weight: .medium) }

    // MARK: - Spacing (4pt grid)

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32

    // MARK: - Corner radii (friendlier, rounder)

    static let cornerSmall: CGFloat = 10
    static let cornerMedium: CGFloat = 14
    static let cornerLarge: CGFloat = 18
    static let cornerXL: CGFloat = 22

    // MARK: - Animations (bouncy, playful springs)

    static let springSnappy = Animation.spring(duration: 0.3, bounce: 0.2)
    static let springSmooth = Animation.spring(duration: 0.4, bounce: 0.15)
    static let springGentle = Animation.spring(duration: 0.55, bounce: 0.1)
}

// MARK: - Color Helpers

extension Color {
    init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    static func adaptive(dark: Int, light: Int) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255.0,
                green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                blue: CGFloat(hex & 0xFF) / 255.0,
                alpha: 1.0
            )
        })
    }

    static func adaptiveAlpha(dark: NSColor, darkAlpha: CGFloat, light: NSColor, lightAlpha: CGFloat) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? dark.withAlphaComponent(darkAlpha)
                : light.withAlphaComponent(lightAlpha)
        })
    }
}
