import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeMode = .system
    @Published var isDarkMode: Bool = false
    
    enum ThemeMode: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        
        var displayName: String {
            return self.rawValue
        }
        
        var systemImage: String {
            switch self {
            case .light: return "sun.max"
            case .dark: return "moon"
            case .system: return "gear"
            }
        }
    }
    
    static let shared = ThemeManager()
    
    private init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "themeMode"),
           let theme = ThemeMode(rawValue: savedTheme) {
            currentTheme = theme
        }
        updateTheme()
    }
    
    func setTheme(_ theme: ThemeMode) {
        DispatchQueue.main.async {
            self.currentTheme = theme
            UserDefaults.standard.set(theme.rawValue, forKey: "themeMode")
            self.updateTheme()
            // Force navigation bar update immediately after theme change
            self.updateNavigationBarAppearance()
        }
    }
    
    private func updateTheme() {
        DispatchQueue.main.async {
            switch self.currentTheme {
            case .light:
                self.isDarkMode = false
            case .dark:
                self.isDarkMode = true
            case .system:
                #if os(iOS)
                self.isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
                #else
                self.isDarkMode = false // Default to light mode on non-iOS platforms
                #endif
            }
            
            // Force navigation bar update after theme change
            self.updateNavigationBarAppearance()
            
            // Force a UI update by updating the published property
            self.objectWillChange.send()
        }
    }
    
    func systemThemeChanged() {
        if currentTheme == .system {
            updateTheme()
        }
        updateNavigationBarAppearance()
    }
    
    func updateForColorScheme(_ colorScheme: ColorScheme) {
        if currentTheme == .system {
            isDarkMode = (colorScheme == .dark)
        }
        updateNavigationBarAppearance()
    }
    
    internal func updateNavigationBarAppearance() {
        #if os(iOS)
        DispatchQueue.main.async {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Use explicit colors based on our theme state instead of system colors
            let backgroundColor = self.isDarkMode 
                ? UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1.0) // Dark mode background
                : UIColor(red: 0.980, green: 0.980, blue: 0.980, alpha: 1.0) // Light mode background
            
            let textColor = self.isDarkMode 
                ? UIColor.white // White text in dark mode
                : UIColor(red: 0.200, green: 0.200, blue: 0.200, alpha: 1.0) // Dark text in light mode
            
            appearance.backgroundColor = backgroundColor
            appearance.titleTextAttributes = [.foregroundColor: textColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: textColor]
            
            // Apply to all navigation bar types (for new navigation bars)
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            if #available(iOS 15.0, *) {
                UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
            }
            
            // Update existing navigation bars immediately
            self.updateExistingNavigationBars(with: appearance)
        }
        #endif
    }
    
    #if os(iOS)
    private func updateExistingNavigationBars(with appearance: UINavigationBarAppearance) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        self.updateNavigationBarsInHierarchy(viewController: window.rootViewController, appearance: appearance)
    }
    
    private func updateNavigationBarsInHierarchy(viewController: UIViewController?, appearance: UINavigationBarAppearance) {
        guard let viewController = viewController else { return }
        
        // Update navigation controller if this is one
        if let navController = viewController as? UINavigationController {
            navController.navigationBar.standardAppearance = appearance
            navController.navigationBar.compactAppearance = appearance
            navController.navigationBar.scrollEdgeAppearance = appearance
            if #available(iOS 15.0, *) {
                navController.navigationBar.compactScrollEdgeAppearance = appearance
            }
        }
        
        // Check child view controllers
        for child in viewController.children {
            self.updateNavigationBarsInHierarchy(viewController: child, appearance: appearance)
        }
        
        // Check presented view controllers (modals, sheets, etc.)
        if let presented = viewController.presentedViewController {
            self.updateNavigationBarsInHierarchy(viewController: presented, appearance: appearance)
        }
    }
    
    private func refreshAllNavigationBars(in viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        if let navController = viewController as? UINavigationController {
            navController.navigationBar.setNeedsLayout()
            navController.navigationBar.layoutIfNeeded()
        }
        
        // Recursively check child view controllers
        for child in viewController.children {
            refreshAllNavigationBars(in: child)
        }
        
        // Check presented view controllers
        if let presented = viewController.presentedViewController {
            refreshAllNavigationBars(in: presented)
        }
    }
    #endif
}

// MARK: - Movefully Design Language
// Warm, supportive, non-toxic design focused on movement over metrics

