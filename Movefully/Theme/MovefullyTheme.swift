import SwiftUI

// MARK: - Movefully Design Language
// Warm, supportive, non-toxic design focused on movement over metrics

struct MovefullyTheme {
    
    // MARK: - Direct Access Properties (for backward compatibility)
    static let primaryTeal = Colors.primaryTeal
    static let warmOrange = Color(red: 0.96, green: 0.64, blue: 0.38) // #F4A261
    static let softGreen = Color(red: 0.44, green: 0.76, blue: 0.55) // #70C18C
    static let gentleBlue = Color(red: 0.44, green: 0.69, blue: 0.99) // #6FB1FC
    static let lavender = Color(red: 0.78, green: 0.60, blue: 0.89) // #C69AE3
    static let mediumGray = Color(red: 0.69, green: 0.69, blue: 0.69) // #B0B0B0
    static let backgroundGray = Color(red: 0.98, green: 0.98, blue: 0.98) // #FAFAFA
    static let cardWhite = Color.white
    static let headingText = Color(red: 0.20, green: 0.20, blue: 0.20) // #333333
    static let bodyText = Color(red: 0.40, green: 0.40, blue: 0.40) // #666666
    static let secondaryText = Color(red: 0.60, green: 0.60, blue: 0.60) // #999999
    static let softShadow = Color.black.opacity(0.06) // For subtle shadows
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Brand Color - Soft Aqua/Teal (#56C2C6)
        static let primaryTeal = Color(red: 0.337, green: 0.761, blue: 0.776) // #56C2C6
        
        // Accent Colors - Wellness focused palette
        static let warmOrange = Color(red: 0.957, green: 0.635, blue: 0.381) // #F4A261 - alerts/needs attention
        static let softGreen = Color(red: 0.439, green: 0.757, blue: 0.549) // #70C18C - active states
        static let gentleBlue = Color(red: 0.435, green: 0.694, blue: 0.988) // #6FB1FC - new/info states
        static let lavender = Color(red: 0.776, green: 0.604, blue: 0.890) // #C69AE3 - pending invite
        static let mediumGray = Color(red: 0.690, green: 0.690, blue: 0.690) // #B0B0B0 - paused states
        
        // Secondary Accent Color - Keeping the peach for warmth
        static let secondaryPeach = Color(red: 0.996, green: 0.784, blue: 0.604) // #FEC89A
        
        // Background Colors - Off-white for calm feeling
        static let backgroundPrimary = Color(red: 0.980, green: 0.980, blue: 0.980) // #FAFAFA - main background
        static let backgroundSecondary = Color(red: 0.976, green: 0.976, blue: 0.976) // #F9F9F9 - secondary areas
        
        // Text Colors - Strong contrast for readability
        static let textPrimary = Color(red: 0.200, green: 0.200, blue: 0.200) // #333333 - headings
        static let textSecondary = Color(red: 0.310, green: 0.310, blue: 0.310) // #4F4F4F - body text
        static let textTertiary = Color(red: 0.620, green: 0.620, blue: 0.620) // #9E9E9E - muted text
        
        // Interactive Elements
        static let buttonPrimary = primaryTeal
        static let buttonSecondary = secondaryPeach
        
        // Subtle UI Elements
        static let divider = Color(red: 0.925, green: 0.925, blue: 0.925) // #ECECEC
        static let cardBackground = Color.white // Pure white cards for contrast
        static let inactive = mediumGray
        
        // Semantic colors using our palette
        static let success = softGreen
        static let warning = warmOrange
        static let info = gentleBlue
        static let accent = lavender
    }
    
