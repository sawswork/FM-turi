import PhotosUI
import SwiftData
import SwiftUI
import TideCore

/// 付録A A-2 Catch。写真選択→候補選択→保存（図鑑へ）。
struct CatchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(LocationService.self) private var location
    @Environment(ConditionsStore.self) private var conditions
    @Environment(TideStore.self) private var tide
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Spot> { $0.isRegistered }) private var spots: [Spot]

    @State private var draft = CatchDraft()
    @State private var pickerItem: PhotosPickerItem?
    @FocusState private var lengthFocused: Bool

    private typealias Cat = DesignTokens.Catch

    private var recordPoint: GeoPoint { draft.photoLocation ?? location.current }

    private var spotName: String {
        let here = recordPoint
        return spots.min { $0.point.distance(to: here) < $1.point.distance(to: here) }?.name ?? "現在地"
    }

    private var tideDay: TideDay? {
        tide.days.first { draft.capturedAt >= $0.dayStart && draft.capturedAt < $0.dayStart.addingTimeInterval(86_400) }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    photoArea(topInset: geo.safeAreaInsets.top)
                    candidateGrid
                    autoRow
                    tacklePills
                    Spacer(minLength: 0)
                    saveButton
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear { location.start() }
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            if let data = try? await pickerItem.loadTransferable(type: Data.self) {
                draft.setPhoto(data: data)
                await draft.classify()
            }
        }
    }

    // MARK: - 写真

    private func photoArea(topInset: CGFloat) -> some View {
        ZStack(alignment: .top) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack {
                    DesignTokens.Colors.surface3
                    if let image = draft.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    CatchPhotoFrame()
                }
                .frame(height: Cat.photoHeight)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Cat.photoBottomRadius,
                                                  bottomTrailingRadius: Cat.photoBottomRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            // 閉じる（左上）と場所チップ（右上）
            HStack(alignment: .top, spacing: 0) {
                RoundButton(icon: .close, size: Cat.closeSize, iconSize: Cat.closeIconSize,
                            background: DesignTokens.Colors.surface2) {
                    draft.reset()
                    pickerItem = nil
                    router.selectedTab = .home
                }
                .padding(.top, Cat.closeTop)
                .padding(.leading, Cat.closeLeft)
                Spacer(minLength: 0)
                placeChip
                    .padding(.top, Cat.chipTop)
                    .padding(.trailing, Cat.chipRight)
            }
            .padding(.top, topInset)

            // サイズピル（左下）と AI リング（右下）
            VStack {
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 0) {
                    sizePill
                        .padding(.leading, Cat.sizePillLeft)
                        .padding(.bottom, Cat.sizePillBottom)
                    Spacer(minLength: 0)
                    aiRing
                        .padding(.trailing, Cat.aiRingRight)
                        .padding(.bottom, Cat.aiRingBottom)
                }
            }
            .frame(height: Cat.photoHeight)
        }
        .frame(height: Cat.photoHeight)
    }

    private var placeChip: some View {
        HStack(spacing: Cat.chipGap) {
            IconView(icon: .pin, size: Cat.chipPinSize, lineWidth: Cat.chipPinLineWidth, color: DesignTokens.Colors.orange)
            Text(spotName)
                .font(DesignTokens.Fonts.text(Cat.chipFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.primary)
            Text(TimeFormat.monthDayTime.string(from: draft.capturedAt))
                .font(DesignTokens.Fonts.text(Cat.chipFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
        .padding(.leading, Cat.chipPadLeading)
        .padding(.trailing, Cat.chipPadTrailing)
        .frame(height: Cat.chipHeight)
        .background(DesignTokens.Colors.black, in: RoundedRectangle(cornerRadius: Cat.chipRadius, style: .continuous))
    }

    private var sizePill: some View {
        HStack(spacing: Cat.sizePillGap) {
            IconView(icon: .ruler, size: Cat.sizePillIconSize, lineWidth: 2)
            TextField("", text: $draft.lengthText)
                .keyboardType(.decimalPad)
                .focused($lengthFocused)
                .font(DesignTokens.Fonts.text(Cat.sizePillFontSize, .w300))
                .foregroundStyle(DesignTokens.Colors.primary)
                .frame(width: Cat.sizePillFieldWidth)
        }
        .padding(.leading, Cat.sizePillPadLeading)
        .padding(.trailing, Cat.sizePillPadTrailing)
        .frame(height: Cat.sizePillHeight)
        .background(DesignTokens.Colors.black, in: RoundedRectangle(cornerRadius: Cat.sizePillRadius, style: .continuous))
        .onTapGesture { lengthFocused = true }
    }

    private var aiRing: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.Colors.black)
                .frame(width: Cat.aiRingSize, height: Cat.aiRingSize)
            RingView(progress: draft.confidence ?? 0, size: Cat.aiRingInner, radius: Cat.aiRingRadius,
                     lineWidth: Cat.aiRingLineWidth, trackColor: DesignTokens.Colors.inactive)
            Circle()
                .fill(DesignTokens.Colors.orange)
                .frame(width: Cat.aiRingDotRadius * 2, height: Cat.aiRingDotRadius * 2)
        }
    }

    // MARK: - 候補

    private var candidateGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Cat.candidateGap), count: Cat.candidateColumns),
                  spacing: Cat.candidateGap) {
            ForEach(Array(draft.candidates.enumerated()), id: \.offset) { index, species in
                let selected = index == draft.selectedIndex
                Button {
                    draft.selectedIndex = index
                } label: {
                    RoundedRectangle(cornerRadius: Cat.candidateRadius, style: .continuous)
                        .fill(selected ? DesignTokens.Colors.primary : DesignTokens.Colors.surface)
                        .frame(height: Cat.candidateHeight)
                        .overlay {
                            FishSilhouette(kind: species.shape)
                                .stroke(selected ? DesignTokens.Colors.black : DesignTokens.Colors.secondary,
                                        style: StrokeStyle(lineWidth: Cat.candidateLineWidth, lineJoin: .round))
                                .frame(width: Cat.candidateFishSize.width, height: Cat.candidateFishSize.height)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, Cat.candidatePadTop)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
    }

    // MARK: - 自動取得

    private var autoRow: some View {
        let level = tideDay?.level(at: draft.capturedAt).map { String(format: "%.1f", $0 / 100) } ?? "—"
        let wind = conditions.weather.map { String(format: "%.1f", $0.windSpeed) } ?? "—"
        let sst = conditions.marine.map { String(format: "%.0f", $0.seaSurfaceTemperature) } ?? "—"
        let moon = tideDay.map { String(format: "%.1f", $0.moonAge) }
            ?? String(format: "%.1f", MoonCalc.age(at: draft.capturedAt))
        let windRotation = Angle.degrees(((conditions.weather?.windDirection ?? 40) + 180).truncatingRemainder(dividingBy: 360))
        return HStack(spacing: Cat.autoGap) {
            autoCell(value: level) { MiniTideCurve(day: tideDay, now: draft.capturedAt) }
            autoCell(value: wind) {
                IconView(icon: .wind, size: Cat.autoIconSize, color: DesignTokens.Colors.secondary).rotationEffect(windRotation)
            }
            autoCell(value: sst) { IconView(icon: .drop, size: Cat.autoIconSize, color: DesignTokens.Colors.secondary) }
            autoCell(value: moon) { MoonGlyph(age: tideDay?.moonAge ?? MoonCalc.age(at: draft.capturedAt)) }
        }
        .padding(.top, Cat.autoPadTop)
        .padding(.horizontal, Cat.autoPadHorizontal)
    }

    private func autoCell<Icon: View>(value: String, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: Cat.autoVerticalGap) {
            icon()
                .frame(height: Cat.autoIconSize)
            Text(value)
                .font(DesignTokens.Fonts.text(Cat.autoFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.primary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - タックル

    private var tacklePills: some View {
        HStack(spacing: Cat.tackleGap) {
            tacklePill(icon: .sinker, text: "\(draft.sinkerGrams)")
            tacklePill(icon: .hook, text: draft.hookSize)
        }
        .padding(.top, Cat.tacklePadTop)
    }

    private func tacklePill(icon: TideIcon, text: String) -> some View {
        HStack(spacing: Cat.tackleInnerGap) {
            IconView(icon: icon, size: Cat.tackleIconSize)
            Text(text)
                .font(DesignTokens.Fonts.text(Cat.tackleFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.primary)
        }
        .padding(.horizontal, Cat.tacklePadHorizontal)
        .frame(height: Cat.tackleHeight)
        .background(DesignTokens.Colors.surface, in: RoundedRectangle(cornerRadius: Cat.tackleRadius, style: .continuous))
    }

    // MARK: - 保存

    private var saveButton: some View {
        Button(action: save) {
            RoundedRectangle(cornerRadius: Cat.saveRadius, style: .continuous)
                .fill(DesignTokens.Colors.orange)
                .frame(height: Cat.saveHeight)
                .overlay {
                    IconView(icon: .check, size: Cat.saveIconSize, lineWidth: Cat.saveIconLineWidth,
                             color: DesignTokens.Colors.black)
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
        .padding(.bottom, Cat.savePadBottom)
    }

    private func save() {
        lengthFocused = false
        let point = recordPoint
        let day = tideDay
        let score = FishingScore.compute(FishingScore.input(
            at: draft.capturedAt, tide: day, weather: conditions.weather, marine: conditions.marine,
            band: draft.selectedSpecies?.band ?? Species.defaultForScore.band))
        var fileName: String?
        var size = CGSize.zero
        if let image = draft.image, let saved = PhotoStore.save(image) {
            fileName = saved.fileName
            size = saved.size
        }
        let record = CatchRecord(
            capturedAt: draft.capturedAt,
            speciesID: draft.selectedSpecies?.id ?? "other",
            candidateIDs: draft.candidates.map(\.id),
            candidateConfidences: draft.candidateConfidences,
            confidence: draft.confidence,
            lengthCm: draft.lengthCm,
            spotName: spotName,
            latitude: point.latitude,
            longitude: point.longitude,
            photoFileName: fileName,
            photoWidth: size.width,
            photoHeight: size.height,
            scoreTotal: score.total,
            sinkerGrams: draft.sinkerGrams,
            hookSize: draft.hookSize
        )
        record.apply(tide: day, at: draft.capturedAt, weather: conditions.weather, marine: conditions.marine)
        context.insert(record)
        try? context.save()
        draft.reset()
        pickerItem = nil
        router.selectedTab = .zukan
    }
}

#Preview {
    CatchView()
        .previewEnvironment()
}
