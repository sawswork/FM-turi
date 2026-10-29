import SwiftData
import SwiftUI
import TideCore

/// 付録A A-1 Home。
struct HomeView: View {
    @Environment(LocationService.self) private var location
    @Environment(ConditionsStore.self) private var conditions
    @Environment(TideStore.self) private var tide
    @Query(filter: #Predicate<Spot> { $0.isRegistered }) private var spots: [Spot]
    @Query(sort: \TackleItem.sortOrder) private var tackle: [TackleItem]
    @State private var selectedDay = 0
    @State private var showDetail = false
    @State private var showSettings = false

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
                        RoundButton(icon: .dots) { showSettings = true }
                    }
                    AlertStrip(alerts: conditions.weather?.alerts ?? [])
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear { location.start() }
        .task(id: targetPoint) {
            await conditions.load(point: targetPoint)
            await tide.load(point: targetPoint)
            publishWidgetSnapshot()
        }
    }

    /// ウィジェット用に今日の値を App Group へ書き出す。
    private func publishWidgetSnapshot() {
        let now = Date()
        let score = score(now: now)
        let band = Species.defaultForScore.band
        let hourly = tide.today.map {
            FishingScore.hourlyTotals(day: $0, weather: conditions.weather, marineSeries: conditions.marineSeries, band: band)
        } ?? Array(repeating: score.result.total, count: 24)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Tide736.timeZone
        let snapshot = WidgetSnapshot(
            spotName: spotName,
            total: score.result.total,
            hourly: hourly,
            meters: score.meters.map(\.widgetMeter),
            moonAge: tide.today?.moonAge ?? MoonCalc.age(at: now),
            tideTypeLabel: tide.today?.tideType.label ?? MoonCalc.tideType(age: MoonCalc.age(at: now)).label,
            isRising: tide.today?.isRising(at: now) ?? true,
            tideLevels: tide.today?.hourlyLevels ?? [],
            sinkers: tackle.filter { $0.kind == .sinker }.map { WidgetSnapshot.Stock(label: $0.label, count: $0.stock) },
            hooks: tackle.filter { $0.kind == .hook }.map { WidgetSnapshot.Stock(label: $0.label, count: $0.stock) },
            dayStart: tide.today?.dayStart ?? cal.startOfDay(for: now),
            generatedAt: now
        )
        WidgetBridge.save(snapshot)
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
