import SwiftUI
import PhotosUI
import UIKit
import HealthKit
import StoreKit
import WidgetKit
import AVFoundation

// MARK: - Camera Mode
enum CameraMode {
    case snapFood
    case snapFoodWithContext
    case nutritionLabel
}

// MARK: - Add Food Intent Bridge

@Observable
final class AddFoodIntent {
    enum Action: String, Equatable, CaseIterable, Identifiable {
        case camera
        case cameraWithContext
        case nutritionLabel
        case barcode
        case fromPhotos
        case fromPhotosWithContext
        case text
        case voice
        case manual
        case savedMeals
        case copyFromDay

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .camera: return "Camera"
            case .cameraWithContext: return "Camera + Note"
            case .nutritionLabel: return "Nutrition Label"
            case .barcode: return "Barcode"
            case .fromPhotos: return "From Photos"
            case .fromPhotosWithContext: return "From Photos + Note"
            case .text: return "Text Input"
            case .voice: return "Voice"
            case .manual: return "Manual Entry"
            case .savedMeals: return "Saved Meals"
            case .copyFromDay: return "Copy from Day"
            }
        }

        var systemImage: String {
            switch self {
            case .camera: return "camera.fill"
            case .cameraWithContext: return "camera.badge.ellipsis"
            case .nutritionLabel: return "text.viewfinder"
            case .barcode: return "barcode.viewfinder"
            case .fromPhotos: return "photo.on.rectangle"
            case .fromPhotosWithContext: return "photo.badge.plus"
            case .text: return "character.cursor.ibeam"
            case .voice: return "mic.fill"
            case .manual: return "square.and.pencil"
            case .savedMeals: return "bookmark.fill"
            case .copyFromDay: return "calendar"
            }
        }
    }
    var pendingAction: Action?
}

// MARK: - Add Food Options Order Persistence

enum AddFoodOptionsOrder {
    static let storageKey = "addFoodOptionsOrder"

    static func decode(_ raw: String) -> [AddFoodIntent.Action] {
        let saved = raw.split(separator: ",").compactMap { AddFoodIntent.Action(rawValue: String($0)) }
        let savedSet = Set(saved)
        let missing = AddFoodIntent.Action.allCases.filter { !savedSet.contains($0) }
        return saved + missing
    }

    static func encode(_ actions: [AddFoodIntent.Action]) -> String {
        actions.map(\.rawValue).joined(separator: ",")
    }
}

enum AppTab: Hashable {
    case home, progress, coach, add
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(FoodStore.self) private var foodStore
    @AppStorage(AppThemeColor.storageKey) private var appThemeColorRaw = AppThemeColor.defaultColor.rawValue
    @State private var selectedTab: AppTab = .home
    @State private var lastNonAddTab: AppTab = .home
    @State private var showAddOptions = false
    @State private var addFoodIntent = AddFoodIntent()
    @State private var addFoodPromptDismissedDay = ""

    private static let promptDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var todayDayKey: String {
        Self.promptDayFormatter.string(from: Date())
    }

    private var shouldShowAddFoodPrompt: Bool {
        guard selectedTab == .home else { return false }
        guard foodStore.entriesByMeal(for: Date(), order: .defaultOrder).isEmpty else { return false }
        return addFoodPromptDismissedDay != todayDayKey
    }

    private func dismissAddFoodPrompt() {
        addFoodPromptDismissedDay = todayDayKey
    }

    /// Positions the prompt callout so its pointer tip lands just above the "+"
    /// Add Food button. Both iOS versions place that button a fixed distance from
    /// the screen's bottom-right corner, so distance-from-edge padding is stable
    /// across iPhone screen sizes.
    private var addFoodPromptTrailingPadding: CGFloat {
        // The callout shape's pointer tip sits `pointerInsetFromRight` (24pt)
        // from the shape's right edge. The "+" button center is ~44pt from the
        // screen's right edge on iOS 26 (~42pt on the legacy floating button).
        // Trailing padding = buttonCenterFromRight - pointerInsetFromRight.
        if #available(iOS 26.0, *) { return 20 }
        return 18
    }

    private var addFoodPromptBottomPadding: CGFloat {
        // Pointer tip almost touches the top edge of the "+" button.
        if #available(iOS 26.0, *) { return 66 }
        return 52
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if shouldShowAddFoodPrompt {
                AddFoodPromptOverlay(onDismiss: dismissAddFoodPrompt)
                    .padding(.trailing, addFoodPromptTrailingPadding)
                    .padding(.bottom, addFoodPromptBottomPadding)
                    .allowsHitTesting(true)
            }
        }
        .environment(addFoodIntent)
        .tint(AppThemeColor.color(for: appThemeColorRaw).color)
        .onChange(of: selectedTab) { _, new in
            if new == .add {
                showAddOptions = true
                DispatchQueue.main.async {
                    selectedTab = lastNonAddTab
                }
            } else {
                lastNonAddTab = new
            }
        }
        .sheet(isPresented: $showAddOptions) {
            AddFoodOptionsSheet(intent: addFoodIntent)
                .presentationDetents([.medium, .large])
        }
        .task {
            await storeManager.checkEntitlements()
        }
        .fullScreenCover(isPresented: Binding(
            get: {
                if CommandLine.arguments.contains("--bypass-paywall-debug") { return false }
                #if DEBUG
                // Screenshot seeding implies "I want a fully usable app right
                // now" — having the paywall cover the seeded Home screen
                // would defeat the purpose.
                if CommandLine.arguments.contains(MockDataSeeder.flag) { return false }
                #endif
                return storeManager.hasCheckedEntitlements && !storeManager.isSubscribed
            },
            set: { _ in }
        )) {
            PaywallView()
        }
    }

    @available(iOS 26.0, *)
    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView()
            }
            Tab("AI", systemImage: "sparkles", value: AppTab.coach) {
                ChatThreadListView()
            }
            Tab("Progress", systemImage: "chart.bar.fill", value: AppTab.progress) {
                ProgressTabView()
            }
            Tab("Add", systemImage: "plus", value: AppTab.add, role: .search) {
                Color.clear
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(AppTab.home)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            ChatThreadListView()
                .tag(AppTab.coach)
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("AI")
                }

            ProgressTabView()
                .tag(AppTab.progress)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }
        }
    }

}

