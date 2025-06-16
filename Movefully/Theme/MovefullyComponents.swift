import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#endif

// MARK: - Standardized Movefully UI Components
// This file contains all reusable UI components that ensure design consistency across the app

// MARK: - Search Field Component
struct MovefullySearchField: View {
    let placeholder: String
    @Binding var text: String
    let onTextChange: ((String) -> Void)?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(placeholder: String, text: Binding<String>, onTextChange: ((String) -> Void)? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            Image(systemName: "magnifyingglass")
                .font(MovefullyTheme.Typography.buttonSmall)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .accentColor(MovefullyTheme.Colors.primaryTeal)
                .onChange(of: text) { newValue in
                    onTextChange?(newValue)
                }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingL)
        .padding(.vertical, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                .stroke(MovefullyTheme.Colors.primaryTeal.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 6, x: 0, y: 3)
    }
}

// MARK: - Pill Component
struct MovefullyPill: View {
    let title: String
    let isSelected: Bool
    let style: PillStyle
    let action: () -> Void
    
    enum PillStyle {
        case category    // For category filters - larger
        case status      // For status badges - smaller
        case filter      // For general filters - medium
        case tag         // For tags - compact
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(fontForStyle)
                .foregroundColor(isSelected ? .white : MovefullyTheme.Colors.primaryTeal)
                .padding(.horizontal, horizontalPaddingForStyle)
                .padding(.vertical, verticalPaddingForStyle)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: [MovefullyTheme.Colors.primaryTeal.opacity(0.15), MovefullyTheme.Colors.primaryTeal.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadiusForStyle))
                .shadow(
                    color: isSelected ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) : MovefullyTheme.Effects.cardShadow,
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: isSelected ? 3 : 2
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var fontForStyle: Font {
        switch style {
        case .category: return MovefullyTheme.Typography.buttonMedium
        case .status: return MovefullyTheme.Typography.footnote
        case .filter: return MovefullyTheme.Typography.buttonSmall
        case .tag: return MovefullyTheme.Typography.caption
        }
    }
    
    private var horizontalPaddingForStyle: CGFloat {
        switch style {
        case .category: return MovefullyTheme.Layout.paddingL
        case .status: return MovefullyTheme.Layout.paddingS
        case .filter: return MovefullyTheme.Layout.paddingM
        case .tag: return MovefullyTheme.Layout.paddingS
        }
    }
    
    private var verticalPaddingForStyle: CGFloat {
        switch style {
        case .category: return MovefullyTheme.Layout.paddingM
        case .status: return MovefullyTheme.Layout.paddingXS
        case .filter: return MovefullyTheme.Layout.paddingS
        case .tag: return MovefullyTheme.Layout.paddingXS
        }
    }
    
    private var cornerRadiusForStyle: CGFloat {
        switch style {
        case .category: return MovefullyTheme.Layout.cornerRadiusL
        case .status: return MovefullyTheme.Layout.cornerRadiusXL
        case .filter: return MovefullyTheme.Layout.cornerRadiusM
        case .tag: return MovefullyTheme.Layout.cornerRadiusS
        }
    }
}

// MARK: - Status Badge Component
struct MovefullyStatusBadge: View {
    let text: String
    let color: Color
    let showDot: Bool
    
