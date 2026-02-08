import SwiftUI

struct TextFoodInputView: View {
    @State private var brand = ""
    @State private var foodName = ""
    @State private var quantity = "1"
    @State private var unit = "serving"
    @Environment(\.dismiss) private var dismiss

    var onSubmit: (String, String, String, String) -> Void

    private let units = ["g", "ml", "oz", "cups", "tbsp", "tsp", "pieces", "slices", "serving"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Brand (optional)", text: $brand)
                        .autocorrectionDisabled()

                    TextField("Food name", text: $foodName)
                        .autocorrectionDisabled()
                }

                Section("Quantity") {
                    HStack {
                        TextField("Amount", text: $quantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)

                        Spacer()

                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { u in
                                Text(u).tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.calorie)
                    }
                }

                Section {
                    Button {
                        onSubmit(brand, foodName, quantity, unit)
                    } label: {
                        Text("Analyze")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.calorie)
                    .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Text Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