// MARK: - Add Food Options Sheet (iOS 26 search-tab destination)
private struct AddFoodOptionsSheet: View {
    let intent: AddFoodIntent
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AddFoodOptionsOrder.storageKey) private var orderRaw: String = ""

    private var orderedActions: [AddFoodIntent.Action] {
        AddFoodOptionsOrder.decode(orderRaw)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(orderedActions) { action in
                        row(action)
                            .deleteDisabled(true)
                    }
                    .onMove(perform: move)
                } footer: {
                    Text("Tap a row to use it. Touch and hold the handle on the right to drag and reorder.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        orderRaw = AddFoodOptionsOrder.encode(AddFoodIntent.Action.allCases)
                    } label: {
                        Text("Reset")
                    }
                    .disabled(orderRaw.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ action: AddFoodIntent.Action) -> some View {
        Button {
            intent.pendingAction = action
            dismiss()
        } label: {
            Label(action.title, systemImage: action.systemImage)
                .foregroundStyle(.primary)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var items = orderedActions
        items.move(fromOffsets: source, toOffset: destination)
        orderRaw = AddFoodOptionsOrder.encode(items)
    }
}

// MARK: - Floating Add Food Menu Button
private struct AddFoodMenuButton: View {
    let intent: AddFoodIntent
    @AppStorage(AddFoodOptionsOrder.storageKey) private var orderRaw: String = ""

    private var orderedActions: [AddFoodIntent.Action] {
        AddFoodOptionsOrder.decode(orderRaw)
    }

    var body: some View {
        Menu {
            ForEach(orderedActions) { action in
                Button {
                    intent.pendingAction = action
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        colors: AppColors.calorieGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: AppColors.calorie.opacity(0.35), radius: 10, x: 0, y: 5)
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
        }
        .menuOrder(.fixed)
    }
}

// MARK: - Home View (Main Dashboard)
struct HomeView: View {
    @Environment(FoodStore.self) private var foodStore
    @Environment(AddFoodIntent.self) private var addFoodIntent
    @State private var showCamera = false
    @State private var showBarcodeScanner = false
    @State private var capturedImage: UIImage?
    @State private var cameraMode: CameraMode = .snapFood
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoPickerMode: CameraMode = .snapFood
    @State private var showPhotoPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedDate: Date = .now
    @State private var showVoicePopover = false
    @State private var showTextPopover = false
    @State private var showManualPopover = false
    @State private var showRecentSheet = false
    @State private var showCopyFromDaySheet = false
    @State private var pendingContextImage: UIImage?
    @State private var contextDescription: String = ""
    @State private var showContextSheet = false

    enum ActiveSheet: String, Identifiable {
        case analyzing, foodResult, analyzingText, lookingUpBarcode, editFood
        var id: String { rawValue }
    }
    @State private var activeSheet: ActiveSheet?
    @State private var editingEntry: FoodEntry?

    @State private var currentFoodResult: GeminiService.FoodAnalysis?
    @State private var currentImage: UIImage?
    @State private var analysisTask: Task<Void, Never>?
    @State private var currentEmoji: String?
    @State private var currentFoodSource: FoodSource = .snapFood
    @State private var showNutritionDetail = false
    @AppStorage("aiAnalysisConsentGiven") private var aiConsentGiven: Bool = false
    @AppStorage(FoodLogSortOrder.storageKey) private var foodLogSortOrderRaw = FoodLogSortOrder.defaultOrder.rawValue
    @AppStorage(HomeTopNutrient.storageKey) private var homeTopNutrientsRaw = HomeTopNutrient.storageValue(for: HomeTopNutrient.defaultSelection)
    @AppStorage(OptionalNutrientGoals.storageKey) private var optionalNutrientGoalsData = Data()
    @State private var showAIConsent = false
    /// Action the user chose before consent was required; replayed once they tap Allow.
    @State private var pendingConsentAction: (() -> Void)?
    @State private var showSettings = false
    @Environment(ProfileStore.self) private var profileStore

    /// Force a body re-evaluation whenever profileStore.profile changes by reading it
    /// at the top of body. SwiftUI's @Observable tracking sometimes misses the access
    /// when the read is buried in a computed property; explicit access guarantees it.
    private var userProfile: UserProfile { profileStore.profile }
    private var calorieGoal: Int { userProfile.effectiveCalories }
    private var proteinGoal: Int { userProfile.effectiveProtein }
    private var carbsGoal: Int { userProfile.effectiveCarbs }
    private var fatGoal: Int { userProfile.effectiveFat }
    private var selectedCalories: Int { foodStore.calories(for: selectedDate) }
    private var caloriesRemaining: Int { max(calorieGoal - selectedCalories, 0) }
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    private var foodLogSortOrder: FoodLogSortOrder { FoodLogSortOrder.order(for: foodLogSortOrderRaw) }
    private var homeTopNutrients: [HomeTopNutrient] { HomeTopNutrient.selection(from: homeTopNutrientsRaw) }
    private var optionalNutrientGoals: OptionalNutrientGoals { OptionalNutrientGoals.decoded(from: optionalNutrientGoalsData) }
    private var logDateForSelectedDay: Date { logDate(on: selectedDate) }

    private var navigationTitle: String {
        if isToday { return "Today" }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func logDate(on day: Date, now: Date = .now) -> Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return now }

        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
        var components = DateComponents()
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        components.nanosecond = timeComponents.nanosecond
        return calendar.date(from: components) ?? day
    }

    var body: some View {
        // Explicit observation tracking — reads profileStore.profile at body root
        // so SwiftUI invalidates this view on every profile mutation.
        let _ = profileStore.profile
        return NavigationStack {
            List {
                // Week energy strip
                Section {
                    WeekEnergyStrip(
                        selectedDate: $selectedDate,
                        caloriesForDate: { foodStore.calories(for: $0) },
                        calorieGoal: calorieGoal
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                // Calorie hero
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            ActivityRingView(
                                progress: calorieGoal > 0 ? min(Double(selectedCalories) / Double(calorieGoal), 1.0) : 0,
                                ringWidth: 18,
                                gradientColors: AppColors.calorieGradient
                            )
                            .frame(width: 240, height: 240)

                            VStack(spacing: 4) {
                                Text("\(selectedCalories)")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: selectedCalories)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)

                                Text("of \(calorieGoal) kcal")
                                    .font(.system(.callout, design: .rounded, weight: .medium))
                                    .foregroundStyle(.tertiary)

                                HStack(spacing: 6) {
                                    Image(systemName: caloriesRemaining > 0 ? "flame" : "checkmark.circle.fill")
                                        .font(.system(.caption, weight: .semibold))
                                        .foregroundStyle(AppColors.calorie)
                                    Text("\(caloriesRemaining) kcal left")
                                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText())
                                        .animation(.snappy, value: caloriesRemaining)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(AppColors.calorie.opacity(0.08))
                                )
                                .padding(.top, 2)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Top nutrient trio
                Section {
                    HStack(spacing: 20) {
                        ForEach(homeTopNutrients) { nutrient in
                            MacroCard(
                                label: nutrient.displayName,
                                current: nutrient.value(from: foodStore, on: selectedDate),
                                goal: nutrient.goal(for: userProfile, optionalGoals: optionalNutrientGoals),
                                unit: nutrient.unit,
                                gradientColors: nutrient.gradientColors,
                                iconName: nutrient.iconName
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Food list
                let mealGroups = foodStore.entriesByMeal(for: selectedDate, order: foodLogSortOrder)
                if mealGroups.isEmpty {
                    Section(isToday ? "Today's Food" : "Food Log") {
                        Text("No foods logged")
                            .foregroundStyle(.secondary)
                            .listRowBackground(AppColors.appCard)
                    }
                } else {
                    ForEach(mealGroups) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                FoodRow(entry: entry)
                                    .listRowBackground(AppColors.appCard)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingEntry = entry
                                        activeSheet = .editFood
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            foodStore.deleteEntry(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        Button {
                                            foodStore.toggleFavorite(entry)
                                        } label: {
                                            Label(foodStore.isFavorite(entry) ? "Unfavorite" : "Favorite", systemImage: foodStore.isFavorite(entry) ? "heart.slash.fill" : "heart.fill")
                                        }
                                        .tint(AppColors.calorie)
                                    }
                            }
                        } header: {
                            HStack(alignment: .center) {
                                Label(group.meal.displayName, systemImage: group.meal.icon)
                                Spacer()
                                if group.id == mealGroups.first?.id {
                                    Menu {
                                        Picker("Food Log Order", selection: $foodLogSortOrderRaw) {
                                            ForEach(FoodLogSortOrder.allCases) { order in
                                                Text(order.displayName).tag(order.rawValue)
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.arrow.down")
                                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                            Text("Sort")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        }
                                    }
                                    .tint(AppColors.calorie)
                                    .textCase(nil)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .animation(.snappy, value: selectedDate)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showNutritionDetail = true
                    } label: {
                        Image(systemName: "list.bullet.clipboard")
                    }
                    .tint(AppColors.calorie)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(AppColors.calorie)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if #unavailable(iOS 26.0) {
                    AddFoodMenuButton(intent: addFoodIntent)
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                }
            }
            .onChange(of: addFoodIntent.pendingAction) { _, action in
                guard let action else { return }
                addFoodIntent.pendingAction = nil
                handle(addAction: action)
            }
            .sheet(isPresented: $showTextPopover) {
                TextFoodInputView(
                    onCancel: {
                        showTextPopover = false
                    },
                    onSubmit: { description in
                        showTextPopover = false
                        currentImage = nil
                        currentEmoji = nil
                        currentFoodSource = .textInput
                        guard aiConsentGiven else { showAIConsent = true; return }
                        analysisTask = Task {
                            try? await Task.sleep(for: .milliseconds(300))
                            if Task.isCancelled { return }
                            activeSheet = .analyzingText
                            do {
                                let result = try await GeminiService.analyzeTextInput(description: description)
                                if Task.isCancelled { return }
                                currentFoodResult = result
                                currentEmoji = result.emoji
                                activeSheet = .foodResult
                            } catch {
                                if Task.isCancelled { return }
                                activeSheet = nil
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                )
            }
            .fullScreenCover(isPresented: $showVoicePopover) {
                VoiceInputView(
                    onCancel: {
                        showVoicePopover = false
                    },
                    onSubmit: { description in
                        showVoicePopover = false
                        currentImage = nil
                        currentEmoji = nil
                        currentFoodSource = .textInput
                        guard aiConsentGiven else { showAIConsent = true; return }
                        analysisTask = Task {
                            try? await Task.sleep(for: .milliseconds(300))
                            if Task.isCancelled { return }
                            activeSheet = .analyzingText
                            do {
                                let result = try await GeminiService.analyzeTextInput(description: description)
                                if Task.isCancelled { return }
                                currentFoodResult = result
                                currentEmoji = result.emoji
                                activeSheet = .foodResult
                            } catch {
                                if Task.isCancelled { return }
                                activeSheet = nil
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showManualPopover) {
                ManualEntryView(
                    logDate: logDateForSelectedDay,
                    onCancel: { showManualPopover = false },
                    onSave: { entry in
                        showManualPopover = false
                        foodStore.addEntry(entry)
                    }
                )
            }
            .fullScreenCover(isPresented: $showCamera) {
                FoodCameraView(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(
                    onScan: { barcode in
                        showBarcodeScanner = false
                        startBarcodeLookup(barcode)
                    },
                    onCancel: {
                        showBarcodeScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .onChange(of: capturedImage) { oldValue, newValue in
                guard let image = newValue else { return }
                capturedImage = nil
                currentImage = image
                currentEmoji = nil
                if cameraMode == .snapFoodWithContext {
                    pendingContextImage = image
                    contextDescription = ""
                    showContextSheet = true
                } else {
                    startAnalysis(image: image, mode: cameraMode)
                }
            }
            .sheet(isPresented: $showContextSheet) {
                ContextDescriptionSheet(
                    image: pendingContextImage,
                    description: $contextDescription,
                    onAnalyze: {
                        let desc = contextDescription
                        let image = pendingContextImage
                        showContextSheet = false
                        pendingContextImage = nil
                        if let image {
                            startAnalysis(image: image, mode: .snapFoodWithContext, description: desc)
                        }
                    },
                    onCancel: {
                        showContextSheet = false
                        pendingContextImage = nil
                        currentImage = nil
                    }
                )
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .analyzing:
                    AnalyzingView(
                        image: currentImage,
                        message: "Analyzing your food…",
                        subMessages: [
                            "Identifying ingredients",
                            "Estimating portions",
                            "Calculating nutrition"
                        ],
                        onCancel: { cancelAnalysis() }
                    )
                case .analyzingText:
                    AnalyzingView(
                        image: nil,
                        systemIcon: "text.magnifyingglass",
                        message: "Looking up nutrition…",
                        subMessages: [
                            "Searching nutrition databases",
                            "Crunching the numbers",
                            "Almost there"
                        ],
                        onCancel: { cancelAnalysis() }
                    )
                case .lookingUpBarcode:
                    AnalyzingView(
                        image: nil,
                        systemIcon: "barcode.viewfinder",
                        message: "Looking up barcode…",
                        subMessages: [
                            "Looking up product",
                            "Fetching nutrition facts",
                            "Almost there"
                        ],
                        onCancel: { cancelAnalysis() }
                    )
                case .foodResult:
                    if let result = currentFoodResult {
                        FoodResultView(
                            image: currentImage,
                            emoji: currentEmoji,
                            source: currentFoodSource,
                            name: result.name,
                            calories: result.calories,
                            protein: result.protein,
                            carbs: result.carbs,
                            fat: result.fat,
                            servingSizeGrams: result.servingSizeGrams,
                            sugar: result.sugar,
                            addedSugar: result.addedSugar,
                            fiber: result.fiber,
                            saturatedFat: result.saturatedFat,
                            monounsaturatedFat: result.monounsaturatedFat,
                            polyunsaturatedFat: result.polyunsaturatedFat,
                            cholesterol: result.cholesterol,
                            sodium: result.sodium,
                            potassium: result.potassium,
                            servingUnitOptions: result.servingUnitOptions,
                            selectedServingUnit: result.selectedServingUnit,
                            selectedServingQuantity: result.selectedServingQuantity,
                            logDate: logDateForSelectedDay,
                            onLog: { entry in
                                foodStore.addEntry(entry)
                            }
                        )
                    }
                case .editFood:
                    if let editingEntry {
                        EditFoodEntryView(entry: editingEntry)
                    }
                }
            }
            .sheet(isPresented: $showRecentSheet, content: {
                RecentsView(logDate: logDateForSelectedDay, onReview: { entry in
                    if let imageData = entry.imageData, let image = UIImage(data: imageData) {
                        currentImage = image
                    } else {
                        currentImage = nil
                    }
                    currentEmoji = entry.emoji
                    currentFoodSource = entry.source
                    currentFoodResult = GeminiService.FoodAnalysis(
                        name: entry.name,
                        calories: entry.calories,
                        protein: entry.protein,
                        carbs: entry.carbs,
                        fat: entry.fat,
                        servingSizeGrams: entry.servingSizeGrams ?? 100,
                        emoji: entry.emoji,
                        sugar: entry.sugar,
                        addedSugar: entry.addedSugar,
                        fiber: entry.fiber,
                        saturatedFat: entry.saturatedFat,
                        monounsaturatedFat: entry.monounsaturatedFat,
                        polyunsaturatedFat: entry.polyunsaturatedFat,
                        cholesterol: entry.cholesterol,
                        sodium: entry.sodium,
                        potassium: entry.potassium,
                        servingUnitOptions: entry.servingUnitOptions,
                        selectedServingUnit: entry.selectedServingUnit,
                        selectedServingQuantity: entry.selectedServingQuantity
                    )
                    activeSheet = .foodResult
                })
            })
            .sheet(isPresented: $showCopyFromDaySheet) {
                CopyFromDaySheet(targetDate: selectedDate)
            }
            .interactiveDismissDisabled(activeSheet == .analyzing || activeSheet == .analyzingText || activeSheet == .lookingUpBarcode)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                guard let item = newValue else { return }
                selectedPhotoItem = nil
                guard aiConsentGiven else { showAIConsent = true; return }
                analysisTask = Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        currentImage = image
                        currentEmoji = nil
                        currentFoodSource = .snapFood
                        if photoPickerMode == .snapFoodWithContext {
                            pendingContextImage = image
                            contextDescription = ""
                            showContextSheet = true
                            return
                        }

                        activeSheet = .analyzing
                        do {
                            let result = try await GeminiService.autoAnalyze(image: image)
                            if Task.isCancelled { return }
                            currentFoodResult = result
                            activeSheet = .foodResult
                        } catch {
                            if Task.isCancelled { return }
                            activeSheet = nil
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showNutritionDetail) {
                NutritionDetailView(date: selectedDate, homeTopNutrientsRaw: $homeTopNutrientsRaw)
            }
            .sheet(isPresented: $showSettings) {
                ProfileView()
            }
            .sheet(isPresented: $showAIConsent, onDismiss: {
                // Replay the action the user originally chose, but only if they
                // consented. Running it here (after the sheet has fully dismissed)
                // avoids presenting the camera/picker while this sheet is closing.
                let action = pendingConsentAction
                pendingConsentAction = nil
                if aiConsentGiven { action?() }
            }) {
                AIConsentSheetView(
                    onAllow: {
                        aiConsentGiven = true
                        showAIConsent = false
                    },
                    onCancel: {
                        showAIConsent = false
                    }
                )
            }
        }
    }


    private func requireAIConsent(_ action: @escaping () -> Void) {
        guard aiConsentGiven else {
            pendingConsentAction = action
            showAIConsent = true
            return
        }
        action()
    }

    private func handle(addAction action: AddFoodIntent.Action) {
        switch action {
        case .camera:
            requireAIConsent {
                cameraMode = .snapFood
                showCamera = true
            }
        case .cameraWithContext:
            requireAIConsent {
                cameraMode = .snapFoodWithContext
                showCamera = true
            }
        case .nutritionLabel:
            requireAIConsent {
                cameraMode = .nutritionLabel
                showCamera = true
            }
        case .barcode:
            showBarcodeScanner = true
        case .fromPhotos:
            requireAIConsent {
                cameraMode = .snapFood
                photoPickerMode = .snapFood
                showPhotoPicker = true
            }
        case .fromPhotosWithContext:
            requireAIConsent {
                cameraMode = .snapFoodWithContext
                photoPickerMode = .snapFoodWithContext
                showPhotoPicker = true
            }
        case .text:
            requireAIConsent {
                showTextPopover = true
            }
        case .voice:
            requireAIConsent {
                showVoicePopover = true
            }
        case .manual:
            showManualPopover = true
        case .savedMeals:
            showRecentSheet = true
        case .copyFromDay:
            showCopyFromDaySheet = true
        }
    }

    private func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        activeSheet = nil
        currentImage = nil
    }

    private func startAnalysis(image: UIImage, mode: CameraMode, description: String? = nil) {
        guard aiConsentGiven else { showAIConsent = true; return }
        activeSheet = .analyzing

        analysisTask = Task {
            do {
                switch mode {
                case .snapFood:
                    let result = try await GeminiService.analyzeFood(image: image)
                    if Task.isCancelled { return }
                    currentFoodResult = result
                    currentFoodSource = .snapFood
                    activeSheet = .foodResult

                case .snapFoodWithContext:
                    let result = try await GeminiService.analyzeFood(image: image, description: description)
                    if Task.isCancelled { return }
                    currentFoodResult = result
                    currentFoodSource = .snapFood
                    activeSheet = .foodResult

                case .nutritionLabel:
                    let label = try await GeminiService.analyzeNutritionLabel(image: image)
                    if Task.isCancelled { return }
                    let servingGrams = label.servingSizeGrams ?? 100
                    currentFoodResult = label.scaled(to: servingGrams)
                    currentFoodSource = .nutritionLabel
                    activeSheet = .foodResult
                }
            } catch {
                if Task.isCancelled { return }
                activeSheet = nil
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func startBarcodeLookup(_ barcode: String) {
        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBarcode.isEmpty else { return }

        currentImage = nil
        currentEmoji = nil
        currentFoodSource = .barcode
        activeSheet = .lookingUpBarcode

        analysisTask = Task {
            do {
                let result = try await OpenFoodFactsService.lookup(barcode: trimmedBarcode)
                if Task.isCancelled { return }
                currentFoodResult = result
                currentEmoji = result.emoji
                activeSheet = .foodResult
            } catch {
                if Task.isCancelled { return }
                activeSheet = nil
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

}

// MARK: - Copy From Day
private struct CopyFromDaySheet: View {
    let targetDate: Date

    @Environment(FoodStore.self) private var foodStore
    @Environment(\.dismiss) private var dismiss
    @State private var sourceDate: Date

    init(targetDate: Date) {
        self.targetDate = targetDate
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: targetDate) ?? targetDate
        _sourceDate = State(initialValue: previousDay)
    }

    private var mealGroups: [FoodLogMealGroup] {
        foodStore.entriesByMeal(for: sourceDate)
    }

    private var sourceEntries: [FoodEntry] {
        mealGroups.flatMap(\.entries)
    }

    private var targetDateText: String {
        if Calendar.current.isDateInToday(targetDate) {
            return "today"
        }
        return targetDate.formatted(.dateTime.month(.abbreviated).day())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Copy From", selection: $sourceDate, displayedComponents: .date)
                        .tint(AppColors.calorie)
                } footer: {
                    Text("Foods will be copied to \(targetDateText). The original entries stay unchanged.")
                }
                .listRowBackground(AppColors.appCard)

                if sourceEntries.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundStyle(AppColors.calorie.opacity(0.45))
                            Text("No foods logged on this day")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .listRowBackground(AppColors.appCard)
                } else {
                    Section {
                        Button {
                            copy(sourceEntries)
                        } label: {
                            Label("Copy All Foods", systemImage: "plus.circle.fill")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                        .tint(AppColors.calorie)
                    } footer: {
                        Text("\(sourceEntries.count) food\(sourceEntries.count == 1 ? "" : "s") will be added to \(targetDateText).")
                    }
                    .listRowBackground(AppColors.appCard)

                    ForEach(mealGroups) { group in
                        Section {
                            Button {
                                copy(group.entries)
                            } label: {
                                Label("Copy \(group.meal.displayName)", systemImage: "plus.circle")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                            .tint(AppColors.calorie)

                            ForEach(group.entries) { entry in
                                Button {
                                    copy([entry])
                                } label: {
                                    FoodRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Label(group.meal.displayName, systemImage: group.meal.icon)
                        }
                        .listRowBackground(AppColors.appCard)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationTitle("Copy from Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func copy(_ entries: [FoodEntry]) {
        guard !entries.isEmpty else { return }
        for entry in entries {
            let copiedTimestamp = timestamp(on: targetDate, preservingTimeFrom: entry.timestamp)
            let copiedEntry = entry.duplicatedForLogging(at: copiedTimestamp, mealType: entry.mealType)
            foodStore.addEntry(copiedEntry)
        }
        dismiss()
    }

    private func timestamp(on day: Date, preservingTimeFrom sourceTimestamp: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: sourceTimestamp)
        var components = DateComponents()
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        components.nanosecond = timeComponents.nanosecond
        return calendar.date(from: components) ?? day
    }
}

// MARK: - Open Food Facts Barcode Lookup
private enum OpenFoodFactsService {
    enum LookupError: LocalizedError {
        case invalidBarcode
        case productNotFound
        case missingNutrition
        case invalidResponse
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidBarcode:
                return "That barcode could not be read. Try scanning it again."
            case .productNotFound:
                return "Product not found in Open Food Facts. Scan the nutrition label instead."
            case .missingNutrition:
                return "This barcode was found, but nutrition data is incomplete. Scan the nutrition label instead."
            case .invalidResponse:
                return "Open Food Facts returned an unexpected response."
            case .networkError(let error):
                return "Barcode lookup failed: \(error.localizedDescription)"
            }
        }
    }

    static func lookup(barcode: String) async throws -> GeminiService.FoodAnalysis {
        let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty,
              let encodedCode = code.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(encodedCode).json")
        else {
            throw LookupError.invalidBarcode
        }

        components.queryItems = [
            URLQueryItem(
                name: "fields",
                value: "product_name,generic_name,brands,quantity,serving_size,serving_quantity,nutriments"
            )
        ]

        guard let url = components.url else { throw LookupError.invalidBarcode }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw LookupError.invalidResponse
            }

            let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            guard decoded.status != 0, let product = decoded.product else {
                throw LookupError.productNotFound
            }

            return try analysis(from: product, barcode: code)
        } catch let error as LookupError {
            throw error
        } catch {
            throw LookupError.networkError(error)
        }
    }

    private static var userAgent: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Voidpen/\(version) (https://voidpen.com)"
    }

    private static func analysis(from product: OpenFoodFactsProduct, barcode: String) throws -> GeminiService.FoodAnalysis {
        guard let nutriments = product.nutriments else { throw LookupError.missingNutrition }

        let servingGrams = max(
            product.servingQuantity?.value ?? grams(from: product.servingSize) ?? 100,
            1
        )
        let scale = servingGrams / 100

        let calories = servingValue("energy-kcal", in: nutriments, scale: scale)
            ?? servingValue("energy", in: nutriments, scale: scale).map { $0 * 0.23900573614 }
        let protein = servingValue("proteins", in: nutriments, scale: scale)
        let carbs = servingValue("carbohydrates", in: nutriments, scale: scale)
        let fat = servingValue("fat", in: nutriments, scale: scale)

        guard calories != nil || protein != nil || carbs != nil || fat != nil else {
            throw LookupError.missingNutrition
        }

        let name = productName(from: product, barcode: barcode)
        let servingOption = ServingUnitOption(unit: "serving", gramsPerUnit: servingGrams, quantity: 1)

        return GeminiService.FoodAnalysis(
            name: name,
            calories: Int(round(calories ?? 0)),
            protein: Int(round(protein ?? 0)),
            carbs: Int(round(carbs ?? 0)),
            fat: Int(round(fat ?? 0)),
            servingSizeGrams: servingGrams,
            emoji: "🏷️",
            sugar: rounded(servingValue("sugars", in: nutriments, scale: scale)),
            addedSugar: rounded(servingValue("added-sugars", in: nutriments, scale: scale)),
            fiber: rounded(servingValue("fiber", in: nutriments, scale: scale)),
            saturatedFat: rounded(servingValue("saturated-fat", in: nutriments, scale: scale)),
            monounsaturatedFat: rounded(servingValue("monounsaturated-fat", in: nutriments, scale: scale)),
            polyunsaturatedFat: rounded(servingValue("polyunsaturated-fat", in: nutriments, scale: scale)),
            cholesterol: milligrams(servingValue("cholesterol", in: nutriments, scale: scale)),
            sodium: milligrams(servingValue("sodium", in: nutriments, scale: scale)),
            potassium: milligrams(servingValue("potassium", in: nutriments, scale: scale)),
            servingUnitOptions: [servingOption],
            selectedServingUnit: servingOption.unit,
            selectedServingQuantity: 1
        )
    }

    private static func servingValue(_ key: String, in nutriments: OpenFoodFactsNutriments, scale: Double) -> Double? {
        if let serving = nutriments.value(for: "\(key)_serving") {
            return serving
        }
        if let per100g = nutriments.value(for: "\(key)_100g") {
            return per100g * scale
        }
        return nil
    }

    private static func productName(from product: OpenFoodFactsProduct, barcode: String) -> String {
        let primary = firstNonEmpty(product.productName, product.genericName)
        let brand = product.brands?
            .split(separator: ",")
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        if let primary, let brand, !primary.localizedCaseInsensitiveContains(brand) {
            return "\(brand) \(primary)"
        }
        return primary ?? brand ?? "Barcode \(barcode)"
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func rounded(_ value: Double?) -> Double? {
        value.map { round($0 * 10) / 10 }
    }

    private static func milligrams(_ grams: Double?) -> Double? {
        grams.map { round($0 * 1000 * 10) / 10 }
    }

    private static func grams(from servingSize: String?) -> Double? {
        guard var text = servingSize?.lowercased() else { return nil }
        text = text.replacingOccurrences(of: ",", with: ".")
        text = text.replacingOccurrences(of: "fl. oz", with: "fl oz")

        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*(fl oz|kg|mg|g|oz|ml|l)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let valueRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text),
              let value = Double(text[valueRange])
        else {
            return nil
        }

        switch String(text[unitRange]) {
        case "kg": return value * 1000
        case "mg": return value / 1000
        case "oz": return value * 28.3495
        case "fl oz": return value * 29.5735
        case "ml": return value
        case "l": return value * 1000
        default: return value
        }
    }

    private struct OpenFoodFactsResponse: Decodable {
        let status: Int?
        let product: OpenFoodFactsProduct?
    }

    private struct OpenFoodFactsProduct: Decodable {
        let productName: String?
        let genericName: String?
        let brands: String?
        let servingSize: String?
        let servingQuantity: FlexibleDouble?
        let nutriments: OpenFoodFactsNutriments?

        private enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case genericName = "generic_name"
            case brands
            case servingSize = "serving_size"
            case servingQuantity = "serving_quantity"
            case nutriments
        }
    }

    private struct OpenFoodFactsNutriments: Decodable {
        private let values: [String: Double]

        func value(for key: String) -> Double? {
            values[key]
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            var parsed: [String: Double] = [:]

            for key in container.allKeys {
                if let value = try? container.decode(FlexibleDouble.self, forKey: key) {
                    parsed[key.stringValue] = value.value
                }
            }

            values = parsed
        }
    }

    private struct FlexibleDouble: Decodable {
        let value: Double

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let double = try? container.decode(Double.self) {
                value = double
            } else if let int = try? container.decode(Int.self) {
                value = Double(int)
            } else {
                let string = try container.decode(String.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: ",", with: ".")
                guard let parsed = Double(string) else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a number")
                }
                value = parsed
            }
        }
    }

    private struct DynamicCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}


// MARK: - Nutrition Detail View
struct NutritionDetailView: View {
    let date: Date
    @Binding var homeTopNutrientsRaw: String
    @Environment(FoodStore.self) private var foodStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(OptionalNutrientGoals.storageKey) private var optionalNutrientGoalsData = Data()
    @State private var showHomeNutrientPicker = false

    private var userProfile: UserProfile { profileStore.profile }
    private var optionalNutrientGoals: OptionalNutrientGoals { OptionalNutrientGoals.decoded(from: optionalNutrientGoalsData) }
    private var homeTopNutrients: [HomeTopNutrient] { HomeTopNutrient.selection(from: homeTopNutrientsRaw) }
    private var homeTopNutrientNames: String {
        homeTopNutrients
            .map(\.displayName)
            .joined(separator: ", ")
    }

    var body: some View {
        let _ = profileStore.profile
        return NavigationStack {
            List {
                Section {
                    Button {
                        showHomeNutrientPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Label("Home Nutrient Cards", systemImage: "square.grid.3x1.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(homeTopNutrientNames)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(AppColors.appCard)

                Section("Macros") {
                    NutritionDetailRow(icon: "flame.fill", label: "Calories", value: "\(foodStore.calories(for: date))", unit: "kcal", goal: "\(userProfile.effectiveCalories)")
                    NutritionDetailRow(icon: "p.circle.fill", label: "Protein", value: "\(foodStore.protein(for: date))", unit: "g", goal: "\(userProfile.effectiveProtein)")
                    NutritionDetailRow(icon: "c.circle.fill", label: "Carbs", value: "\(foodStore.carbs(for: date))", unit: "g", goal: "\(userProfile.effectiveCarbs)")
                    NutritionDetailRow(icon: "f.circle.fill", label: "Fat", value: "\(foodStore.fat(for: date))", unit: "g", goal: "\(userProfile.effectiveFat)")
                }
                .listRowBackground(AppColors.appCard)

                Section("Detailed Nutrition") {
                    optionalNutritionRow(.sugar, value: foodStore.sugar(for: date))
                    optionalNutritionRow(.addedSugar, value: foodStore.addedSugar(for: date))
                    optionalNutritionRow(.fiber, value: foodStore.fiber(for: date))
                    optionalNutritionRow(.saturatedFat, value: foodStore.saturatedFat(for: date))
                    NutritionDetailRow(icon: "drop", label: "Mono Unsat. Fat", value: formatMicro(foodStore.monounsaturatedFat(for: date)), unit: "g")
                    NutritionDetailRow(icon: "drop.halffull", label: "Poly Unsat. Fat", value: formatMicro(foodStore.polyunsaturatedFat(for: date)), unit: "g")
                    optionalNutritionRow(.cholesterol, value: foodStore.cholesterol(for: date))
                    optionalNutritionRow(.sodium, value: foodStore.sodium(for: date))
                    optionalNutritionRow(.potassium, value: foodStore.potassium(for: date))
                }
                .listRowBackground(AppColors.appCard)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationTitle("Nutrition Details")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHomeNutrientPicker) {
                HomeNutrientPickerSheet(selectionRawValue: $homeTopNutrientsRaw)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(AppColors.calorie)
                }
            }
        }
    }

    private func formatMicro(_ value: Double) -> String {
        value == 0 ? "—" : String(format: "%.1f", value)
    }

    private func optionalNutritionRow(_ nutrient: OptionalNutrient, value: Double) -> some View {
        NutritionDetailRow(
            icon: nutrient.iconName,
            label: nutrient.displayName,
            value: formatMicro(value),
            unit: nutrient.unit,
            goal: "\(optionalNutrientGoals.goal(for: nutrient))"
        )
    }
}

struct NutritionDetailRow: View {
    var icon: String? = nil
    let label: String
    let value: String
    let unit: String
    var goal: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 24)
            }
            Text(label)
                .font(.system(.body, design: .rounded))
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppColors.calorie)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            if let goal {
                Text("/ \(goal)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Context Description Sheet
struct ContextDescriptionSheet: View {
    let image: UIImage?
    @Binding var description: String
    let onAnalyze: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppColors.calorie.opacity(0.15), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add context (optional)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("e.g. \"This is a half portion\" or \"Cooked in olive oil\"")
                                    .foregroundStyle(.tertiary)
                                    .font(.body)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 10)
                                    .allowsHitTesting(false)
                            }
                            TextField("", text: $description, axis: .vertical)
                                .font(.body)
                                .lineLimit(3...6)
                                .textFieldStyle(.plain)
                                .focused($isFocused)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 10)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }

                    Button {
                        onAnalyze()
                    } label: {
                        Text("Analyze")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.calorie)
                    .controlSize(.large)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

// MARK: - Camera View (UIKit wrapper)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var mode: CameraMode = .snapFood
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        picker.edgesForExtendedLayout = .all
        picker.showsCameraControls = false
        context.coordinator.picker = picker

        // Scale the camera preview so it fills the screen vertically.
        // Default UIImagePickerController preview is 4:3 (centered), leaving black bars
        // above & below — this aspect-fills the preview to remove them.
        let screenSize = UIScreen.main.bounds.size
        let nativePreviewHeight = screenSize.width * 4.0 / 3.0
        if nativePreviewHeight > 0 {
            let scale = screenSize.height / nativePreviewHeight
            if scale > 1 {
                picker.cameraViewTransform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }

        let coordinator = context.coordinator
        let overlay = CameraOverlayView(
            mode: mode,
            onCapture: { [weak coordinator] in coordinator?.capture() },
            onCancel: { [weak coordinator] in coordinator?.cancel() }
        )
        overlay.frame = UIScreen.main.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        picker.cameraOverlayView = overlay
        context.coordinator.overlay = overlay

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        weak var picker: UIImagePickerController?
        weak var overlay: CameraOverlayView?

        init(_ parent: CameraView) {
            self.parent = parent
        }

        @objc func capture() {
            overlay?.playCaptureFlash()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            picker?.takePicture()
        }

        @objc func cancel() {
            parent.dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera Overlay (UIKit)
final class CameraOverlayView: UIView {
    private let flashView = UIView()
    private let shutterInner = UIView()
    private let shutterInnerGradient = CAGradientLayer()
    private let cornerBracketsLayer = CAShapeLayer()
    private let onCapture: () -> Void
    private let onCancel: () -> Void

    init(mode: CameraMode, onCapture: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onCancel = onCancel
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        setUp()
    }

    @objc private func handleCapture() { onCapture() }
    @objc private func handleCancel() { onCancel() }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        shutterInnerGradient.frame = shutterInner.bounds
        shutterInnerGradient.cornerRadius = shutterInner.bounds.width / 2
        updateCornerBracketsPath()
    }

    private func updateCornerBracketsPath() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let side = min(bounds.width - 64, 340)
        let frame = CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2 - 48,
            width: side,
            height: side
        )
        let legLength: CGFloat = 36
        let cornerRadius: CGFloat = 28
        let path = UIBezierPath()

        // top-left
        path.move(to: CGPoint(x: frame.minX, y: frame.minY + cornerRadius + legLength))
        path.addLine(to: CGPoint(x: frame.minX, y: frame.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: frame.minX + cornerRadius, y: frame.minY),
                          controlPoint: CGPoint(x: frame.minX, y: frame.minY))
        path.addLine(to: CGPoint(x: frame.minX + cornerRadius + legLength, y: frame.minY))

        // top-right
        path.move(to: CGPoint(x: frame.maxX - cornerRadius - legLength, y: frame.minY))
        path.addLine(to: CGPoint(x: frame.maxX - cornerRadius, y: frame.minY))
        path.addQuadCurve(to: CGPoint(x: frame.maxX, y: frame.minY + cornerRadius),
                          controlPoint: CGPoint(x: frame.maxX, y: frame.minY))
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY + cornerRadius + legLength))

        // bottom-right
        path.move(to: CGPoint(x: frame.maxX, y: frame.maxY - cornerRadius - legLength))
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: frame.maxX - cornerRadius, y: frame.maxY),
                          controlPoint: CGPoint(x: frame.maxX, y: frame.maxY))
        path.addLine(to: CGPoint(x: frame.maxX - cornerRadius - legLength, y: frame.maxY))

        // bottom-left
        path.move(to: CGPoint(x: frame.minX + cornerRadius + legLength, y: frame.maxY))
        path.addLine(to: CGPoint(x: frame.minX + cornerRadius, y: frame.maxY))
        path.addQuadCurve(to: CGPoint(x: frame.minX, y: frame.maxY - cornerRadius),
                          controlPoint: CGPoint(x: frame.minX, y: frame.maxY))
        path.addLine(to: CGPoint(x: frame.minX, y: frame.maxY - cornerRadius - legLength))

        cornerBracketsLayer.frame = bounds
        cornerBracketsLayer.path = path.cgPath
    }

    // Empty regions of the overlay pass touches through to the camera preview;
    // only the actual controls (UIButtons) consume taps.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }

    func playCaptureFlash() {
        flashView.alpha = 0
        UIView.animate(withDuration: 0.08, animations: { [weak self] in
            self?.flashView.alpha = 0.85
        }, completion: { [weak self] _ in
            UIView.animate(withDuration: 0.28) { self?.flashView.alpha = 0 }
        })
    }

    private func setUp() {
        // 1) Full-screen capture flash overlay
        flashView.translatesAutoresizingMaskIntoConstraints = false
        flashView.backgroundColor = .white
        flashView.alpha = 0
        flashView.isUserInteractionEnabled = false
        addSubview(flashView)

        // Scan-frame corner brackets — short L-shaped strokes in brand primary color
        let bracketColor = UIColor(AppThemeColor.current.gradientColors.first ?? Color(hex: 0xFF375F))
        cornerBracketsLayer.fillColor = UIColor.clear.cgColor
        cornerBracketsLayer.strokeColor = bracketColor.cgColor
        cornerBracketsLayer.lineWidth = 5
        cornerBracketsLayer.lineCap = .round
        cornerBracketsLayer.lineJoin = .round
        cornerBracketsLayer.shadowColor = UIColor.black.cgColor
        cornerBracketsLayer.shadowOpacity = 0.28
        cornerBracketsLayer.shadowRadius = 6
        cornerBracketsLayer.shadowOffset = .zero
        layer.addSublayer(cornerBracketsLayer)

        // 2) Close X — glassy circular button, brand primary icon tint
        let closeBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        closeBlur.translatesAutoresizingMaskIntoConstraints = false
        closeBlur.isUserInteractionEnabled = false
        closeBlur.layer.cornerRadius = 26
        closeBlur.layer.masksToBounds = true
        closeBlur.layer.borderWidth = 0.5
        closeBlur.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        addSubview(closeBlur)

        let closeShadow = UIView()
        closeShadow.translatesAutoresizingMaskIntoConstraints = false
        closeShadow.backgroundColor = .clear
        closeShadow.isUserInteractionEnabled = false
        closeShadow.layer.shadowColor = UIColor.black.cgColor
        closeShadow.layer.shadowOpacity = 0.28
        closeShadow.layer.shadowRadius = 10
        closeShadow.layer.shadowOffset = CGSize(width: 0, height: 3)
        closeShadow.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 52, height: 52)).cgPath
        insertSubview(closeShadow, belowSubview: closeBlur)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = UIColor(AppThemeColor.current.gradientColors.first ?? Color(hex: 0xFF375F))
        closeButton.setImage(UIImage(systemName: "xmark",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)),
                             for: .normal)
        closeButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTouchDown), for: .touchDown)
        closeButton.addTarget(self, action: #selector(closeTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addSubview(closeButton)

        // 3) Shutter (white ring + brand-pink gradient inner) and tap target
        let shutterOuter = UIView()
        shutterOuter.translatesAutoresizingMaskIntoConstraints = false
        shutterOuter.backgroundColor = .clear
        shutterOuter.layer.borderWidth = 4
        shutterOuter.layer.borderColor = UIColor.white.cgColor
        shutterOuter.layer.cornerRadius = 38
        shutterOuter.isUserInteractionEnabled = false
        addSubview(shutterOuter)

        shutterInner.translatesAutoresizingMaskIntoConstraints = false
        shutterInner.backgroundColor = .clear
        shutterInner.layer.masksToBounds = true
        shutterInner.layer.cornerRadius = 30
        shutterInner.layer.borderWidth = 0.5
        shutterInner.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        shutterInner.isUserInteractionEnabled = false
        addSubview(shutterInner)

        shutterInnerGradient.colors = AppThemeColor.current.gradientColors.map { UIColor($0).cgColor }
        shutterInnerGradient.startPoint = CGPoint(x: 0, y: 0)
        shutterInnerGradient.endPoint = CGPoint(x: 1, y: 1)
        shutterInner.layer.insertSublayer(shutterInnerGradient, at: 0)

        let shutterButton = UIButton(type: .custom)
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.backgroundColor = .clear
        shutterButton.addTarget(self, action: #selector(handleCapture), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(shutterTouchDown), for: .touchDown)
        shutterButton.addTarget(self, action: #selector(shutterTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addSubview(shutterButton)

        NSLayoutConstraint.activate([
            // Flash — fills the entire overlay
            flashView.topAnchor.constraint(equalTo: topAnchor),
            flashView.bottomAnchor.constraint(equalTo: bottomAnchor),
            flashView.leadingAnchor.constraint(equalTo: leadingAnchor),
            flashView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Close X — sits in the camera controls row, left of the shutter
            closeBlur.centerYAnchor.constraint(equalTo: shutterOuter.centerYAnchor),
            closeBlur.trailingAnchor.constraint(equalTo: shutterOuter.leadingAnchor, constant: -36),
            closeBlur.widthAnchor.constraint(equalToConstant: 52),
            closeBlur.heightAnchor.constraint(equalToConstant: 52),

            closeShadow.centerXAnchor.constraint(equalTo: closeBlur.centerXAnchor),
            closeShadow.centerYAnchor.constraint(equalTo: closeBlur.centerYAnchor),
            closeShadow.widthAnchor.constraint(equalToConstant: 52),
            closeShadow.heightAnchor.constraint(equalToConstant: 52),

            closeButton.centerXAnchor.constraint(equalTo: closeBlur.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: closeBlur.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 52),
            closeButton.heightAnchor.constraint(equalToConstant: 52),

            // Shutter — bottom center
            shutterOuter.centerXAnchor.constraint(equalTo: centerXAnchor),
            shutterOuter.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -14),
            shutterOuter.widthAnchor.constraint(equalToConstant: 76),
            shutterOuter.heightAnchor.constraint(equalToConstant: 76),

            shutterInner.centerXAnchor.constraint(equalTo: shutterOuter.centerXAnchor),
            shutterInner.centerYAnchor.constraint(equalTo: shutterOuter.centerYAnchor),
            shutterInner.widthAnchor.constraint(equalToConstant: 60),
            shutterInner.heightAnchor.constraint(equalToConstant: 60),

            shutterButton.centerXAnchor.constraint(equalTo: shutterOuter.centerXAnchor),
            shutterButton.centerYAnchor.constraint(equalTo: shutterOuter.centerYAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 88),
            shutterButton.heightAnchor.constraint(equalToConstant: 88),
        ])

        self.shutterOuter = shutterOuter
        self.closeContainer = closeBlur
        self.closeShadowView = closeShadow
    }

    private weak var shutterOuter: UIView?
    private weak var closeContainer: UIView?
    private weak var closeShadowView: UIView?

    @objc private func shutterTouchDown() {
        UIView.animate(withDuration: 0.12,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction]) { [weak self] in
            self?.shutterOuter?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }

    @objc private func shutterTouchUp() {
        UIView.animate(withDuration: 0.22,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction]) { [weak self] in
            self?.shutterOuter?.transform = .identity
        }
    }

    @objc private func closeTouchDown() {
        UIView.animate(withDuration: 0.12,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction]) { [weak self] in
            let t = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self?.closeContainer?.transform = t
            self?.closeShadowView?.transform = t
        }
    }

    @objc private func closeTouchUp() {
        UIView.animate(withDuration: 0.22,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction]) { [weak self] in
            self?.closeContainer?.transform = .identity
            self?.closeShadowView?.transform = .identity
        }
    }
}


// MARK: - Food Camera (AVCapture — preview & saved crop share one geometry)

/// Full-screen camera for food / nutrition-label capture, built on AVCapture so
/// the live preview (`resizeAspectFill`) and the saved photo are cropped from the
/// SAME geometry — the result is provably what was framed. (UIImagePickerController's
/// preview is opaque and over-zooms, which made the saved image show more than the
/// preview.) Reuses `CameraOverlayView` for the shutter / close / brackets UI.
struct FoodCameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> FoodCameraViewController {
        let controller = FoodCameraViewController()
        controller.onImage = { captured in
            image = captured
            dismiss()
        }
        controller.onCancel = { dismiss() }
        return controller
    }

    func updateUIViewController(_ uiViewController: FoodCameraViewController, context: Context) {}
}

final class FoodCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onImage: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var overlay: CameraOverlayView?
    private let sessionQueue = DispatchQueue(label: "voidpen.food-camera.session")
    private var isConfigured = false
    /// Aspect (w/h) of the on-screen preview at the moment of capture — used to
    /// crop the photo to exactly the resizeAspectFill visible region.
    private var captureAspect: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildOverlay()
        checkCameraAccess()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func buildOverlay() {
        let overlay = CameraOverlayView(
            mode: .snapFood,
            onCapture: { [weak self] in self?.capturePhoto() },
            onCancel: { [weak self] in self?.onCancel?() }
        )
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        self.overlay = overlay
    }

    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureSession() } else { self?.onCancel?() }
                }
            }
        default:
            onCancel?()
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input),
                  self.session.canAddOutput(self.photoOutput) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.onCancel?() }
                return
            }
            self.session.addInput(input)
            self.session.addOutput(self.photoOutput)
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.frame = self.view.bounds
                Self.applyPortrait(previewLayer.connection)
                self.view.layer.insertSublayer(previewLayer, at: 0)
                self.previewLayer = previewLayer
                self.isConfigured = true
            }

            self.session.startRunning()
        }
    }

    /// Lock the connection to portrait so the preview and captured photo are upright.
    private static func applyPortrait(_ connection: AVCaptureConnection?) {
        guard let connection else { return }
        if #available(iOS 17.0, *) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    private func capturePhoto() {
        guard isConfigured else { return }
        let bounds = view.bounds
        captureAspect = bounds.height > 0 ? bounds.width / bounds.height : 0
        overlay?.playCaptureFlash()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Self.applyPortrait(photoOutput.connection(with: .video))
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async { [weak self] in self?.onCancel?() }
            return
        }
        // resizeAspectFill into the full-screen preview == aspect-fill the photo to
        // the screen, which is exactly what cropToPreview computes — so the saved
        // image matches the preview the user framed.
        let cropped = CameraPreviewCrop.cropToPreview(image, screenAspect: captureAspect)
        DispatchQueue.main.async { [weak self] in self?.onImage?(cropped) }
    }
}

