import SwiftUI

struct ManualEntryView: View {
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @FocusState private var focused: Field?

    let logDate: Date
    var onCancel: () -> Void
    var onSave: (FoodEntry) -> Void

    private enum Field { case name, calories, protein, carbs, fat }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(calories) != nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Manual Entry")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            field(label: "Name", text: $name, placeholder: "e.g. Homemade salad", keyboard: .default, focus: .name)

            HStack(spacing: 10) {
                numberField(label: "Calories", text: $calories, focus: .calories)
                numberField(label: "Protein (g)", text: $protein, focus: .protein)
            }

            HStack(spacing: 10) {
                numberField(label: "Carbs (g)", text: $carbs, focus: .carbs)
                numberField(label: "Fat (g)", text: $fat, focus: .fat)
            }

            Button {
                let entry = FoodEntry(
                    name: name.trimmingCharacters(in: .whitespaces),
                    calories: Int(calories) ?? 0,
                    protein: Int(protein) ?? 0,
                    carbs: Int(carbs) ?? 0,
                    fat: Int(fat) ?? 0,
                    timestamp: logDate,
                    source: .manual
                )
                onSave(entry)
            } label: {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.calorie)
            .controlSize(.large)
            .disabled(!canSave)

            Button("Cancel") { onCancel() }
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 340)
        .onAppear { focused = .name }
    }

    @ViewBuilder
    private func field(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .focused($focused, equals: focus)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.quaternarySystemFill)))
        }
    }

    @ViewBuilder
    private func numberField(label: String, text: Binding<String>, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .focused($focused, equals: focus)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.quaternarySystemFill)))
        }
    }
}