    // MARK: - Typography
    struct Typography {
        // Main Titles (22-24pt)
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .bold, design: .rounded)        // Main page titles
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)   // Secondary titles
        static let title3 = Font.system(size: 18, weight: .medium, design: .rounded)     // Section headers
        
        // Body text (15-17pt)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)      // Standard body text
        static let bodyMedium = Font.system(size: 16, weight: .medium, design: .rounded) // Emphasized body
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded) // Large body text
        
        // Supporting text (13-14pt)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)   // Callout text
        static let caption = Font.system(size: 13, weight: .regular, design: .rounded)   // Captions/metadata
        static let footnote = Font.system(size: 12, weight: .regular, design: .rounded)  // Fine print
        
        // Button text
        static let buttonLarge = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let buttonMedium = Font.system(size: 16, weight: .medium, design: .rounded)
        static let buttonSmall = Font.system(size: 14, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing & Layout
    struct Layout {
        static let paddingXS: CGFloat = 4
        static let paddingS: CGFloat = 8
        static let paddingM: CGFloat = 16
        static let paddingL: CGFloat = 24
        static let paddingXL: CGFloat = 32
        static let paddingXXL: CGFloat = 40
        
        // Corner radius
        static let cornerRadiusXS: CGFloat = 6
        static let cornerRadiusS: CGFloat = 8
        static let cornerRadiusM: CGFloat = 12
        static let cornerRadiusL: CGFloat = 16
        static let cornerRadiusXL: CGFloat = 20
        
        // Button heights
        static let buttonHeightS: CGFloat = 40
        static let buttonHeightM: CGFloat = 48
        static let buttonHeightL: CGFloat = 56
    }
    
    // MARK: - Shadows & Effects
    struct Effects {
        static let cardShadow = Color.black.opacity(0.05)
        static let buttonShadow = Color.black.opacity(0.1)
    }
}

// MARK: - Custom Button Styles
struct MovefullyButtonStyle: ButtonStyle {
    let type: ButtonType
    
    enum ButtonType {
        case primary
        case secondary
        case tertiary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MovefullyTheme.Typography.buttonMedium)
            .frame(maxWidth: .infinity)
            .frame(height: MovefullyTheme.Layout.buttonHeightM)
            .background(backgroundFor(type: type, isPressed: configuration.isPressed))
            .foregroundColor(foregroundFor(type: type))
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: MovefullyTheme.Effects.buttonShadow, radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundFor(type: ButtonType, isPressed: Bool) -> Color {
        let opacity = isPressed ? 0.8 : 1.0
        switch type {
        case .primary:
            return MovefullyTheme.Colors.primaryTeal.opacity(opacity)
        case .secondary:
            return MovefullyTheme.Colors.secondaryPeach.opacity(opacity)
        case .tertiary:
            return MovefullyTheme.Colors.cardBackground.opacity(opacity)
        }
    }
    
    private func foregroundFor(type: ButtonType) -> Color {
        switch type {
        case .primary, .secondary:
            return .white
        case .tertiary:
            return MovefullyTheme.Colors.textPrimary
        }
    }
}

// MARK: - Custom Text Field Style
struct MovefullyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(MovefullyTheme.Typography.body)
            .foregroundColor(MovefullyTheme.Colors.textPrimary)
            .accentColor(MovefullyTheme.Colors.primaryTeal)
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
            )
    }
}

// MARK: - Search Field Style  
struct MovefullySearchFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(MovefullyTheme.Typography.body)
            .foregroundColor(MovefullyTheme.Colors.textPrimary)
            .accentColor(MovefullyTheme.Colors.primaryTeal)
            .padding(.horizontal, MovefullyTheme.Layout.paddingL)
            .padding(.vertical, MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                    .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 6, x: 0, y: 3)
    }
}

// MARK: - Custom Card Style
struct MovefullyCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(MovefullyTheme.Layout.paddingL)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
            .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Extensions for Theme
extension View {
    func movefullyBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [
                    MovefullyTheme.Colors.backgroundPrimary,
                    MovefullyTheme.Colors.backgroundSecondary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    func movefullyButtonStyle(_ type: MovefullyButtonStyle.ButtonType = .primary) -> some View {
        self.buttonStyle(MovefullyButtonStyle(type: type))
    }
    
    func movefullyTextFieldStyle() -> some View {
        self.textFieldStyle(MovefullyTextFieldStyle())
    }
    
    func movefullySearchFieldStyle() -> some View {
        self.textFieldStyle(MovefullySearchFieldStyle())
    }
    
    func movefullyShadow() -> some View {
        self.shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
} 