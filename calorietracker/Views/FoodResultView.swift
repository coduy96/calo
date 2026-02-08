import SwiftUI

struct FoodResultView: View {
    let image: UIImage?
    let source: FoodSource

    @State var name: String
    @State var calories: Int
    @State var protein: Int
    @State var carbs: Int
    @State var fat: Int
    @State var mealType: MealType = .snack

    var onLog: (FoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    init(
        image: UIImage?,
        source: FoodSource,
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        onLog: @escaping (FoodEntry) -> Void
    ) {
        self.image = image
        self.source = source
        self._name = State(initialValue: name)
        self._calories = State(initialValue: calories)
        self._protein = State(initialValue: protein)
        self._carbs = State(initialValue: carbs)
        self._fat = State(initialValue: fat)
        self.onLog = onLog
    }

    var body: some View {
        NavigationStack {
            List {
                if let image {
                    Section {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Food Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Food name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Nutrition") {
                    NutritionField(label: "Calories", value: $calories, unit: "kcal")
                    NutritionField(label: "Protein", value: $protein, unit: "g")
                    NutritionField(label: "Carbs", value: $carbs, unit: "g")
                    NutritionField(label: "Fat", value: $fat, unit: "g")
                }

                Section("Meal") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Label(meal.displayName, systemImage: meal.icon)
                                .tag(meal)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.calorie)
                }

                Section {
                    Button(action: logFood) {
                        Text("Log Food")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.calorie)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Review Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func logFood() {
        let entry = FoodEntry(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            imageData: image?.jpegData(compressionQuality: 0.5),
            source: source,
            mealType: mealType
        )
        onLog(entry)
        dismiss()
    }
}

struct NutritionField: View {
    let label: String
    @Binding var value: Int
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}
