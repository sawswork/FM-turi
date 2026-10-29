import SwiftData
import SwiftUI
import TideCore

/// 付録A A-1 Home。L3: 上部帯。L4: 日付行＋3日潮位グラフ。
struct HomeView: View {
    @Environment(LocationService.self) private var location
    @Environment(ConditionsStore.self) private var conditions
    @Environment(TideStore.self) private var tide
    @Query(filter: #Predicate<Spot> { $0.isRegistered }) private var spots: [Spot]
    @State private var selectedDay = 0

    /// 現在地に最も近い登録済み釣り場。
    private var nearestSpot: Spot? {
        let here = location.current
        return spots.min { $0.point.distance(to: here) < $1.point.distance(to: here) }
    }

    private var targetPoint: GeoPoint {
        nearestSpot?.point ?? location.current
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                TopBarView {
                    LocationPill(name: nearestSpot?.name ?? "現在地")
                } trailing: {
                    RoundButton(icon: .dots)
                }
                Spacer(minLength: 0)
                if !tide.days.isEmpty {
                    DateChipRow(days: tide.days, selected: $selectedDay)
                    TideGraphView(days: tide.days, selected: $selectedDay)
                }
                Spacer(minLength: 0)
            }
        }
        .onAppear { location.start() }
        .task(id: targetPoint) {
            await conditions.load(point: targetPoint)
            await tide.load(point: targetPoint)
        }
    }
}

#Preview {
    HomeView()
        .previewEnvironment()
}
