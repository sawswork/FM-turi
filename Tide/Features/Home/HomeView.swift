import SwiftData
import SwiftUI
import TideCore

/// 付録A A-1 Home。
struct HomeView: View {
    @Environment(LocationService.self) private var location
    @Environment(ConditionsStore.self) private var conditions
    @Environment(TideStore.self) private var tide
    @Query(filter: #Predicate<Spot> { $0.isRegistered }) private var spots: [Spot]
    @State private var selectedDay = 0
    @State private var showDetail = false

    /// 現在地に最も近い登録済み釣り場。
    private var nearestSpot: Spot? {
        let here = location.current
        return spots.min { $0.point.distance(to: here) < $1.point.distance(to: here) }
    }

    private var targetPoint: GeoPoint {
        nearestSpot?.point ?? location.current
    }

    private var spotName: String {
        nearestSpot?.name ?? "現在地"
    }

    private func score(now: Date) -> HomeScore {
        HomeScore.make(now: now, day: tide.today,
                       selectedDay: tide.days.indices.contains(selectedDay) ? tide.days[selectedDay] : tide.today,
                       weather: conditions.weather, marine: conditions.marine,
                       marineSeries: conditions.marineSeries, band: Species.defaultForScore.band)
    }

    private func detailData(now: Date) -> DetailData {
        DetailData.make(spotName: spotName, now: now, day: tide.today, weather: conditions.weather,
                        marine: conditions.marine, score: score(now: now).result,
                        weatherSource: conditions.weatherSource, marineSource: conditions.marineSource)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            let score = score(now: now)
            ScreenContainer {
                VStack(spacing: 0) {
                    TopBarView {
                        LocationPill(name: spotName)
                    } trailing: {
                        RoundButton(icon: .dots)
                    }
                    ScoreRingView(total: score.result.total) { showDetail = true }
                    ConditionsGrid(meters: score.meters) { showDetail = true }
                    if !tide.days.isEmpty {
                        DateChipRow(days: tide.days, selected: $selectedDay)
                        TideGraphView(days: tide.days, selected: $selectedDay)
                    }
                    HourBarView(values: score.hourly, currentHour: selectedDay == 0 ? currentHour(now) : nil)
                    Spacer(minLength: 0)
                }
            }
            .fullScreenCover(isPresented: $showDetail) {
                DetailView(data: detailData(now: now)) { showDetail = false }
            }
        }
        .onAppear { location.start() }
        .task(id: targetPoint) {
            await conditions.load(point: targetPoint)
            await tide.load(point: targetPoint)
        }
    }

    private func currentHour(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Tide736.timeZone
        return cal.component(.hour, from: date)
    }
}

#Preview {
    HomeView()
        .previewEnvironment()
}
