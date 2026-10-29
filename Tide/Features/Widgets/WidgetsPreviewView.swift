import SwiftUI

/// 付録A の Widgets 画面。L1 では空画面。
struct WidgetsPreviewView: View {
    var body: some View {
        ScreenContainer {
            EmptyView()
        }
    }
}

#Preview {
    WidgetsPreviewView()
        .previewEnvironment()
}
