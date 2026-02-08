import SwiftUI

struct FoodResultView: View {
    let image: UIImage?
    let emoji: String?
    let source: FoodSource

    @State var name: String
    @State var calories: Int
    @State var protein: Int
    @State var carbs: Int
    @State var fat: Int
    @State var mealType: MealType = .snack

    @State var sugar: Double?
    @State var addedSugar: Double?
    @State var fiber: Double?
    @State var saturatedFat: Double?
    @State var monounsaturatedFat: Double?
    @State var polyunsaturatedFat: Double?
    @State var cholesterol: Double?
    @State var sodium: Double?
    @State var potassium: Double?

    var onLog: (FoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    init(
        image: UIImage?,
        emoji: String? = nil,
        source: FoodSource,
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        sugar: Double? = nil,
        addedSugar: Double? = nil,
        fiber: Double? = nil,
        saturatedFat: Double? = nil,
        monounsaturatedFat: Double? = nil,
        polyunsaturatedFat: Double? = nil,
        cholesterol: Double? = nil,
        sodium: Double? = nil,
        potassium: Double? = nil,
        onLog: @escaping (FoodEntry) -> Void
    ) {
        self.image = image
        self.emoji = emoji
        self.source = source
        self._name = State(initialValue: name)
        self._calories = State(initialValue: calories)
        self._protein = State(initialValue: protein)
        self._carbs = State(initialValue: carbs)
        self._fat = State(initialValue: fat)
        self._sugar = State(initialValue: sugar)
        self._addedSugar = State(initialValue: addedSugar)
        self._fiber = State(initialValue: fiber)
        self._saturatedFat = State(initialValue: saturatedFat)
        self._monounsaturatedFat = State(initialValue: monounsaturatedFat)
        self._polyunsaturatedFat = State(initialValue: polyunsaturatedFat)
        self._cholesterol = State(initialValue: cholesterol)
        self._sodium = State(initialValue: sodium)
        self._potassium = State(initialValue: potassium)
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
                } else if let emoji {
                    Section {
                        HStack {
                            Spacer()
                            Text(emoji)
                                .font(.system(size: 80))
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

                Section {
                    DisclosureGroup("More Nutrition") {
                        OptionalNutritionField(label: "Sugar", value: $sugar, unit: "g")
                        OptionalNutritionField(label: "Added Sugar", value: $addedSugar, unit: "g")
                        OptionalNutritionField(label: "Fiber", value: $fiber, unit: "g")
                        OptionalNutritionField(label: "Saturated Fat", value: $saturatedFat, unit: "g")
                        OptionalNutritionField(label: "Mono Fat", value: $monounsaturatedFat, unit: "g")
                        OptionalNutritionField(label: "Poly Fat", value: $polyunsaturatedFat, unit: "g")
                        OptionalNutritionField(label: "Cholesterol", value: $cholesterol, unit: "mg")
                        OptionalNutritionField(label: "Sodium", value: $sodium, unit: "mg")
                        OptionalNutritionField(label: "Potassium", value: $potassium, unit: "mg")
                    }
                    .tint(AppColors.calorie)
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
            emoji: emoji,
            source: source,
            mealType: mealType,
            sugar: sugar,
            addedSugar: addedSugar,
            fiber: fiber,
            saturatedFat: saturatedFat,
            monounsaturatedFat: monounsaturatedFat,
            polyunsaturatedFat: polyunsaturatedFat,
            cholesterol: cholesterol,
            sodium: sodium,
            potassium: potassium
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

struct OptionalNutritionField: View {
    let label: String
    @Binding var value: Double?
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("—", value: $value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}
