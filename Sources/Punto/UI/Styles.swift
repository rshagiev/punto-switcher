import AppKit

/// Centralized styling constants for the application
enum Styles {

    // MARK: - Colors

    static var primaryTextColor: NSColor {
        return .labelColor
    }

    static var secondaryTextColor: NSColor {
        return .secondaryLabelColor
    }

    static var tertiaryTextColor: NSColor {
        return .tertiaryLabelColor
    }

    static var accentColor: NSColor {
        return .controlAccentColor
    }

    static var borderColor: NSColor {
        return NSColor.separatorColor
    }

    static var inputBackgroundColor: NSColor {
        return NSColor.controlBackgroundColor
    }

    static var inputHoverColor: NSColor {
        return NSColor.unemphasizedSelectedContentBackgroundColor
    }

    // MARK: - Fonts

    static var sectionHeaderFont: NSFont {
        return NSFont.systemFont(ofSize: 11, weight: .semibold)
    }

    static var bodyFont: NSFont {
        return NSFont.systemFont(ofSize: 13)
    }

    static var captionFont: NSFont {
        return NSFont.systemFont(ofSize: 11)
    }

    static var hotkeyFont: NSFont {
        return NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    }

    // MARK: - Dimensions

    static let windowPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 8
    static let boxPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 8
}