    init(text: String, color: Color, showDot: Bool = true) {
        self.text = text
        self.color = color
        self.showDot = showDot
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingXS) {
            if showDot {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            
            Text(text)
                .font(MovefullyTheme.Typography.footnote)
                .foregroundColor(color)
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingS)
        .padding(.vertical, MovefullyTheme.Layout.paddingXS)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Page Header Component
struct MovefullyPageHeader: View {
    let title: String
    let subtitle: String
    let actionButton: ActionButton?
    
    struct ActionButton {
        let title: String
        let icon: String
        let action: () -> Void
    }
    
    init(title: String, subtitle: String, actionButton: ActionButton? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionButton = actionButton
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingL) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
                Text(title)
                    .font(MovefullyTheme.Typography.title1)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MovefullyTheme.Typography.callout)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if let button = actionButton {
                Button(action: button.action) {
                    HStack(spacing: MovefullyTheme.Layout.paddingS) {
                        Image(systemName: button.icon)
                            .font(MovefullyTheme.Typography.buttonSmall)
                            .foregroundColor(.white)
                        Text(button.title)
                            .font(MovefullyTheme.Typography.buttonSmall)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingL)
                    .padding(.vertical, MovefullyTheme.Layout.paddingM)
                    .background(
                        LinearGradient(
                            colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                    .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
}

// MARK: - Card Component
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

// MARK: - Filter Pills Row Component
struct MovefullyFilterPillsRow<FilterType: Hashable>: View {
    let filters: [FilterType]
    let selectedFilter: FilterType
    let filterTitle: (FilterType) -> String
    let onFilterSelected: (FilterType) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                ForEach(filters, id: \.self) { filter in
                    MovefullyPill(
                        title: filterTitle(filter),
                        isSelected: selectedFilter == filter,
                        style: .category
                    ) {
                        onFilterSelected(filter)
                    }
                }
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
        }
    }
}

// MARK: - Empty State Component
struct MovefullyEmptyState: View {
    let icon: String
    let title: String
    let description: String
    let actionButton: ActionButton?
    
    struct ActionButton {
        let title: String
        let action: () -> Void
    }
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            Spacer(minLength: 24)
            
            Image(systemName: icon)
                .font(MovefullyTheme.Typography.largeTitle)
                .foregroundColor(MovefullyTheme.Colors.primaryTeal.opacity(0.6))
            
            VStack(spacing: MovefullyTheme.Layout.paddingM) {
                Text(title)
                    .font(MovefullyTheme.Typography.title2)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(MovefullyTheme.Typography.body)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
            
            if let button = actionButton {
                Button(button.title) {
                    button.action()
                }
                .font(MovefullyTheme.Typography.buttonMedium)
                .foregroundColor(.white)
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.vertical, MovefullyTheme.Layout.paddingL)
                .background(
                    LinearGradient(
                        colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
                .shadow(color: MovefullyTheme.Colors.primaryTeal.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading State Component
struct MovefullyLoadingState: View {
    let message: String
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            Spacer(minLength: 200)
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(MovefullyTheme.Colors.primaryTeal)
            
            Text(message)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textSecondary)
            
            Spacer(minLength: 200)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Form Field Component
struct MovefullyFormField<Content: View>: View {
    let title: String
    let subtitle: String?
    let isRequired: Bool
    let content: Content
    
    init(title: String, subtitle: String? = nil, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingS) {
            HStack {
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(MovefullyTheme.Colors.warmOrange)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(MovefullyTheme.Typography.caption)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
            }
            
            content
        }
    }
}

// MARK: - Text Field Component
struct MovefullyTextField: View {
    let placeholder: String
    @Binding var text: String
    let onTextChange: ((String) -> Void)?
    let icon: String?
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    let disableAutocorrection: Bool
    let maxCharacters: Int?
    
    init(
        placeholder: String,
        text: Binding<String>,
        onTextChange: ((String) -> Void)? = nil,
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        disableAutocorrection: Bool = false,
        maxCharacters: Int? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.onTextChange = onTextChange
        self.icon = icon
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.disableAutocorrection = disableAutocorrection
        self.maxCharacters = maxCharacters
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .frame(width: 20)
            }
            
            TextField(placeholder, text: $text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .accentColor(MovefullyTheme.Colors.primaryTeal)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(disableAutocorrection)
                .onChange(of: text) { newValue in
                    if let maxCharacters = maxCharacters, newValue.count > maxCharacters {
                        text = String(newValue.prefix(maxCharacters))
                    } else {
                        onTextChange?(newValue)
                    }
                }
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
        )
    }
}

// MARK: - Multiline Text Field Component
struct MovefullyTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let minLines: Int
    let maxLines: Int
    let onTextChange: ((String) -> Void)?
    let maxCharacters: Int?
    
    init(
        placeholder: String,
        text: Binding<String>,
        minLines: Int = 3,
        maxLines: Int = 6,
        onTextChange: ((String) -> Void)? = nil,
        maxCharacters: Int? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.minLines = minLines
        self.maxLines = maxLines
        self.onTextChange = onTextChange
        self.maxCharacters = maxCharacters
    }
    
    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(MovefullyTheme.Typography.body)
            .foregroundColor(MovefullyTheme.Colors.textPrimary)
            .accentColor(MovefullyTheme.Colors.primaryTeal)
            .lineLimit(minLines...maxLines)
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
            )
            .onChange(of: text) { newValue in
                if let maxCharacters = maxCharacters, newValue.count > maxCharacters {
                    text = String(newValue.prefix(maxCharacters))
                } else {
                    onTextChange?(newValue)
                }
            }
    }
}

// MARK: - Secure Field Component
struct MovefullySecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let onTextChange: ((String) -> Void)?
    
    init(
        placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(MovefullyTheme.Colors.textSecondary)
                    .frame(width: 20)
            }
            
            SecureField(placeholder, text: $text)
                .font(MovefullyTheme.Typography.body)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .accentColor(MovefullyTheme.Colors.primaryTeal)
                .onChange(of: text) { newValue in
                    onTextChange?(newValue)
                }
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                .stroke(MovefullyTheme.Colors.divider, lineWidth: 1)
        )
    }
}

