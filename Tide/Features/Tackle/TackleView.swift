import SwiftUI

/// 付録A の Tackle 画面。L1 では空画面。
struct TackleView: View {
    var body: some View {
        ScreenContainer {
            EmptyView()
        }
    }
}

#Preview {
    TackleView()
        .previewEnvironment()
}
