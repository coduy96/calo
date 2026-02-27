import SwiftUI

struct EditFoodEntryView: View {
    let entry: FoodEntry
    @Environment(FoodStore.self) private var foodStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @State private var mealType: MealType

    @State private var sugarText: String
    @State private var addedSugarText: String
    @State private var fiberText: String
    @State private var saturatedFatText: String
    @State private var monoFatText: String
    @State private var polyFatText: String
    @State private var cholesterolText: String
    @State private var sodiumText: String
    @State private var potassiumText: String

    init(entry: FoodEntry) {
        self.entry = entry
        self._name = State(initialValue: entry.name)
        self._caloriesText = State(initialValue: "\(entry.calories)")
        self._proteinText = State(initialValue: "\(entry.protein)")
        self._carbsText = State(initialValue: "\(entry.carbs)")
        self._fatText = State(initialValue: "\(entry.fat)")
        self._mealType = State(initialValue: entry.mealType)
        self._sugarText = State(initialValue: Self.formatOptional(entry.sugar))
        self._addedSugarText = State(initialValue: Self.formatOptional(entry.addedSugar))
        self._fiberText = State(initialValue: Self.formatOptional(entry.fiber))
        self._saturatedFatText = State(initialValue: Self.formatOptional(entry.saturatedFat))
        self._monoFatText = State(initialValue: Self.formatOptional(entry.monounsaturatedFat))
        self._polyFatText = State(initialValue: Self.formatOptional(entry.polyunsaturatedFat))
        self._cholesterolText = State(initialValue: Self.formatOptional(entry.cholesterol))
        self._sodiumText = State(initialValue: Self.formatOptional(entry.sodium))
        self._potassiumText = State(initialValue: Self.formatOptional(entry.potassium))
    }

    private static func formatOptional(_ value: Double?) -> String {
        guard let value else { return "" }
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        NavigationStack {
            List {
                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                    Section {
                        HStack {
                            Spacer()
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                } else if let emoji = entry.emoji {
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
                    EditableNutritionRow(label: "Calories", text: $caloriesText, unit: "kcal")
                    EditableNutritionRow(label: "Protein", text: $proteinText, unit: "g")
                    EditableNutritionRow(label: "Carbs", text: $carbsText, unit: "g")
                    EditableNutritionRow(label: "Fat", text: $fatText, unit: "g")
                }

                Section {
                    DisclosureGroup("More Nutrition") {
                        EditableNutritionRow(label: "Sugar", text: $sugarText, unit: "g")
                        EditableNutritionRow(label: "Added Sugar", text: $addedSugarText, unit: "g")
                        EditableNutritionRow(label: "Fiber", text: $fiberText, unit: "g")
                        EditableNutritionRow(label: "Saturated Fat", text: $saturatedFatText, unit: "g")
                        EditableNutritionRow(label: "Mono Fat", text: $monoFatText, unit: "g")
                        EditableNutritionRow(label: "Poly Fat", text: $polyFatText, unit: "g")
                        EditableNutritionRow(label: "Cholesterol", text: $cholesterolText, unit: "mg")
                        EditableNutritionRow(label: "Sodium", text: $sodiumText, unit: "mg")
                        EditableNutritionRow(label: "Potassium", text: $potassiumText, unit: "mg")
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
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.calorie)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func parseOptionalDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private func saveChanges() {
        let updated = FoodEntry(
            id: entry.id,
            name: name,
            calories: Int(caloriesText) ?? entry.calories,
            protein: Int(proteinText) ?? entry.protein,
            carbs: Int(carbsText) ?? entry.carbs,
            fat: Int(fatText) ?? entry.fat,
            timestamp: entry.timestamp,
            imageData: entry.imageData,
            emoji: entry.emoji,
            source: entry.source,
            mealType: mealType,
            sugar: parseOptionalDouble(sugarText),
            addedSugar: parseOptionalDouble(addedSugarText),
            fiber: parseOptionalDouble(fiberText),
            saturatedFat: parseOptionalDouble(saturatedFatText),
            monounsaturatedFat: parseOptionalDouble(monoFatText),
            polyunsaturatedFat: parseOptionalDouble(polyFatText),
            cholesterol: parseOptionalDouble(cholesterolText),
            sodium: parseOptionalDouble(sodiumText),
            potassium: parseOptionalDouble(potassiumText)
        )
        foodStore.updateEntry(updated)
        dismiss()
    }
}

private struct EditableNutritionRow: View {
    let label: String
    @Binding var text: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}