// MARK: - Barcode Scanner
struct BarcodeScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        BarcodeScannerViewController(onScan: onScan, onCancel: onCancel)
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let onScan: (String) -> Void
    private let onCancel: () -> Void
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didScan = false

    init(onScan: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onScan = onScan
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildOverlay()
        checkCameraAccess()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let session = session
        DispatchQueue.global(qos: .userInitiated).async {
            session?.stopRunning()
        }
    }

    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.showCameraUnavailable("Camera access is needed to scan barcodes.")
                    }
                }
            }
        case .denied, .restricted:
            showCameraUnavailable("Camera access is needed to scan barcodes.")
        @unknown default:
            showCameraUnavailable("Camera is unavailable.")
        }
    }

    private func configureSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            session.commitConfiguration()
            showCameraUnavailable("Camera is unavailable.")
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            showCameraUnavailable("Barcode scanning is unavailable.")
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)

        let supportedTypes: [AVMetadataObject.ObjectType] = [
            .ean13,
            .ean8,
            .upce,
            .code128,
            .code39,
            .code93,
            .itf14,
            .interleaved2of5
        ]
        let availableTypes = supportedTypes.filter { output.availableMetadataObjectTypes.contains($0) }
        guard !availableTypes.isEmpty else {
            session.commitConfiguration()
            showCameraUnavailable("Barcode scanning is unavailable.")
            return
        }
        output.metadataObjectTypes = availableTypes
        session.commitConfiguration()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        self.session = session
        self.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func buildOverlay() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        let scanBox = UIView()
        scanBox.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        scanBox.layer.borderWidth = 3
        scanBox.layer.cornerRadius = 22
        scanBox.backgroundColor = UIColor.clear
        scanBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanBox)

        let label = UILabel()
        label.text = "Point the camera at the barcode"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let hint = UILabel()
        hint.text = "If the product is not found, scan the nutrition label instead."
        hint.textColor = UIColor.white.withAlphaComponent(0.72)
        hint.font = .systemFont(ofSize: 14, weight: .medium)
        hint.textAlignment = .center
        hint.numberOfLines = 0
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            scanBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanBox.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -34),
            scanBox.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.76),
            scanBox.heightAnchor.constraint(equalToConstant: 190),

            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            label.topAnchor.constraint(equalTo: scanBox.bottomAnchor, constant: 28),

            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            hint.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        ])
    }

    private func showCameraUnavailable(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    @objc private func cancelTapped() {
        onCancel()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didScan,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue,
              !code.isEmpty else { return }

        didScan = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let session = session
        DispatchQueue.global(qos: .userInitiated).async {
            session?.stopRunning()
        }
        onScan(code)
    }
}

