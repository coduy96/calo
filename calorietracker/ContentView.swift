import SwiftUI
import PhotosUI
import UIKit

// MARK: - Camera Mode
enum CameraMode {
    case snapFood
    case nutritionLabel
}

// MARK: - Main Content View
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            ProgressTabView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }

            GroupsView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Groups")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
        }
    }
}

// MARK: - Home View (Main Dashboard)
struct HomeView: View {
    @Environment(FoodStore.self) private var foodStore
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var cameraMode: CameraMode = .snapFood
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedDate: Date = .now

    enum ActiveSheet: String, Identifiable {
        case analyzing, foodResult
        var id: String { rawValue }
    }
    @State private var activeSheet: ActiveSheet?

    @State private var currentFoodResult: GeminiService.FoodAnalysis?
    @State private var currentImage: UIImage?

    private var userProfile: UserProfile { UserProfile.load() ?? .default }
    private var calorieGoal: Int { userProfile.effectiveCalories }
    private var proteinGoal: Int { userProfile.effectiveProtein }
    private var carbsGoal: Int { userProfile.effectiveCarbs }
    private var fatGoal: Int { userProfile.effectiveFat }
    private var selectedCalories: Int { foodStore.calories(for: selectedDate) }
    private var caloriesRemaining: Int { max(calorieGoal - selectedCalories, 0) }
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    private var navigationTitle: String {
        if isToday { return "Today" }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        NavigationStack {
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
                }

                // Calorie hero
                Section {
                    VStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(selectedCalories)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .contentTransition(.numericText())
                                .animation(.snappy, value: selectedCalories)

                            Text("of \(calorieGoal) kcal")
                                .font(.system(.callout, design: .rounded, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.calorie.opacity(0.10))
                                    .frame(height: 10)

                                Capsule()
                                    .fill(LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(10, geo.size.width * min(Double(selectedCalories) / Double(calorieGoal), 1.0)), height: 10)
                                    .shadow(color: AppColors.calorie.opacity(0.35), radius: 8, y: 3)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: selectedCalories)
                            }
                        }
                        .frame(height: 10)
                        .padding(.horizontal, 24)

