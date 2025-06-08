import SwiftUI

// MARK: - Standardized Page Layouts
// This file contains reusable page layout components for consistent structure

// MARK: - Standard Page Layout
struct MovefullyPageLayout<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                content
            }
        }
        .background(
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
}

// MARK: - Standard Page Section
struct MovefullyPageSection<Content: View>: View {
    let content: Content
    let hasTopPadding: Bool
    let hasBottomPadding: Bool
    let hasHorizontalPadding: Bool
    let backgroundColor: Color
    
    init(
        hasTopPadding: Bool = true,
        hasBottomPadding: Bool = true,
        hasHorizontalPadding: Bool = true,
        backgroundColor: Color = MovefullyTheme.Colors.cardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.hasTopPadding = hasTopPadding
        self.hasBottomPadding = hasBottomPadding
        self.hasHorizontalPadding = hasHorizontalPadding
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(spacing: MovefullyTheme.Layout.paddingL) {
            content
        }
        .padding(.top, hasTopPadding ? MovefullyTheme.Layout.paddingL : 0)
        .padding(.bottom, hasBottomPadding ? MovefullyTheme.Layout.paddingL : 0)
        .padding(.horizontal, hasHorizontalPadding ? MovefullyTheme.Layout.paddingXL : 0)
        .background(backgroundColor)
    }
}

// MARK: - Content Section with Divider
struct MovefullyContentSection<Content: View>: View {
    let content: Content
    let showDivider: Bool
    
    init(showDivider: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showDivider = showDivider
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
            
            if showDivider {
                Rectangle()
                    .fill(MovefullyTheme.Colors.divider)
                    .frame(height: 1)
                    .shadow(color: MovefullyTheme.Effects.cardShadow, radius: 1, x: 0, y: 1)
            }
        }
    }
}

// MARK: - Standard List Layout
struct MovefullyListLayout<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let itemView: (Item) -> ItemView
    
    init(
        items: [Item],
        spacing: CGFloat = MovefullyTheme.Layout.paddingL,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.spacing = spacing
        self.itemView = itemView
    }
    
    var body: some View {
        LazyVStack(spacing: spacing) {
            ForEach(items) { item in
                itemView(item)
            }
        }
        .padding(.horizontal, MovefullyTheme.Layout.paddingXL)
        .padding(.vertical, MovefullyTheme.Layout.paddingL)
    }
}

// MARK: - Navigation Page Layout
struct MovefullyNavigationPageLayout<Content: View>: View {
    let content: Content
    let useStackStyle: Bool
    
    init(useStackStyle: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.useStackStyle = useStackStyle
    }
    
    var body: some View {
        NavigationStack {
            content
        }
    }
} 