// MARK: - Toggle Field Component
struct MovefullyToggleField: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(MovefullyTheme.Colors.primaryTeal)
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
    }
}

// MARK: - Action Row Component
struct MovefullyActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    let showChevron: Bool
    
    init(title: String, icon: String, showChevron: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MovefullyTheme.Layout.paddingM) {
                Image(systemName: icon)
                    .font(MovefullyTheme.Typography.buttonSmall)
                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                    .frame(width: 24)
                
                Text(title)
                    .font(MovefullyTheme.Typography.bodyMedium)
                    .foregroundColor(MovefullyTheme.Colors.textPrimary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(MovefullyTheme.Typography.caption)
                        .foregroundColor(MovefullyTheme.Colors.textSecondary)
                }
            }
            .padding(MovefullyTheme.Layout.paddingM)
            .background(MovefullyTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Alert Banner Component
struct MovefullyAlertBanner: View {
    let title: String
    let message: String
    let type: AlertType
    let actionButton: ActionButton?
    
    enum AlertType {
        case info
        case warning
        case error
        case success
        
        var color: Color {
            switch self {
            case .info: return MovefullyTheme.Colors.gentleBlue
            case .warning: return MovefullyTheme.Colors.warmOrange
            case .error: return Color.red
            case .success: return MovefullyTheme.Colors.softGreen
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    struct ActionButton {
        let title: String
        let action: () -> Void
    }
    
    var body: some View {
        HStack(spacing: MovefullyTheme.Layout.paddingM) {
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(MovefullyTheme.Typography.buttonSmall)
                
                VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingXS) {
                    Text(title)
                        .font(MovefullyTheme.Typography.bodyMedium)
                        .foregroundColor(type.color)
                    
                    Text(message)
                        .font(MovefullyTheme.Typography.body)
                        .foregroundColor(type.color)
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            if let button = actionButton {
                Button(button.title) {
                    button.action()
                }
                .font(MovefullyTheme.Typography.buttonSmall)
                .foregroundColor(type.color)
                .padding(.horizontal, MovefullyTheme.Layout.paddingM)
                .padding(.vertical, MovefullyTheme.Layout.paddingS)
                .background(type.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
            }
        }
        .padding(MovefullyTheme.Layout.paddingL)
        .background(type.color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL))
        .overlay(
            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusL)
                .stroke(type.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Character Count Component
struct MovefullyCharacterCount: View {
    let currentCount: Int
    let maxCount: Int
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(currentCount)/\(maxCount)")
                .font(MovefullyTheme.Typography.caption)
                .foregroundColor(currentCount > maxCount ? MovefullyTheme.Colors.warmOrange : MovefullyTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Navigation Header Component
struct MovefullyNavigationHeader: View {
    let title: String
    let showTrailingButton: Bool
    let trailingButtonIcon: String
    let trailingButtonAction: () -> Void
    
    init(
        title: String,
        showTrailingButton: Bool = false,
        trailingButtonIcon: String = "person.crop.circle",
        trailingButtonAction: @escaping () -> Void = {}
    ) {
        self.title = title
        self.showTrailingButton = showTrailingButton
        self.trailingButtonIcon = trailingButtonIcon
        self.trailingButtonAction = trailingButtonAction
    }
    
    var body: some View {
        ZStack {
            // This creates the same spacing as a large navigation title
            VStack {
                if showTrailingButton {
                    HStack {
                        Spacer()
                        Button(action: trailingButtonAction) {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: trailingButtonIcon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                        }
                        .accessibilityLabel("Profile")
                        .padding(.trailing, MovefullyTheme.Layout.paddingXL)
                        .padding(.top, 8)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Standard Navigation System

/// Standard navigation wrapper that provides consistent professional navigation across all main views
/// Features:
/// - Large navigation titles that collapse on scroll
/// - Standardized toolbar button styling
/// - Support for multiple trailing action buttons
/// - Consistent background and padding
/// - Professional iOS navigation behavior
struct MovefullyStandardNavigation<Content: View>: View {
    let title: String
    let showProfileButton: Bool
    let profileAction: (() -> Void)?
    let trailingButtons: [ToolbarButton]
    let leadingButton: ToolbarButton?
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let content: Content
    
    struct ToolbarButton {
        let icon: String
        let action: () -> Void
        let accessibilityLabel: String?
        
        init(icon: String, action: @escaping () -> Void, accessibilityLabel: String? = nil) {
            self.icon = icon
            self.action = action
            self.accessibilityLabel = accessibilityLabel
        }
    }
    
    init(
        title: String,
        showProfileButton: Bool = false,
        profileAction: (() -> Void)? = nil,
        trailingButtons: [ToolbarButton] = [],
        trailingButton: ToolbarButton? = nil, // Keep for backward compatibility
        leadingButton: ToolbarButton? = nil,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large, // Default to large
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showProfileButton = showProfileButton
        self.profileAction = profileAction
        // Combine new and old trailing button parameters for backward compatibility
        var buttons = trailingButtons
        if let singleButton = trailingButton {
            buttons.append(singleButton)
        }
        self.trailingButtons = buttons
        self.leadingButton = leadingButton
        self.titleDisplayMode = titleDisplayMode
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                    content
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.top, MovefullyTheme.Layout.paddingL) // Add proper top padding above search field
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(titleDisplayMode)
            .navigationBarHidden(false)
            .toolbar {
                // Leading button
                if let leadingButton = leadingButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: leadingButton.action) {
                            Image(systemName: leadingButton.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                        }
                        .accessibilityLabel(leadingButton.accessibilityLabel ?? "")
                    }
                }
                
                // Trailing buttons - support multiple buttons
                if showProfileButton, let profileAction = profileAction {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: profileAction) {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                        }
                        .accessibilityLabel("Profile")
                    }
                } else if !trailingButtons.isEmpty {
                    // Multiple trailing buttons in a single ToolbarItem
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(Array(trailingButtons.enumerated()), id: \.offset) { index, button in
                                Button(action: button.action) {
                                    Image(systemName: button.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                }
                                .accessibilityLabel(button.accessibilityLabel ?? "")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Inline Navigation (Title + Buttons on Same Line)
/// Navigation with title and buttons horizontally aligned on the same line
/// Perfect for management views where actions should be directly next to the title
struct MovefullyInlineNavigation<Content: View>: View {
    let title: String
    let trailingButtons: [ToolbarButton]
    let content: Content
    
    struct ToolbarButton {
        let icon: String
        let action: () -> Void
        let accessibilityLabel: String?
        
        init(icon: String, action: @escaping () -> Void, accessibilityLabel: String? = nil) {
            self.icon = icon
            self.action = action
            self.accessibilityLabel = accessibilityLabel
        }
    }
    
    init(
        title: String,
        trailingButtons: [ToolbarButton] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailingButtons = trailingButtons
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom inline header with title and buttons on same line
                HStack(alignment: .center, spacing: MovefullyTheme.Layout.paddingL) {
                    Text(title)
                        .font(MovefullyTheme.Typography.title1)
                        .foregroundColor(MovefullyTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Action buttons horizontally aligned with title
                    if !trailingButtons.isEmpty {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(Array(trailingButtons.enumerated()), id: \.offset) { index, button in
                                Button(action: button.action) {
                                    Image(systemName: button.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                }
                                .accessibilityLabel(button.accessibilityLabel ?? "")
                            }
                        }
                    }
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                .padding(.top, MovefullyTheme.Layout.paddingL)
                .padding(.bottom, MovefullyTheme.Layout.paddingM)
                
                // Content
                ScrollView {
                    VStack(spacing: MovefullyTheme.Layout.paddingXL) {
                        content
                    }
                    .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
                    .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
                }
                .background(MovefullyTheme.Colors.backgroundPrimary)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Standard Navigation for Trainer Views
/// Trainer-specific navigation wrapper with consistent trainer UI patterns
struct MovefullyTrainerNavigation<Content: View>: View {
    let title: String
    let showProfileButton: Bool
    let profileAction: (() -> Void)?
    let trailingButtons: [MovefullyStandardNavigation<Content>.ToolbarButton]
    let useInlineLayout: Bool
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let content: Content
    
    init(
        title: String,
        showProfileButton: Bool = false,
        profileAction: (() -> Void)? = nil,
        trailingButtons: [MovefullyStandardNavigation<Content>.ToolbarButton] = [],
        trailingButton: MovefullyStandardNavigation<Content>.ToolbarButton? = nil, // Keep for backward compatibility
        useInlineLayout: Bool = false,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large, // Default to large
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showProfileButton = showProfileButton
        self.profileAction = profileAction
        // Combine new and old trailing button parameters for backward compatibility
        var buttons = trailingButtons
        if let singleButton = trailingButton {
            buttons.append(singleButton)
        }
        self.trailingButtons = buttons
        self.useInlineLayout = useInlineLayout
        self.titleDisplayMode = titleDisplayMode
        self.content = content()
    }
    
    var body: some View {
        if useInlineLayout {
            // Use inline navigation (title and buttons on same line)
            let inlineButtons = trailingButtons.map { button in
                MovefullyInlineNavigation<Content>.ToolbarButton(
                    icon: button.icon,
                    action: button.action,
                    accessibilityLabel: button.accessibilityLabel
                )
            }
            
            MovefullyInlineNavigation(
                title: title,
                trailingButtons: inlineButtons
            ) {
                content
            }
        } else {
            // Use trainer-optimized navigation with tighter spacing
            MovefullyTrainerOptimizedNavigation(
                title: title,
                showProfileButton: showProfileButton,
                profileAction: profileAction,
                trailingButtons: trailingButtons,
                titleDisplayMode: titleDisplayMode
            ) {
                content
            }
        }
    }
}

// MARK: - Trainer-Optimized Navigation (Internal Component)
/// Internal navigation component optimized specifically for trainer views with tighter spacing
private struct MovefullyTrainerOptimizedNavigation<Content: View>: View {
    let title: String
    let showProfileButton: Bool
    let profileAction: (() -> Void)?
    let trailingButtons: [MovefullyStandardNavigation<Content>.ToolbarButton]
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let content: Content
    
    init(
        title: String,
        showProfileButton: Bool = false,
        profileAction: (() -> Void)? = nil,
        trailingButtons: [MovefullyStandardNavigation<Content>.ToolbarButton] = [],
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showProfileButton = showProfileButton
        self.profileAction = profileAction
        self.trailingButtons = trailingButtons
        self.titleDisplayMode = titleDisplayMode
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MovefullyTheme.Layout.paddingL) { // Reduced from paddingXL (32pt) to paddingL (24pt)
                    content
                }
                .padding(.horizontal, MovefullyTheme.Layout.paddingL) // Reduced from paddingXL (32pt) to paddingL (24pt)
                .padding(.top, MovefullyTheme.Layout.paddingL) // Add proper top padding above search field
                .padding(.bottom, MovefullyTheme.Layout.paddingXXL)
            }
            .background(MovefullyTheme.Colors.backgroundPrimary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(titleDisplayMode)
            .navigationBarHidden(false)
            .toolbar {
                // Trailing buttons - support multiple buttons
                if showProfileButton, let profileAction = profileAction {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: profileAction) {
                            ZStack {
                                Circle()
                                    .fill(MovefullyTheme.Colors.primaryTeal.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                            }
                        }
                        .accessibilityLabel("Profile")
                    }
                } else if !trailingButtons.isEmpty {
                    // Multiple trailing buttons in a single ToolbarItem
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: MovefullyTheme.Layout.paddingM) {
                            ForEach(Array(trailingButtons.enumerated()), id: \.offset) { index, button in
                                Button(action: button.action) {
                                    Image(systemName: button.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(MovefullyTheme.Colors.primaryTeal)
                                }
                                .accessibilityLabel(button.accessibilityLabel ?? "")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Standard Navigation for Client Views
/// Client-specific navigation wrapper with consistent client UI patterns
struct MovefullyClientNavigation<Content: View>: View {
    let title: String
    let showProfileButton: Bool
    let profileAction: (() -> Void)?
    let trailingButton: MovefullyStandardNavigation<Content>.ToolbarButton?
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let content: Content
    
    init(
        title: String,
        showProfileButton: Bool = true,
        profileAction: (() -> Void)? = nil,
        trailingButton: MovefullyStandardNavigation<Content>.ToolbarButton? = nil,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large, // Default to large for Today, Progress, Resources
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showProfileButton = showProfileButton
        self.profileAction = profileAction
        self.trailingButton = trailingButton
        self.titleDisplayMode = titleDisplayMode
        self.content = content()
    }
    
    var body: some View {
        MovefullyStandardNavigation(
            title: title,
            showProfileButton: showProfileButton,
            profileAction: profileAction,
            trailingButton: trailingButton,
            titleDisplayMode: titleDisplayMode
        ) {
            content
        }
    }
}

// MARK: - Theme Picker Component
struct MovefullyThemePicker: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: MovefullyTheme.Layout.paddingM) {
            Text("Appearance")
                .font(MovefullyTheme.Typography.bodyMedium)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
            
            HStack(spacing: MovefullyTheme.Layout.paddingS) {
                ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { theme in
                    Button(action: {
                        themeManager.setTheme(theme)
                    }) {
                        VStack(spacing: MovefullyTheme.Layout.paddingS) {
                            Image(systemName: theme.systemImage)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(themeManager.currentTheme == theme ? .white : MovefullyTheme.Colors.primaryTeal)
                            
                            Text(theme.displayName)
                                .font(MovefullyTheme.Typography.caption)
                                .foregroundColor(themeManager.currentTheme == theme ? .white : MovefullyTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MovefullyTheme.Layout.paddingM)
                        .background(
                            Group {
                                if themeManager.currentTheme == theme {
                                    LinearGradient(
                                        colors: [MovefullyTheme.Colors.primaryTeal, MovefullyTheme.Colors.primaryTeal.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    MovefullyTheme.Colors.cardBackground
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                                .stroke(
                                    themeManager.currentTheme == theme 
                                        ? Color.clear 
                                        : MovefullyTheme.Colors.divider, 
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: themeManager.currentTheme == theme 
                                ? MovefullyTheme.Colors.primaryTeal.opacity(0.3) 
                                : MovefullyTheme.Effects.cardShadow,
                            radius: themeManager.currentTheme == theme ? 6 : 2,
                            x: 0,
                            y: themeManager.currentTheme == theme ? 3 : 1
                        )
                        .scaleEffect(themeManager.currentTheme == theme ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: themeManager.currentTheme)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM))
        .onReceive(themeManager.$isDarkMode) { _ in
            // Force UI update when theme changes
        }
        .onReceive(themeManager.$currentTheme) { _ in
            // Force UI update when theme mode changes
        }
    }
}

// MARK: - Icon Selector Component
struct MovefullyIconSelector: View {
    @Binding var selectedIcon: String
    
    private let availableIcons = [
        "dumbbell.fill", "heart.fill", "flame.fill", "leaf.fill",
        "bolt.fill", "sun.max.fill", "star.fill", "target",
        "timer", "moon.fill", "drop.fill", "wind"
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: MovefullyTheme.Layout.paddingM) {
            ForEach(availableIcons, id: \.self) { icon in
                iconButton(for: icon)
            }
        }
    }
    
    private func iconButton(for icon: String) -> some View {
        Button(action: {
            selectedIcon = icon
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .fill(selectedIcon == icon ? MovefullyTheme.Colors.primaryTeal.opacity(0.15) : MovefullyTheme.Colors.backgroundSecondary)
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedIcon == icon ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.textSecondary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusM)
                    .stroke(selectedIcon == icon ? MovefullyTheme.Colors.primaryTeal : MovefullyTheme.Colors.divider.opacity(0.5), lineWidth: selectedIcon == icon ? 2 : 1)
            )
            .scaleEffect(selectedIcon == icon ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: selectedIcon)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Smart Alert Card Component
struct SmartAlertCard: View {
    let alert: SmartAlert
    let onDismiss: () -> Void
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        HStack(alignment: .top, spacing: MovefullyTheme.Layout.paddingS) {
            // Minimal alert indicator
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(MovefullyTheme.Colors.warmOrange)
                .padding(.top, 2) // Align with first line of text
            
            // Alert text - allow wrapping to 2 lines
            Text(alert.title)
                .font(MovefullyTheme.Typography.callout)
                .foregroundColor(MovefullyTheme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 8)
        }
        .padding(.vertical, MovefullyTheme.Layout.paddingS)
        .padding(.horizontal, MovefullyTheme.Layout.paddingM)
        .background(MovefullyTheme.Colors.warmOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MovefullyTheme.Layout.cornerRadiusS))
        .offset(x: dragOffset.width)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Only allow horizontal dragging to the left
                    if gesture.translation.width < 0 {
                        dragOffset = gesture.translation
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.width < -100 { // Swipe left threshold
                        // Animate dismiss
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragOffset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
                        }
                        // Call dismiss after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
}