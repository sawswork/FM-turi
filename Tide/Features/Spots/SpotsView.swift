import MapKit
import SwiftData
import SwiftUI
import TideCore

/// 付録A A-4 釣り場。MapKit の地図に候補点（未登録）と登録済みバッジ、下に登録済みリスト。
struct SpotsView: View {
    @Environment(LocationService.self) private var location
    @Environment(ConditionsStore.self) private var conditions
    @Environment(TideStore.self) private var tide
    @Environment(SpotsStore.self) private var spotsStore
    @Query(sort: \Spot.createdAt) private var allSpots: [Spot]

    @State private var selectedCandidate: Spot?
    @State private var camera: MapCameraPosition = .automatic
    @State private var didCenter = false

    private typealias Spt = DesignTokens.Spots

    private var registered: [Spot] { allSpots.filter(\.isRegistered) }
    private var candidates: [Spot] { allSpots.filter { !$0.isRegistered } }

    /// Home と同じ「現在地に最も近い登録済み釣り場」= 橙。
    private var nearest: Spot? {
        let here = location.current
        return registered.min { $0.point.distance(to: here) < $1.point.distance(to: here) }
    }

    private var sortedRegistered: [Spot] {
        let here = location.current
        return registered.sorted { $0.point.distance(to: here) < $1.point.distance(to: here) }
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                TopBarView {
                    LocationPill(name: "現在地")
                } trailing: {
                    RoundButton(icon: .plus) {
                        Task { await registerTapped() }
                    }
                }
                map
                    .frame(height: Spt.mapHeight)
                    .padding(.top, Spt.mapMarginTop)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedRegistered) { spot in
                            row(spot)
                        }
                    }
                    .padding(.top, Spt.listPadTop)
                    .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear { location.start() }
        .task(id: location.current) {
            if !didCenter || location.hasFix {
                camera = .region(MKCoordinateRegion(center: location.current.coordinate,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)))
                didCenter = true
            }
            await spotsStore.searchCandidates(around: location.current)
            await refreshScores()
        }
        .task(id: registered.count) {
            await refreshScores()
        }
        .task(id: selectedCandidate?.id) {
            if let selectedCandidate {
                await spotsStore.refreshScores(spots: [selectedCandidate], conditions: conditions, tide: tide,
                                               band: Species.defaultForScore.band)
            }
        }
    }

    private func refreshScores() async {
        await spotsStore.refreshScores(spots: registered, conditions: conditions, tide: tide,
                                       band: Species.defaultForScore.band)
    }

    private func registerTapped() async {
        if let candidate = selectedCandidate {
            spotsStore.register(candidate)
            selectedCandidate = nil
        } else {
            await spotsStore.registerCurrentLocation(location.current)
        }
    }

    private func score(_ spot: Spot) -> Int {
        spotsStore.scores[spot.id] ?? 0
    }

    private func scoreColor(_ spot: Spot) -> Color {
        if spot.id == nearest?.id { return DesignTokens.Colors.orange }
        return score(spot) >= Spt.goodScore ? DesignTokens.Colors.primary : DesignTokens.Colors.secondary
    }

    // MARK: - 地図

    private var map: some View {
        Map(position: $camera) {
            Annotation("", coordinate: location.current.coordinate, anchor: .center) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.primary.opacity(Spt.currentHaloOpacity))
                        .frame(width: Spt.currentHaloRadius * 2, height: Spt.currentHaloRadius * 2)
                    Circle()
                        .fill(DesignTokens.Colors.primary)
                        .frame(width: Spt.currentDotRadius * 2, height: Spt.currentDotRadius * 2)
                }
            }
            ForEach(candidates) { spot in
                Annotation("", coordinate: spot.point.coordinate, anchor: .center) {
                    candidateDot(spot)
                }
            }
            ForEach(registered) { spot in
                Annotation("", coordinate: spot.point.coordinate, anchor: .center) {
                    badge(spot)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControlVisibility(.hidden)
    }

    private func candidateDot(_ spot: Spot) -> some View {
        let selected = spot.id == selectedCandidate?.id
        return ZStack {
            Color.clear
                .frame(width: Spt.candidateTapSize, height: Spt.candidateTapSize)
                .contentShape(Circle())
            Circle()
                .fill(selected ? DesignTokens.Colors.primary : DesignTokens.Colors.inactive)
                .frame(width: selected ? Spt.candidateSelectedSize : Spt.candidateSize,
                       height: selected ? Spt.candidateSelectedSize : Spt.candidateSize)
        }
        .onTapGesture { selectedCandidate = selected ? nil : spot }
        .overlay(alignment: .leading) {
            if selected {
                popup(spot)
                    .fixedSize()
                    .offset(x: Spt.candidateTapSize / 2 + Spt.popupOffsetX - Spt.candidateSelectedSize / 2,
                            y: -Spt.popupHeight / 2 + Spt.candidateTapSize / 2 - 8)
            }
        }
    }

    private func popup(_ spot: Spot) -> some View {
        HStack(spacing: Spt.popupGap) {
            Text(spot.name)
                .font(DesignTokens.Fonts.text(Spt.popupNameFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.black)
                .lineLimit(1)
            Text("\(score(spot))")
                .font(DesignTokens.Fonts.text(Spt.popupScoreFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.black)
            Button {
                spotsStore.register(spot)
                selectedCandidate = nil
            } label: {
                Circle()
                    .fill(DesignTokens.Colors.orange)
                    .frame(width: Spt.popupButtonSize, height: Spt.popupButtonSize)
                    .overlay {
                        IconView(icon: .plus, size: Spt.popupButtonIconSize, lineWidth: Spt.popupButtonLineWidth,
                                 color: DesignTokens.Colors.black)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Spt.popupPadLeading)
        .padding(.trailing, Spt.popupPadTrailing)
        .frame(height: Spt.popupHeight)
        .background(DesignTokens.Colors.primary, in: RoundedRectangle(cornerRadius: Spt.popupRadius, style: .continuous))
    }

    private func badge(_ spot: Spot) -> some View {
        let value = score(spot)
        return ZStack {
            Circle()
                .fill(DesignTokens.Colors.black)
                .frame(width: Spt.badgeOuterRadius * 2, height: Spt.badgeOuterRadius * 2)
            RingView(progress: Double(value) / 100, size: Spt.badgeRingRadius * 2 + Spt.badgeRingLineWidth,
                     radius: Spt.badgeRingRadius, lineWidth: Spt.badgeRingLineWidth, color: scoreColor(spot))
            Text("\(value)")
                .font(DesignTokens.Fonts.text(Spt.badgeFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.primary)
        }
        .frame(width: Spt.badgeSize, height: Spt.badgeSize)
    }

    // MARK: - リスト

    private func row(_ spot: Spot) -> some View {
        let distanceKm = spot.point.distance(to: location.current) / 1000
        let windDirection = spotsStore.windDirections[spot.id] ?? 40
        return HStack(spacing: Spt.rowGap) {
            Circle()
                .fill(scoreColor(spot))
                .frame(width: Spt.rowDotSize, height: Spt.rowDotSize)
            Text(spot.name)
                .font(DesignTokens.Fonts.text(Spt.rowNameFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.primary)
                .lineLimit(1)
            Text(distanceKm < 10 ? String(format: "%.1fkm", distanceKm) : String(format: "%.0fkm", distanceKm))
                .font(DesignTokens.Fonts.text(Spt.rowDistanceFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.secondary)
            IconView(icon: .wind, size: Spt.rowWindIconSize, color: DesignTokens.Colors.secondary)
                .rotationEffect(.degrees((windDirection + 180).truncatingRemainder(dividingBy: 360)))
            Spacer(minLength: 0)
            Text("\(score(spot))")
                .font(DesignTokens.Fonts.text(Spt.rowScoreFontSize, .w500))
                .foregroundStyle(scoreColor(spot))
                .frame(width: Spt.rowScoreWidth, alignment: .trailing)
        }
        .frame(height: Spt.rowHeight)
        .overlay(alignment: .top) {
            Rectangle().fill(DesignTokens.Colors.surface).frame(height: 1)
        }
    }
}

#Preview {
    SpotsView()
        .previewEnvironment()
}
