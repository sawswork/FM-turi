import SwiftUI

/// 付録A の Zukan 画面。L1 では空画面。
struct ZukanView: View {
    var body: some View {
        ScreenContainer {
            EmptyView()
        }
    }
}

#Preview {
    ZukanView()
}
