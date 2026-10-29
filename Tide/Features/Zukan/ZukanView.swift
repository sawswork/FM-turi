import SwiftData
import SwiftUI
import TideCore

/// 付録A A-5 図鑑。魚種ごとのカード（釣った／未）と記録一覧。
struct ZukanView: View {
    @Environment(LocationService.self) private var location
    @Query(filter: #Predicate<Spot> { $0.isRegistered }) private var spots: [Spot]
    @Query(sort: \CatchRecord.capturedAt, order: .reverse) private var records: [CatchRecord]
    @State private var filterIndex: Int?
    @State private var selectedSpecies: Species?

    private typealias Zuk = DesignTokens.Zukan

    /// フィルターの候補: 登録済み釣り場＋記録にある「現在地」（ADR-0006）。
    private var filterNames: [String] {
        var names = spots.map(\.name)
        if records.contains(where: { $0.spotName == "現在地" }) { names.append("現在地") }
        return names
    }

    private var nearestIndex: Int {
        let here = location.current
        guard let nearest = spots.min(by: { $0.point.distance(to: here) < $1.point.distance(to: here) }) else { return 0 }
        return filterNames.firstIndex(of: nearest.name) ?? 0
    }

    private var currentFilter: String? {
        let names = filterNames
        guard !names.isEmpty else { return nil }
        return names[(filterIndex ?? nearestIndex) % names.count]
    }

    private var filtered: [CatchRecord] {
        guard let currentFilter else { return records }
        return records.filter { $0.spotName == currentFilter }
    }

    /// 魚種ごとの集計。
    private struct Entry: Identifiable {
        let species: Species
        let count: Int
        let maxLength: Double?
        var id: String { species.id }
        var caught: Bool { count >= 1 }
    }

    private var entries: [Entry] {
        let grouped = Dictionary(grouping: filtered, by: \.speciesID)
        let all = Species.all.map { species in
            let items = grouped[species.id] ?? []
            return Entry(species: species, count: items.count, maxLength: items.compactMap(\.lengthCm).max())
        }
        return all.filter(\.caught) + all.filter { !$0.caught }
    }

    private var recordHolder: String? {
        entries.filter { $0.maxLength != nil }.max { ($0.maxLength ?? 0) < ($1.maxLength ?? 0) }?.species.id
    }

    var body: some View {
        let entries = entries
        let caughtCount = entries.filter(\.caught).count
        ScreenContainer {
            VStack(spacing: 0) {
                TopBarView {
                    LocationPill(name: currentFilter ?? "現在地") {
                        let names = filterNames
                        guard !names.isEmpty else { return }
                        filterIndex = ((filterIndex ?? nearestIndex) + 1) % names.count
                    }
                } trailing: {
                    HStack(spacing: Zuk.headerGap) {
                        HStack(alignment: .firstTextBaseline, spacing: Zuk.countGap) {
                            Text("\(caughtCount)")
                                .font(DesignTokens.Fonts.text(Zuk.countFontSize, .w300))
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text("/ \(Species.all.count)")
                                .font(DesignTokens.Fonts.text(Zuk.totalFontSize, .w500))
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                        RingView(progress: Double(caughtCount) / Double(Species.all.count),
                                 size: Zuk.ringSize, radius: Zuk.ringRadius, lineWidth: Zuk.ringLineWidth,
                                 color: DesignTokens.Colors.primary)
                    }
                }
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Zuk.gap), count: Zuk.columns), spacing: Zuk.gap) {
                        ForEach(entries) { entry in
                            Button {
                                if entry.caught { selectedSpecies = entry.species }
                            } label: {
                                ZukanCard(entry: entry, isRecordHolder: entry.species.id == recordHolder)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, Zuk.padTop)
                    .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear { location.start() }
        .sheet(item: $selectedSpecies) { species in
            SpeciesRecordsSheet(species: species, records: filtered.filter { $0.speciesID == species.id })
        }
    }

    // MARK: - カード

    private struct ZukanCard: View {
        let entry: Entry
        let isRecordHolder: Bool

        var body: some View {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Zuk.cardRadius, style: .continuous)
                    .fill(entry.caught ? DesignTokens.Colors.surface3 : Color.clear)
                VStack(spacing: Zuk.cardGap) {
                    silhouette
                        .frame(width: Zuk.silhouetteSize.width, height: Zuk.silhouetteSize.height)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(entry.maxLength.map { String(format: "%.0f", $0) } ?? "—")
                            .font(DesignTokens.Fonts.text(Zuk.lengthFontSize, .w500))
                            .foregroundStyle(isRecordHolder ? DesignTokens.Colors.orange : DesignTokens.Colors.primary)
                        Text("cm")
                            .font(DesignTokens.Fonts.text(Zuk.unitFontSize, .w500))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                    .opacity(entry.caught ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if entry.caught {
                    Text("\(entry.count)")
                        .font(DesignTokens.Fonts.text(Zuk.badgeFontSize, .w600))
                        .foregroundStyle(isRecordHolder ? DesignTokens.Colors.black : DesignTokens.Colors.primary)
                        .padding(.horizontal, Zuk.badgePadHorizontal)
                        .frame(minWidth: Zuk.badgeMinWidth)
                        .frame(height: Zuk.badgeHeight)
                        .background(isRecordHolder ? DesignTokens.Colors.orange : DesignTokens.Colors.surface2,
                                    in: RoundedRectangle(cornerRadius: Zuk.badgeRadius, style: .continuous))
                        .padding(.top, Zuk.badgeTop)
                        .padding(.trailing, Zuk.badgeRight)
                }
            }
            .frame(height: Zuk.cardHeight)
        }

        @ViewBuilder
        private var silhouette: some View {
            let shape = FishSilhouette(kind: entry.species.shape)
            if entry.caught {
                shape.fill(DesignTokens.Colors.primary)
                    .overlay(shape.stroke(DesignTokens.Colors.primary, lineWidth: Zuk.silhouetteLineWidth))
            } else {
                shape.stroke(DesignTokens.Colors.surface2, lineWidth: Zuk.silhouetteLineWidth)
            }
        }
    }
}

/// 図鑑カード→その魚の記録一覧（A-8）。
struct SpeciesRecordsSheet: View {
    let species: Species
    let records: [CatchRecord]

    private typealias Zuk = DesignTokens.Zukan

    var body: some View {
        ZStack {
            DesignTokens.Colors.sheet.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: DesignTokens.LocationPill.gap) {
                    FishSilhouette(kind: species.shape)
                        .fill(DesignTokens.Colors.primary)
                        .frame(width: Zuk.silhouetteSize.width / 2, height: Zuk.silhouetteSize.height / 2)
                    Text(species.name)
                        .font(DesignTokens.Fonts.text(DesignTokens.Detail.placeFontSize, .w600))
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Spacer(minLength: 0)
                    Text("\(records.count)")
                        .font(DesignTokens.Fonts.text(DesignTokens.Detail.placeFontSize, .w500))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                .padding(.top, DesignTokens.Detail.sheetPadTop + DesignTokens.Detail.handleBottom)
                .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(records) { record in
                            row(record)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ record: CatchRecord) -> some View {
        HStack(spacing: DesignTokens.Chip.gap * 2) {
            Group {
                if let image = PhotoStore.load(record.photoFileName) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    DesignTokens.Colors.surface2
                }
            }
            .frame(width: Zuk.recordThumb, height: Zuk.recordThumb)
            .clipShape(RoundedRectangle(cornerRadius: Zuk.recordThumbRadius, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(TimeFormat.monthDayWeekdayTime.string(from: record.capturedAt))
                    .font(DesignTokens.Fonts.text(DesignTokens.Detail.placeFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text(record.spotName)
                    .font(DesignTokens.Fonts.text(DesignTokens.Detail.unitFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(record.lengthCm.map { String(format: "%.0f", $0) } ?? "—")
                    .font(DesignTokens.Fonts.text(Zuk.lengthFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text("cm")
                    .font(DesignTokens.Fonts.text(Zuk.unitFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
        }
        .frame(height: Zuk.recordRowHeight)
        .overlay(alignment: .top) {
            Rectangle().fill(DesignTokens.Colors.surface).frame(height: 1)
        }
    }
}

#Preview {
    ZukanView()
        .previewEnvironment()
}
