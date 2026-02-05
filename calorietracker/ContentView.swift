import SwiftUI
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
    @State private var showAnalyzing = false
    @State private var showFoodResult = false
    @State private var showServingSize = false
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var currentFoodResult: GeminiService.FoodAnalysis?
    @State private var currentLabelResult: GeminiService.NutritionLabelAnalysis?
    @State private var currentImage: UIImage?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WeekSelectorView()
                }

                Section("Calories") {
                    CalorieRow(eaten: foodStore.todayCalories, goal: 2500)
                }

                Section("Log Food") {
                    HStack(spacing: 12) {
                        Button(action: {
                            cameraMode = .snapFood
                            showCamera = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Snap Food")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)

                        Button(action: {
                            cameraMode = .nutritionLabel
                            showCamera = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "text.viewfinder")
                                    .font(.title2)
                                Text("Nutrition Label")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Macros") {
                    MacroRow(name: "Protein", current: foodStore.todayProtein, goal: 150, unit: "g", color: .orange)
                    MacroRow(name: "Carbs", current: foodStore.todayCarbs, goal: 275, unit: "g", color: .yellow)
                    MacroRow(name: "Fat", current: foodStore.todayFat, goal: 70, unit: "g", color: .blue)
                }

                Section("Recently uploaded") {
                    if foodStore.todayEntries.isEmpty {
                        Text("No foods logged today")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(foodStore.todayEntries) { entry in
                            FoodRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Cal AI")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("15")
                            .fontWeight(.semibold)
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
            .sheet(isPresented: $showAnalyzing) {
                if let image = currentImage {
                    AnalyzingView(image: image)
                        .interactiveDismissDisabled()
                }
            }
            .sheet(isPresented: $showFoodResult) {
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
            .sheet(isPresented: $showServingSize) {
                if let image = currentImage, let labelResult = currentLabelResult {
                    ServingSizeInputView(
                        image: image,
                        labelAnalysis: labelResult,
                        onContinue: { scaled in
                            showServingSize = false
                            currentFoodResult = scaled
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showFoodResult = true
                            }
                        }
                    )
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
        showAnalyzing = true

        Task {
            do {
                switch mode {
                case .snapFood:
                    let result = try await GeminiService.analyzeFood(image: image)
                    showAnalyzing = false
                    currentFoodResult = result
                    try? await Task.sleep(for: .milliseconds(300))
                    showFoodResult = true

                case .nutritionLabel:
                    let result = try await GeminiService.analyzeNutritionLabel(image: image)
                    showAnalyzing = false
                    currentLabelResult = result
                    try? await Task.sleep(for: .milliseconds(300))
                    showServingSize = true
                }
            } catch {
                showAnalyzing = false
                errorMessage = error.localizedDescription
                try? await Task.sleep(for: .milliseconds(300))
                showError = true
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entries = foodStore.todayEntries
        for index in offsets {
            foodStore.deleteEntry(entries[index])
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

// MARK: - Week Selector View
struct WeekSelectorView: View {
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let dates = [10, 11, 12, 13, 14, 15, 16]
    @State private var selectedIndex = 3

    var body: some View {
        HStack {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 4) {
                    Text(days[index])
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(dates[index])")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(index == selectedIndex ? .white : .primary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(index == selectedIndex ? Color.accentColor : Color.clear)
                        )
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    selectedIndex = index
                }
            }
        }
    }
}

// MARK: - Calorie Row
struct CalorieRow: View {
    let eaten: Int
    let goal: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(eaten) / \(goal)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Calories eaten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Gauge(value: Double(eaten), in: 0...Double(goal)) {
                Image(systemName: "flame.fill")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.primary)
        }
    }
}

// MARK: - Macro Row
struct MacroRow: View {
    let name: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Label(name, systemImage: "circle.fill")
                .foregroundStyle(color)

            Spacer()

            Text("\(current)/\(goal)\(unit)")
                .foregroundStyle(.secondary)

            Gauge(value: Double(current), in: 0...Double(goal)) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(color)
            .frame(width: 60)
        }
    }
}

// MARK: - Food Row
struct FoodRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .font(.title)
                    .frame(width: 44, height: 44)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading) {
                Text(entry.name)
                    .fontWeight(.medium)
                Label("\(entry.calories) cal", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.timeString)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Placeholder Views for Other Tabs
struct ProgressTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Weight") {
                    LabeledContent("Current", value: "132.1 lbs")
                    LabeledContent("Goal", value: "140 lbs")
                }

                Section("Statistics") {
                    LabeledContent("Daily Average", value: "2861 cal")
                    LabeledContent("Weekly Average", value: "2750 cal")
                }
            }
            .navigationTitle("Progress")
        }
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No groups yet")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Groups")
        }
    }
}

struct ProfileView: View {
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

                Section("Settings") {
                    Label("Notifications", systemImage: "bell")
                    Label("Goals", systemImage: "target")
                    Label("Units", systemImage: "scalemass")
                }

                Section {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
        .environment(FoodStore())
}