                        Text("\(caloriesRemaining) left")
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Macro trio
                Section {
                    HStack(spacing: 20) {
                        MacroCard(label: "Protein", current: foodStore.protein(for: selectedDate), goal: proteinGoal, gradientColors: AppColors.proteinGradient)
                        MacroCard(label: "Carbs", current: foodStore.carbs(for: selectedDate), goal: carbsGoal, gradientColors: AppColors.carbsGradient)
                        MacroCard(label: "Fat", current: foodStore.fat(for: selectedDate), goal: fatGoal, gradientColors: AppColors.fatGradient)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Food list
                let mealGroups = foodStore.entriesByMeal(for: selectedDate)
                if mealGroups.isEmpty {
                    Section(isToday ? "Today's Food" : "Food Log") {
                        Text("No foods logged")
                            .foregroundStyle(.secondary)
                            .listRowBackground(AppColors.appCard)
                    }
                } else {
                    ForEach(mealGroups, id: \.meal) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                FoodRow(entry: entry)
                                    .listRowBackground(AppColors.appCard)
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    foodStore.deleteEntry(group.entries[index])
                                }
                            }
                        } header: {
                            Label(group.meal.displayName, systemImage: group.meal.icon)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .animation(.snappy, value: selectedDate)
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            cameraMode = .snapFood
                            showCamera = true
                        }) {
                            Label("Camera", systemImage: "camera.fill")
                        }
                        Button(action: {
                            cameraMode = .nutritionLabel
                            showCamera = true
                        }) {
                            Label("Nutrition Label", systemImage: "text.viewfinder")
                        }
                        Button(action: { showPhotoPicker = true }) {
                            Label("From Photos", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedImage) { oldValue, newValue in
                guard let image = newValue else { return }
                capturedImage = nil
                currentImage = image
                startAnalysis(image: image, mode: cameraMode)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .analyzing:
                    if let image = currentImage {
                        AnalyzingView(image: image)
                    }
                case .foodResult:
                    if let image = currentImage, let result = currentFoodResult {
                        FoodResultView(
                            image: image,
                            source: cameraMode == .snapFood ? .snapFood : .nutritionLabel,
                            name: result.name,
                            calories: result.calories,
                            protein: result.protein,
                            carbs: result.carbs,
                            fat: result.fat,
                            onLog: { entry in
                                foodStore.addEntry(entry)
                            }
                        )
                    }
                }
            }
            .interactiveDismissDisabled(activeSheet == .analyzing)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                guard let item = newValue else { return }
                selectedPhotoItem = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        currentImage = image
                        activeSheet = .analyzing
                        do {
                            let result = try await GeminiService.autoAnalyze(image: image)
                            currentFoodResult = result
                            activeSheet = .foodResult
                        } catch {
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
        }
    }

    private func startAnalysis(image: UIImage, mode: CameraMode) {
        activeSheet = .analyzing

        Task {
            do {
                switch mode {
                case .snapFood:
                    let result = try await GeminiService.analyzeFood(image: image)
                    currentFoodResult = result
                    activeSheet = .foodResult

                case .nutritionLabel:
                    let label = try await GeminiService.analyzeNutritionLabel(image: image)
                    let servingGrams = label.servingSizeGrams ?? 100
                    currentFoodResult = label.scaled(to: servingGrams)
                    activeSheet = .foodResult
                }
            } catch {
                activeSheet = nil
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

}


// MARK: - Camera View (UIKit wrapper)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        picker.edgesForExtendedLayout = .all
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
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

// MARK: - Food Row
struct FoodRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {
            if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "photo")
                    .font(.title)
                    .frame(width: 64, height: 64)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text(entry.timeString)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text("\(entry.calories) cal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    MacroPill(label: "P", value: entry.protein, color: AppColors.protein)
                    MacroPill(label: "C", value: entry.carbs, color: AppColors.carbs)
                    MacroPill(label: "F", value: entry.fat, color: AppColors.fat)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MacroPill: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        Text("\(label): \(value)g")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Progress Tab
struct ProgressTabView: View {
    @Environment(FoodStore.self) private var foodStore
    @Environment(WeightStore.self) private var weightStore
    @State private var timeRange: TimeRange = .week
    @State private var showLogWeight = false

    private var userProfile: UserProfile { UserProfile.load() ?? .default }

    private var dateRange: ClosedRange<Date> { timeRange.dateRange() }

    private var filteredWeightEntries: [WeightEntry] {
        weightStore.entries(in: dateRange)
    }

    private var dailyCalories: [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        let days = timeRange.days ?? {
            guard let earliest = foodStore.entries.map({ $0.timestamp }).min() else { return 7 }
            return max(calendar.dateComponents([.day], from: earliest, to: .now).day ?? 7, 1)
        }()
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
        let days = timeRange.days ?? {
            guard let earliest = foodStore.entries.map({ $0.timestamp }).min() else { return 7 }
            return max(calendar.dateComponents([.day], from: earliest, to: .now).day ?? 7, 1)
        }()
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

    private var streak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var count = 0
        var day = today
        while true {
            let dayEntries = foodStore.entries(for: day)
            if dayEntries.isEmpty { break }
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    private var bestStreak: Int {
        let calendar = Calendar.current
        guard let earliest = foodStore.entries.map({ $0.timestamp }).min() else { return 0 }
        let start = calendar.startOfDay(for: earliest)
        let today = calendar.startOfDay(for: .now)
        let totalDays = max(calendar.dateComponents([.day], from: start, to: today).day ?? 0, 0) + 1

        var best = 0, current = 0
        for offset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if !foodStore.entries(for: date).isEmpty {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private var daysOnTarget: Int {
        let calendar = Calendar.current
        let goal = Double(userProfile.effectiveCalories)
        let days = timeRange.days ?? {
            guard let earliest = foodStore.entries.map({ $0.timestamp }).min() else { return 7 }
            return max(calendar.dateComponents([.day], from: earliest, to: .now).day ?? 7, 1)
        }()
        let today = calendar.startOfDay(for: .now)
        var count = 0
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let cals = Double(foodStore.calories(for: date))
            if cals > 0 && goal > 0 && abs(cals - goal) / goal <= 0.10 {
                count += 1
            }
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Segmented Picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Weight Trend
                    WeightChartSection(
                        weightEntries: filteredWeightEntries,
                        goalWeightLbs: nil,
                        currentWeightLbs: weightStore.latestEntry?.weightLbs,
                        onLogWeight: { showLogWeight = true }
                    )
                    .padding(.horizontal)

                    // Calorie Trend
                    CalorieChartSection(
                        dailyCalories: dailyCalories,
                        calorieGoal: userProfile.effectiveCalories
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

                    // Streaks & Stats
                    StatsSection(
                        streak: streak,
                        daysOnTarget: daysOnTarget,
                        totalEntries: foodStore.entries.count,
                        bestStreak: bestStreak
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppColors.appBackground)
            .navigationTitle("Progress")
            .sheet(isPresented: $showLogWeight) {
                LogWeightSheet(
                    currentWeightLbs: weightStore.latestEntry?.weightLbs ?? userProfile.weightKg * 2.20462
                ) { weightKg in
                    let entry = WeightEntry(weightKg: weightKg)
                    weightStore.addEntry(entry)
                }
            }
        }
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No groups yet")
                    .foregroundStyle(.secondary)
                    .listRowBackground(AppColors.appCard)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationTitle("Groups")
        }
    }
}

struct ProfileView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text("User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("user@email.com")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(AppColors.appCard)

                Section("Settings") {
                    Label("Notifications", systemImage: "bell")
                    Label("Goals", systemImage: "target")
                    Picker(selection: $appearanceMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.menu)
                }
                .listRowBackground(AppColors.appCard)

                Section {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                }
                .listRowBackground(AppColors.appCard)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
        .environment(FoodStore())
        .environment(WeightStore())
}