// MARK: - Food Row
struct FoodRow: View {
    let entry: FoodEntry
    @Environment(FoodStore.self) private var foodStore

    private var servingText: String? {
        guard let grams = entry.servingSizeGrams else { return nil }
        let formatted = grams == grams.rounded() ? "\(Int(grams))" : String(format: "%.1f", grams)
        if let selectedUnit = entry.selectedServingUnit,
           let quantity = entry.selectedServingQuantity,
           quantity > 0 {
            let option = ServingUnitOption.option(matching: selectedUnit, in: entry.servingUnitOptions)
            if !option.isGramUnit {
                let quantityText = ServingUnitEditor.formatQuantity(quantity)
                return "\(quantityText) \(option.displayUnit(for: quantity)) (~\(formatted)g)"
            }
        }
        return "\(formatted)g"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppColors.calorie.opacity(0.15), lineWidth: 1)
                    )
            } else if let emoji = entry.emoji {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(AppColors.calorie)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    HStack(spacing: 4) {
                        Text(entry.name)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                        if foodStore.isFavorite(entry) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    Spacer()
                    Text(entry.timeString)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 6) {
                    Text("\(entry.calories) kcal")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppColors.calorie)

                    if let serving = servingText {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(serving)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    MacroPill(label: "P", value: entry.protein)
                    MacroPill(label: "C", value: entry.carbs)
                    MacroPill(label: "F", value: entry.fat)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MacroPill: View {
    let label: String
    let value: Int

    var body: some View {
        Text("\(label) \(value)g")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppColors.calorie.opacity(0.08), in: Capsule())
    }
}

// MARK: - Progress Tab
struct ProgressTabView: View {
    @Environment(FoodStore.self) private var foodStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(BodyFatStore.self) private var bodyFatStore
    @Environment(ProfileStore.self) private var profileStore
    @AppStorage("useMetric") private var useMetric = false
    @State private var timeRange: TimeRange = .week
    @State private var showLogWeight = false
    @State private var showLogBodyFat = false
    @State private var showGoalReached = false
    @State private var showAllWeights = false

    private var userProfile: UserProfile { profileStore.profile }

    private var dateRange: ClosedRange<Date> { timeRange.dateRange() }

    private var filteredWeightEntries: [WeightEntry] {
        weightStore.entries(in: dateRange)
    }

    private var filteredBodyFatEntries: [BodyFatEntry] {
        bodyFatStore.entries(in: dateRange)
    }

    /// Show the Body Fat section to anyone who has either logged a reading,
    /// set a current value (legacy users from before BodyFatStore existed —
    /// they won't have any entries yet but we still want to show the tracker
    /// + Log button so they can start), or set a goal. Hidden entirely for
    /// users who skipped the body-fat track in onboarding.
    private var showsBodyFatSection: Bool {
        !bodyFatStore.entries.isEmpty
            || userProfile.bodyFatPercentage != nil
            || userProfile.goalBodyFatPercentage != nil
    }

    private var dailyCalories: [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        let days = timeRange.days
        let today = calendar.startOfDay(for: .now)
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let cals = foodStore.calories(for: date)
            if cals == 0 { return nil }
            return (date: date, calories: cals)
        }.reversed()
    }

    private var macroAverages: (protein: Int, carbs: Int, fat: Int) {
        let calendar = Calendar.current
        let days = timeRange.days
        let today = calendar.startOfDay(for: .now)
        var totalP = 0, totalC = 0, totalF = 0, count = 0
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayEntries = foodStore.entries(for: date)
            if dayEntries.isEmpty { continue }
            totalP += dayEntries.reduce(0) { $0 + $1.protein }
            totalC += dayEntries.reduce(0) { $0 + $1.carbs }
            totalF += dayEntries.reduce(0) { $0 + $1.fat }
            count += 1
        }
        guard count > 0 else { return (0, 0, 0) }
        return (totalP / count, totalC / count, totalF / count)
    }

    var body: some View {
        let _ = profileStore.profile
        return NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Segmented Picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Weight / Body Fat Trend — single card with a segmented
                    // toggle (when the user has opted into body-fat tracking)
                    // or just the bare Weight chart (when they haven't, so the
                    // layout stays identical to v3.1 for those users).
                    BodyMetricsSection(
                        weightEntries: filteredWeightEntries,
                        goalWeightKg: userProfile.goalWeightKg,
                        currentWeightKg: weightStore.latestEntry?.weightKg,
                        onLogWeight: { showLogWeight = true },
                        bodyFatEntries: filteredBodyFatEntries,
                        goalBodyFatFraction: userProfile.goalBodyFatPercentage,
                        currentBodyFatFraction: bodyFatStore.latestEntry?.bodyFatFraction ?? userProfile.bodyFatPercentage,
                        onLogBodyFat: { showLogBodyFat = true },
                        bodyFatAvailable: showsBodyFatSection,
                        dateRange: timeRange == .allTime ? nil : dateRange
                    )
                    .padding(.horizontal)

                    // Weight History — tap to view/delete entries
                    if !weightStore.entries.isEmpty {
                        WeightHistoryLink(
                            totalCount: weightStore.entries.count,
                            onTap: { showAllWeights = true }
                        )
                        .padding(.horizontal)
                    }

                    // Calorie Trend
                    CalorieChartSection(
                        dailyCalories: dailyCalories,
                        calorieGoal: userProfile.effectiveCalories,
                        dateRange: timeRange == .allTime ? nil : dateRange
                    )
                    .padding(.horizontal)

                    // Macro Averages
                    MacroAveragesSection(
                        avgProtein: macroAverages.protein,
                        avgCarbs: macroAverages.carbs,
                        avgFat: macroAverages.fat,
                        proteinGoal: userProfile.effectiveProtein,
                        carbsGoal: userProfile.effectiveCarbs,
                        fatGoal: userProfile.effectiveFat
                    )
                    .padding(.horizontal)


                }
                .padding(.vertical)
            }
            .background(AppColors.appBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showLogWeight) {
                LogWeightSheet(
                    currentWeightKg: weightStore.latestEntry?.weightKg ?? userProfile.weightKg
                ) { weightKg, imageData in
                    let id = UUID()
                    var filename: String? = nil
                    if let imageData {
                        filename = WeightPhotoStore.shared.store(data: imageData, for: id)
                    }
                    weightStore.addEntry(WeightEntry(id: id, weightKg: weightKg, photoFilename: filename))
                }
            }
            .sheet(isPresented: $showLogBodyFat) {
                // Seed from latest entry → profile current → sane default,
                // mirroring the LogWeightSheet seeding chain.
                let seed = bodyFatStore.latestEntry?.bodyFatFraction
                    ?? userProfile.bodyFatPercentage
                    ?? 0.20
                LogBodyFatSheet(currentFraction: seed) { fraction in
                    bodyFatStore.addEntry(BodyFatEntry(bodyFatFraction: fraction))
                }
            }
            .alert("Congratulations!", isPresented: $showGoalReached) {
                Button("Keep Going", role: .cancel) { }
            } message: {
                Text("You've reached your goal weight! Head to Settings to switch your goal (Maintain, Lose, or Gain) and tap Recalculate Goals to refresh your targets.")
            }
            .onReceive(NotificationCenter.default.publisher(for: .weightGoalReached)) { _ in
                showGoalReached = true
            }
            .sheet(isPresented: $showAllWeights) {
                AllWeightHistoryView(
                    entries: weightStore.entries.sorted { $0.date > $1.date },
                    useMetric: useMetric,
                    onDelete: { entry in weightStore.deleteEntry(entry) }
                )
            }
        }
    }

}


