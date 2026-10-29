import SwiftUI

/// 付録A の Catch 画面。L1 では空画面。
struct CatchView: View {
    var body: some View {
        ScreenContainer {
            EmptyView()
        }
    }
}

#Preview {
    CatchView()
        .previewEnvironment()
}
