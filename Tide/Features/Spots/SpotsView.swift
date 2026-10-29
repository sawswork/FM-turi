import SwiftUI

/// 付録A の Spots 画面。L1 では空画面。
struct SpotsView: View {
    var body: some View {
        ScreenContainer {
            EmptyView()
        }
    }
}

#Preview {
    SpotsView()
        .previewEnvironment()
}