struct ProfileView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(FoodStore.self) private var foodStore
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(HealthKitManager.self) private var healthKitManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(CloudSyncCoordinator.self) private var syncCoordinator: CloudSyncCoordinator?
    @Environment(\.dismiss) private var dismiss
    private var profile: UserProfile {
        get { profileStore.profile }
        nonmutating set { profileStore.profile = newValue }
    }
    private var profileBinding: Binding<UserProfile> {
        Binding(get: { profileStore.profile }, set: { profileStore.profile = $0 })
    }
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @AppStorage("useMetric") private var useMetric = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = false
    @AppStorage(AppThemeColor.storageKey) private var appThemeColorRaw = AppThemeColor.defaultColor.rawValue
    @AppStorage(AppLanguageSettings.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @State private var showLanguageRestartAlert = false

    enum ActiveSheet: String, Identifiable {
        case editBirthday, editHeight, editWeight, editBodyFat, editGoalBodyFat, editGoalWeight, editCalories, editProtein, editCarbs, editFat
        var id: String { rawValue }
    }
    @State private var activeSheet: ActiveSheet?
    @State private var showDeleteConfirmation = false
    @State private var showClearFoodLogConfirmation = false
    @State private var showRecalculateConfirm = false
    @State private var showCalculationMethods = false
    @State private var showInvalidGoalWeightAlert = false
    @State private var invalidGoalWeightMessage = ""
    @State private var showShareSheet = false

    private var appVersionDisplay: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }

    private var shareMessage: String {
        "Check out Voidpen — a calorie tracker that keeps your data on-device."
    }

    // Height formatting
    private var heightDisplay: String {
        if useMetric {
            return "\(Int(profile.heightCm)) cm"
        }
        let totalInches = profile.heightCm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches) % 12
        return "\(feet)'\(inches)\""
    }

    // Weight formatting
    private var weightDisplay: String {
        if useMetric {
            return String(format: "%.1f kg", profile.weightKg)
        }
        return String(format: "%.1f lbs", profile.weightKg * 2.20462)
    }

    // Birthday formatting
    private var birthdayDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: profile.birthday)) (age \(profile.age))"
    }

    // Goal weight display
    private var goalWeightDisplay: String {
        guard let gw = profile.goalWeightKg else { return "Not set" }
        if useMetric {
            return String(format: "%.1f kg", gw)
        }
        return String(format: "%.1f lbs", gw * 2.20462)
    }

    // Weekly change display
    private var weeklyChangeDisplay: String {
        let rate = profile.weeklyChangeKg ?? 0.5
        if useMetric {
            return String(format: "%.2f kg/week", rate)
        }
        return String(format: "%.1f lbs/week", rate * 2.20462)
    }

    private var selectedThemeColor: AppThemeColor {
        AppThemeColor.color(for: appThemeColorRaw)
    }

    private var settingsHeader: some View {
        ZStack {
            Text("Settings")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .tint(AppColors.calorie)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.appBackground)
    }

    var body: some View {
        NavigationStack {
            List {
                // Section 1: Personal Info
                Section("Personal Info") {
                    Picker(selection: profileBinding.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    } label: {
                        Label {
                            Text("Gender")
                        } icon: {
                            Image(systemName: profile.gender.icon)
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .onChange(of: profile.gender) { _, _ in resetCustomGoalsAndSave() }

                    ProfileInfoRow(icon: "birthday.cake", label: "Birthday", value: birthdayDisplay) {
                        activeSheet = .editBirthday
                    }

                    ProfileInfoRow(icon: "ruler", label: "Height", value: heightDisplay) {
                        activeSheet = .editHeight
                    }

                    ProfileInfoRow(icon: "scalemass", label: "Weight", value: weightDisplay) {
                        activeSheet = .editWeight
                    }

                    ProfileInfoRow(
                        icon: "percent",
                        label: "Body Fat",
                        value: profile.bodyFatPercentage != nil ? "\(Int(profile.bodyFatPercentage! * 100))%" : "Not set"
                    ) {
                        activeSheet = .editBodyFat
                    }

                    // Only surface the goal row to users who have a current
                    // body-fat value — feature was scoped to "skippable, no
                    // math impact, only visible if the user opted in to the
                    // body-fat track in onboarding (or set one later here)."
                    if profile.bodyFatPercentage != nil {
                        ProfileInfoRow(
                            icon: "target",
                            label: "Goal Body Fat",
                            value: profile.goalBodyFatPercentage != nil ? "\(Int(profile.goalBodyFatPercentage! * 100))%" : "Not set"
                        ) {
                            activeSheet = .editGoalBodyFat
                        }

                        // Toggle to disable Katch-McArdle without wiping the
                        // body-fat value — escape hatch for users whose
                        // reading is stale (weight shifted but they haven't
                        // re-measured). When off, BMR/TDEE/macros recompute
                        // from Mifflin-St Jeor (height/weight/age only).
                        Toggle(isOn: Binding(
                            get: { profile.useBodyFatInBMR ?? true },
                            set: { newValue in
                                profile.useBodyFatInBMR = newValue
                                resetCustomGoalsAndSave()
                            }
                        )) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use Body Fat for BMR")
                                    Text("On = Katch-McArdle (uses lean mass for a more accurate BMR). Off = Mifflin-St Jeor (height/weight/age only). Turn off if your body-fat reading is outdated.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "function")
                                    .foregroundStyle(AppColors.calorie)
                            }
                        }
                        .tint(AppColors.calorie)
                    }
                }
                .listRowBackground(AppColors.appCard)

                // Section 2: Goals & Nutrition
                Section("Goals & Nutrition") {
                    Picker(selection: profileBinding.goal) {
                        ForEach(WeightGoal.allCases, id: \.self) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    } label: {
                        Label {
                            Text("Weight Goal")
                        } icon: {
                            Image(systemName: profile.goal.icon)
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .onChange(of: profile.goal) { _, newValue in
                        if newValue == .maintain {
                            profile.weeklyChangeKg = nil
                            profile.goalWeightKg = nil
                        } else {
                            if profile.weeklyChangeKg == nil {
                                profile.weeklyChangeKg = 0.5
                            }
                            // Clear goal weight if it no longer matches the new direction
                            // (e.g., switching from Lose to Gain with an old target below current weight).
                            if let gw = profile.goalWeightKg {
                                let losingPastTarget = newValue == WeightGoal.lose && gw >= profile.weightKg
                                let gainingPastTarget = newValue == WeightGoal.gain && gw <= profile.weightKg
                                if losingPastTarget || gainingPastTarget {
                                    profile.goalWeightKg = nil
                                }
                            }
                        }
                        resetCustomGoalsAndSave()
                    }

                    Picker(selection: profileBinding.activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    } label: {
                        Label {
                            Text("Activity Level")
                        } icon: {
                            Image(systemName: profile.activityLevel.icon)
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .onChange(of: profile.activityLevel) { _, _ in resetCustomGoalsAndSave() }

                    if profile.goal != .maintain {
                        Picker(selection: Binding(
                            get: { profile.weeklyChangeKg ?? 0.5 },
                            set: { profile.weeklyChangeKg = $0; resetCustomGoalsAndSave() }
                        )) {
                            Text("Slow (0.25 kg/wk)").tag(0.25)
                            Text("Moderate (0.5 kg/wk)").tag(0.5)
                            Text("Fast (1.0 kg/wk)").tag(1.0)
                        } label: {
                            Label {
                                Text("Weekly Change")
                            } icon: {
                                Image(systemName: "gauge.with.dots.needle.33percent")
                                    .foregroundStyle(AppColors.calorie)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.secondary)

                        ProfileInfoRow(
                            icon: "flag.checkered",
                            label: "Goal Weight",
                            value: goalWeightDisplay
                        ) {
                            activeSheet = .editGoalWeight
                        }
                    }

                    ProfileInfoRow(icon: "flame", label: "Calories", value: "\(profile.effectiveCalories) kcal") {
                        activeSheet = .editCalories
                    }

                    macroRow(label: "Protein", icon: "p.circle", macro: .protein, value: profile.effectiveProtein, sheet: .editProtein)
                    macroRow(label: "Carbs", icon: "c.circle", macro: .carbs, value: profile.effectiveCarbs, sheet: .editCarbs)
                    macroRow(label: "Fat", icon: "f.circle", macro: .fat, value: profile.effectiveFat, sheet: .editFat)

                    NavigationLink {
                        OptionalNutrientGoalsSettingsView(profile: profile, useMetric: useMetric)
                    } label: {
                        Label {
                            HStack {
                                Text("Other Nutrients")
                                Spacer()
                                Text("Sugar, Fiber, Sodium")
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }

                    Button {
                        showRecalculateConfirm = true
                    } label: {
                        Label {
                            Text("Recalculate Goals")
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .tint(.primary)

                    Button {
                        showCalculationMethods = true
                    } label: {
                        Label {
                            Text("Calculation Methods")
                        } icon: {
                            Image(systemName: "book")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .tint(.primary)
                }
                .listRowBackground(AppColors.appCard)

                // Section 3: App Settings
                Section("App Settings") {
                    Picker(selection: $appearanceMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        Label {
                            Text("Appearance")
                        } icon: {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)

                    Picker(selection: $appLanguageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    } label: {
                        Label {
                            Text("App Language")
                        } icon: {
                            Image(systemName: "character.bubble")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .onChange(of: appLanguageRaw) { _, _ in
                        // AppleLanguages is read once at process start, so the
                        // override only takes effect on next launch. Apply it
                        // now so the relaunched process picks up the right
                        // localization, and prompt the user to restart.
                        AppLanguageSettings.applyToBundle()
                        showLanguageRestartAlert = true
                    }

                    NavigationLink {
                        ThemeColorSettingsView(selectedColorRaw: $appThemeColorRaw)
                    } label: {
                        Label {
                            HStack {
                                Text("Theme Color")
                                Spacer()
                                HStack(spacing: 8) {
                                    ThemeColorSwatch(themeColor: selectedThemeColor, size: 22)
                                    Text(selectedThemeColor.displayName)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "paintpalette.fill")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }

                    Toggle(isOn: $useMetric) {
                        Label {
                            Text("Metric Units")
                        } icon: {
                            Image(systemName: "ruler")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .tint(AppColors.calorie)

                    Picker(selection: $weekStartsOnMonday) {
                        Text("Sunday").tag(false)
                        Text("Monday").tag(true)
                    } label: {
                        Label {
                            Text("Week Starts On")
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label {
                            Text("Notifications")
                        } icon: {
                            Image(systemName: "bell")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                }
                .listRowBackground(AppColors.appCard)


                // Section 4: iCloud Sync
                if let syncCoordinator {
                    Section {
                        CloudSyncStatusRow(status: syncCoordinator.status)
                    } footer: {
                        Text("Your data syncs to your private iCloud.")
                    }
                    .listRowBackground(AppColors.appCard)
                }

                // Section 5: Health & Data
                Section("Health & Data") {
                    // Apple Health
                    HStack {
                        Label {
                            Text("Apple Health")
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                        }
                        Spacer()
                        Toggle("", isOn: $healthKitEnabled)
                            .labelsHidden()
                            .onChange(of: healthKitEnabled) { _, enabled in
                                handleHealthKitToggle(enabled)
                            }
                    }

                    // Clear Food Log
                    Button(role: .destructive) {
                        showClearFoodLogConfirmation = true
                    } label: {
                        Label {
                            Text("Clear Food Log")
                        } icon: {
                            Image(systemName: "fork.knife")
                        }
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)

                    // Delete All Data — always visible
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label {
                            Text("Delete All Data")
                        } icon: {
                            Image(systemName: "trash")
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(AppColors.appCard)

                // Section 6: About
                Section("About") {
                    HStack {
                        Label {
                            Text("App Version")
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppColors.calorie)
                        }
                        Spacer()
                        Text(appVersionDisplay)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        requestNativeReview()
                    } label: {
                        Label {
                            Text("Rate the App")
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .tint(.primary)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label {
                            Text("Share the App")
                        } icon: {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundStyle(AppColors.calorie)
                        }
                    }
                    .tint(.primary)
                }
                .listRowBackground(AppColors.appCard)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationBarHidden(true)
            .safeAreaInset(edge: .top, spacing: 0) { settingsHeader }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .editBirthday:
                    NavigationStack {
                        VStack(spacing: 20) {
                            Text("Birthday")
                                .font(.system(.title2, design: .rounded, weight: .bold))

                            DatePicker(
                                "Birthday",
                                selection: profileBinding.birthday,
                                in: ...Date.now,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()

                            Button {
                                saveProfile()
                                activeSheet = nil
                            } label: {
                                Text("Save")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal, 24)

                            Spacer()
                        }
                        .padding(.top, 24)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { activeSheet = nil }
                            }
                        }
                    }
                    .presentationDetents([.medium])

                case .editHeight:
                    HeightPickerSheet(
                        useMetric: useMetric,
                        currentHeightCm: profile.heightCm
                    ) { newHeight in
                        profile.heightCm = newHeight
                        resetCustomGoalsAndSave()
                    }

                case .editWeight:
                    WeightPickerSheet(
                        useMetric: useMetric,
                        currentWeightKg: profile.weightKg
                    ) { newWeight in
                        profile.weightKg = newWeight
                        // Invalidate goal weight if the new current weight makes the direction impossible.
                        if let gw = profile.goalWeightKg {
                            let mismatch = (profile.goal == .lose && gw >= newWeight)
                                        || (profile.goal == .gain && gw <= newWeight)
                            if mismatch { profile.goalWeightKg = nil }
                        }
                        resetCustomGoalsAndSave()
                        weightStore.addEntry(WeightEntry(weightKg: newWeight))
                    }

                case .editBodyFat:
                    BodyFatPickerSheet(
                        currentPercentage: profile.bodyFatPercentage
                    ) { newValue in
                        profile.bodyFatPercentage = newValue
                        // Goal body fat only makes sense alongside a current
                        // value — clear it whenever the current is cleared so
                        // a stale goal doesn't linger on a user who's opted out.
                        if newValue == nil { profile.goalBodyFatPercentage = nil }
                        resetCustomGoalsAndSave()
                    }

                case .editGoalBodyFat:
                    // Goal body fat is purely cosmetic — does NOT participate
                    // in BMR / TDEE / macro math. Use a plain saveProfile()
                    // path (not resetCustomGoalsAndSave) so editing the goal
                    // never silently wipes a user's pinned macros.
                    GoalBodyFatPickerSheet(
                        currentGoal: profile.goalBodyFatPercentage,
                        currentBodyFat: profile.bodyFatPercentage
                    ) { newValue in
                        profile.goalBodyFatPercentage = newValue
                        saveProfile()
                    }

                case .editGoalWeight:
                    WeightPickerSheet(
                        useMetric: useMetric,
                        currentWeightKg: profile.goalWeightKg ?? profile.weightKg
                    ) { newGoalWeight in
                        // Validate against current goal direction.
                        let invalid = (profile.goal == .lose && newGoalWeight >= profile.weightKg)
                                   || (profile.goal == .gain && newGoalWeight <= profile.weightKg)
                        if invalid {
                            invalidGoalWeightMessage = profile.goal == .lose
                                ? "A Lose goal needs a target below your current weight."
                                : "A Gain goal needs a target above your current weight."
                            showInvalidGoalWeightAlert = true
                            return
                        }
                        profile.goalWeightKg = newGoalWeight
                        saveProfile()
                    }

                case .editCalories:
                    NutritionPickerSheet(label: "Calories", unit: "kcal", currentValue: profile.effectiveCalories, range: 800...6000, step: 50) { value in
                        profile.customCalories = value
                        saveProfile()
                    }

                case .editProtein:
                    NutritionPickerSheet(
                        label: "Protein", unit: "g",
                        currentValue: profile.effectiveProtein,
                        range: 10...500, step: 5
                    ) { setMacro(.protein, to: $0) }

                case .editCarbs:
                    NutritionPickerSheet(
                        label: "Carbs", unit: "g",
                        currentValue: profile.effectiveCarbs,
                        range: 0...800, step: 5
                    ) { setMacro(.carbs, to: $0) }

                case .editFat:
                    NutritionPickerSheet(
                        label: "Fat", unit: "g",
                        currentValue: profile.effectiveFat,
                        range: 10...300, step: 5
                    ) { setMacro(.fat, to: $0) }

                }
            }
            .alert("Clear Food Log", isPresented: $showClearFoodLogConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All Logs", role: .destructive) {
                    foodStore.replaceAllEntries([])
                }
            } message: {
                Text("This will permanently delete all your logged food entries. Your profile, weight entries, and favorites will be kept. This action cannot be undone.")
            }
            .alert("Recalculate Goals", isPresented: $showRecalculateConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Recalculate") { recalculateGoalsNow() }
            } message: {
                Text("Recompute calories, protein, carbs, and fat from your current weight, activity, and goal? Your custom values will be replaced.")
            }
            .sheet(isPresented: $showCalculationMethods) {
                CalculationMethodsView()
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheet(activityItems: [shareMessage])
            }
            .alert("Invalid Goal Weight", isPresented: $showInvalidGoalWeightAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(invalidGoalWeightMessage)
            }
            .alert("Restart required", isPresented: $showLanguageRestartAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Quit and reopen the app to apply the new language.")
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    // Delete All Data does NOT touch Apple Health samples — that data is
                    // personal and belongs to the user, not this app's storage. If they
                    // want HK cleaned up they can do it from the Health app's
                    // Sources → Voidpen screen.
                    //
                    // The CloudKit zone delete must be enqueued and flushed BEFORE we
                    // clear local state, because `removePersistentDomain` below wipes
                    // `ckSyncEngineState` — clearing it first would orphan the pending
                    // delete. We therefore run the whole wipe inside a Task so we can
                    // `await` the zone delete first; without the server-side delete the
                    // data would re-download from iCloud after re-onboarding. If
                    // `syncCoordinator` is nil (sync never started), the wipe is
                    // local-only — that's fine.
                    Task { @MainActor in
                        await syncCoordinator?.deleteAllCloudData()

                        foodStore.replaceAllEntries([])
                        weightStore.replaceAllEntries([])
                        // Wipe the food-image folder defensively — replaceAllEntries
                        // already cleans per-entry files, but a belt-and-braces
                        // deleteAll catches any orphans from earlier crash recovery.
                        FoodImageStore.shared.deleteAll()
                        WeightPhotoStore.shared.deleteAll()
                        // Cancel all notifications
                        notificationManager.cancelAllNotifications()
                        // Wipe all persisted data (this also clears ckSyncEngineState).
                        let domain = Bundle.main.bundleIdentifier ?? ""
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        chatStore.reset()
                        // Wipe the widget snapshot out of the App Group container —
                        // it lives outside UserDefaults.standard and would otherwise
                        // keep showing the previous profile's numbers on the widget.
                        WidgetSnapshot.clear()
                        WidgetCenter.shared.reloadAllTimelines()
                        hasCompletedOnboarding = false
                    }
                }
            } message: {
                Text("This will permanently delete all your data including food logs, weight entries, and profile. This action cannot be undone.")
            }
        }
    }

    private func saveProfile() {
        profile.save()
    }

    private func requestNativeReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }

    /// Clear all custom goal overrides so calories + macros recompute from the current
    /// weight / activity / goal formulas. Triggered automatically when those underlying
    /// inputs change (gender, activity, weight, etc.) and via the Recalculate button.
    private func resetCustomGoalsAndSave() {
        profile.recalculateGoalsFromFormulas()
        saveProfile()
    }

    @ViewBuilder
    private func macroRow(label: String, icon: String, macro: AutoBalanceMacro, value: Int, sheet: ActiveSheet) -> some View {
        Button {
            activeSheet = sheet
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.calorie)
                    .frame(width: 22)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(value)g")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func setMacro(_ macro: AutoBalanceMacro, to value: Int?) {
        switch macro {
        case .protein: profile.customProtein = value
        case .carbs:   profile.customCarbs   = value
        case .fat:     profile.customFat     = value
        }
        saveProfile()
    }

    private func recalculateGoalsNow() {
        profile.recalculateGoalsFromFormulas()
        saveProfile()
    }

    private func handleHealthKitToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let authorized = await healthKitManager.requestAuthorization()
                if authorized {
                    healthKitManager.writeWeight(kg: profile.weightKg, date: .now)
                    healthKitManager.writeHeight(cm: profile.heightCm)
                    if let bf = profile.bodyFatPercentage {
                        healthKitManager.writeBodyFat(fraction: bf)
                    }
                    let measurements = await healthKitManager.fetchLatestBodyMeasurements()
                    if let kg = measurements.weight, abs(profile.weightKg - kg) > 0.01 {
                        profile.weightKg = kg
                    }
                    if let cm = measurements.height, abs(profile.heightCm - cm) > 0.1 {
                        profile.heightCm = cm
                    }
                    if let bf = measurements.bodyFat {
                        profile.bodyFatPercentage = bf
                    }
                    if let dob = measurements.dob {
                        profile.birthday = dob
                    }
                    if let sex = measurements.sex {
                        switch sex {
                        case .male: profile.gender = .male
                        case .female: profile.gender = .female
                        default: break
                        }
                    }
                    saveProfile()
                    healthKitManager.startBodyMeasurementObserver()
                    healthKitManager.backfillNutritionIfNeeded(
                        entries: foodStore.entries,
                        currentEntryIDs: { Set(foodStore.entries.map(\.id)) }
                    )
                } else {
                    healthKitEnabled = false
                }
            }
        } else {
            healthKitManager.stopObserver()
        }
    }

}

// UIActivityViewController wrapper. SwiftUI's ShareLink message arg gets
// dropped by most share targets — UIActivityViewController forwards every
// activity item, so the share-the-app message reaches Messages, Mail, etc.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct ThemeColorSettingsView: View {
    @Binding var selectedColorRaw: String

    private var selectedColor: AppThemeColor {
        AppThemeColor.color(for: selectedColorRaw)
    }

    var body: some View {
        List {
            Section {
                ForEach(AppThemeColor.allCases) { themeColor in
                    Button {
                        selectedColorRaw = themeColor.rawValue
                    } label: {
                        HStack(spacing: 14) {
                            ThemeColorSwatch(themeColor: themeColor, size: 30)
                            Text(themeColor.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedColor == themeColor {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.calorie)
                            }
                        }
                    }
                    .tint(.primary)
                }
            } footer: {
                Text("Changes the main app color and home screen icon used for tabs, buttons, icons, charts, and progress rings.")
            }
            .listRowBackground(AppColors.appCard)
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.appBackground)
        .navigationTitle("Theme Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ThemeColorSwatch: View {
    let themeColor: AppThemeColor
    var size: CGFloat = 24

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: themeColor.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: themeColor.color.opacity(0.28), radius: 4, y: 2)
    }
}

// MARK: - AI Consent Sheet (Apple Guideline 5.1.1(i) + 5.1.2(i))
/// Disclosed-and-explicit consent before any user data is sent to a third-party
/// AI provider. Apple App Review (April 2026) rejected v3.2 (5) for not having
/// in-app consent — privacy policy alone is not sufficient. The sheet names the
/// currently selected provider, lists what data gets sent, and requires an
/// explicit Allow tap before any food analysis call can fire.
struct AIConsentSheetView: View {
    let onAllow: () -> Void
    let onCancel: () -> Void

    private var providerName: String {
        "Voidpen Premium"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 88, height: 88)
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                    .padding(.top, 28)

                    VStack(spacing: 8) {
                        Text("AI Analysis Notice")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text("Before Voidpen sends data to a third-party AI provider, we need your permission.")
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        consentRow(icon: "photo.fill", title: "What is sent",
                                   text: "When you log a meal, the photo, voice audio or transcript, or text description is sent to your selected AI provider. Profile data (age, weight, goals) is sent only for Coach chat.")
                        consentRow(icon: "network", title: "Who receives it",
                                   text: "Requests are sent through Voidpen's secure backend, which forwards them to the configured AI provider. Your API keys are never stored on this device.")
                        consentRow(icon: "lock.shield.fill", title: "What stays local",
                                   text: "Your saved food log, weight history, and body fat history stay on this device. Only the active AI request is sent for processing.")
                    }
                    .padding(.horizontal, 20)

                    Text("Tap Allow to enable AI food analysis. Manual entry is always available without sending data anywhere. You can revoke consent later by deleting the app or via Settings → Delete All Data.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    Link("View privacy policy", destination: URL(string: "https://voidpen.com/privacy.html")!)
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.calorie)
                }
                .padding(.bottom, 24)
            }

            VStack(spacing: 10) {
                Button(action: onAllow) {
                    Text("Allow")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                Button(action: onCancel) {
                    Text("Not Now")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(.ultraThinMaterial)
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
    }

    private func consentRow(icon: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.calorie)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(text)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(FoodStore())
        .environment(WeightStore())
}