struct MovefullyTheme {
    // MARK: - Direct Access Properties (for backward compatibility)
    static var primaryTeal: Color { Colors.primaryTeal }
    static var warmOrange: Color { Colors.warmOrange }
    static var softGreen: Color { Colors.softGreen }
    static var gentleBlue: Color { Colors.gentleBlue }
    static var lavender: Color { Colors.lavender }
    static var mediumGray: Color { Colors.mediumGray }
    static var backgroundGray: Color { Colors.backgroundPrimary }
    static var cardWhite: Color { Colors.cardBackground }
    static var headingText: Color { Colors.textPrimary }
    static var bodyText: Color { Colors.textSecondary }
    static var secondaryText: Color { Colors.textTertiary }
    static var softShadow: Color { Effects.cardShadow }
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Brand Color - Soft Aqua/Teal (#56C2C6)
        static var primaryTeal: Color {
            // Keep the same for both themes as it's a brand color
            Color(red: 0.337, green: 0.761, blue: 0.776) // #56C2C6
        }
        
        // Primary Teal for backgrounds - optimized for white text contrast
        static var primaryTealBackground: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.287, green: 0.647, blue: 0.660) // Darker in dark mode for better contrast
                : Color(red: 0.287, green: 0.647, blue: 0.660) // Slightly darker in light mode too for accessibility
        }
        
        // Accent Colors - Wellness focused palette
        static var warmOrange: Color {
            // Keep the same for both themes
            Color(red: 0.957, green: 0.635, blue: 0.381) // #F4A261
        }
        
        static var softGreen: Color {
            // Keep the same for both themes
            Color(red: 0.439, green: 0.757, blue: 0.549) // #70C18C
        }
        
        static var gentleBlue: Color {
            // Keep the same for both themes
            Color(red: 0.435, green: 0.694, blue: 0.988) // #6FB1FC
        }
        
        static var lavender: Color {
            // Keep the same for both themes
            Color(red: 0.776, green: 0.604, blue: 0.890) // #C69AE3
        }
        
        static var mediumGray: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.550, green: 0.550, blue: 0.550) // Lighter gray for dark mode
                : Color(red: 0.690, green: 0.690, blue: 0.690) // #B0B0B0
        }
        
        // Secondary Accent Color - Keeping the peach for warmth
        static var secondaryPeach: Color {
            // Keep the same for both themes
            Color(red: 0.996, green: 0.784, blue: 0.604) // #FEC89A
        }
        
        // Background Colors - These are the critical ones for theme switching
        static var backgroundPrimary: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.110, green: 0.110, blue: 0.118) // #1C1C1E - iOS dark background
                : Color(red: 0.980, green: 0.980, blue: 0.980) // #FAFAFA
        }
        
        static var backgroundSecondary: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.141, green: 0.141, blue: 0.153) // #242428 - iOS secondary dark
                : Color(red: 0.976, green: 0.976, blue: 0.976) // #F9F9F9
        }
        
        // Text Colors - Critical for readability
        static var textPrimary: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 1.0, green: 1.0, blue: 1.0) // White text in dark mode
                : Color(red: 0.200, green: 0.200, blue: 0.200) // #333333
        }
        
        static var textSecondary: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.922, green: 0.922, blue: 0.961) // #EBEBF5 - iOS secondary text dark
                : Color(red: 0.310, green: 0.310, blue: 0.310) // #4F4F4F
        }
        
        static var textTertiary: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93 - iOS tertiary text dark
                : Color(red: 0.620, green: 0.620, blue: 0.620) // #9E9E9E
        }
        
        // Interactive Elements
        static var buttonPrimary: Color { primaryTeal }
        static var buttonSecondary: Color { secondaryPeach }
        
        // Subtle UI Elements
        static var divider: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.329, green: 0.329, blue: 0.345) // #545458 - iOS separator dark
                : Color(red: 0.925, green: 0.925, blue: 0.925) // #ECECEC
        }
        
        static var cardBackground: Color {
            ThemeManager.shared.isDarkMode
                ? Color(red: 0.172, green: 0.172, blue: 0.180) // #2C2C2E - iOS grouped background dark
                : Color.white
        }
        
        static var inactive: Color { mediumGray }
        
        // Semantic colors using our palette
        static var success: Color { softGreen }
        static var warning: Color { warmOrange }
        static var info: Color { gentleBlue }
        static var accent: Color { lavender }
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
        static var cardShadow: Color {
            ThemeManager.shared.isDarkMode
                ? Color.black.opacity(0.3) // Stronger shadows in dark mode
                : Color.black.opacity(0.05)
        }
        
        static var buttonShadow: Color {
            ThemeManager.shared.isDarkMode
                ? Color.black.opacity(0.4) // Stronger shadows in dark mode
                : Color.black.opacity(0.1)
        }
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

// MARK: - Custom Text Field Style (DEPRECATED - Use MovefullyTextField component instead)
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

// MARK: - Search Field Style (DEPRECATED - Use MovefullySearchField component instead)
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

// MARK: - Navigation Bar Theme Modifier
struct NavigationBarThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                themeManager.updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.isDarkMode) { _ in
                themeManager.updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.currentTheme) { _ in
                themeManager.updateNavigationBarAppearance()
            }
    }
}

// MARK: - Theme Environment Modifier
struct ThemeEnvironmentModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.currentTheme == .system ? nil : (themeManager.isDarkMode ? .dark : .light))
            .onChange(of: colorScheme) { newColorScheme in
                themeManager.updateForColorScheme(newColorScheme)
            }
            .onChange(of: themeManager.currentTheme) { _ in
                themeManager.updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.isDarkMode) { _ in
                themeManager.updateNavigationBarAppearance()
            }
            .animation(.easeInOut(duration: 0.3), value: themeManager.isDarkMode)
            .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                themeManager.systemThemeChanged()
            }
            #endif
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
    
    // DEPRECATED - Use MovefullyTextField component instead
    func movefullyTextFieldStyle() -> some View {
        self.textFieldStyle(MovefullyTextFieldStyle())
    }
    
    // DEPRECATED - Use MovefullySearchField component instead
    func movefullySearchFieldStyle() -> some View {
        self.textFieldStyle(MovefullySearchFieldStyle())
    }
    
    func movefullyShadow() -> some View {
        self.shadow(color: MovefullyTheme.Effects.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    /// Apply Movefully theme management to the entire app
    /// This modifier should be applied to the root view of your app
    func movefullyThemed() -> some View {
        self.modifier(ThemeEnvironmentModifier())
    }
    
    /// Apply navigation bar theming that responds to theme changes
    /// Use this on views with navigation bars that need theme-responsive appearance
    func movefullyNavigationThemed() -> some View {
        self.modifier(NavigationBarThemeModifier())
    }
} 