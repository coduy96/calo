import SwiftUI

struct ServingUnitEditor: View {
    @Binding var quantityText: String
    @Binding var servingSizeGrams: Double
    @Binding var selectedUnitID: String

    let unitOptions: [ServingUnitOption]
    let focusRequest: Int
    var onEditingChanged: (Bool) -> Void
    var onClear: () -> Void

    private var pickerOptions: [ServingUnitOption] {
        ServingUnitOption.pickerOptions(for: unitOptions)
    }

    private var selectedOption: ServingUnitOption {
        pickerOptions.first { $0.id == selectedUnitID } ?? .grams
    }

    private var selectedQuantity: Double? {
        Double(quantityText)
    }

    private var selectedUnitLabel: String {
        selectedOption.displayUnit(for: selectedQuantity)
    }

    var body: some View {
        HStack(spacing: 8) {
            EndEditingDecimalTextField(
                text: $quantityText,
                focusRequest: focusRequest,
                onEditingChanged: onEditingChanged
            )
            .frame(width: 72)
            .onChange(of: quantityText) { _, newValue in
                guard let parsed = Double(newValue), parsed > 0 else { return }
                servingSizeGrams = parsed * selectedOption.gramsPerUnit
            }
            .onChange(of: selectedUnitID) { _, _ in
                syncQuantityTextToSelectedUnit()
            }

            if !quantityText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear quantity")
            }

            if pickerOptions.count > 1 {
                Menu {
                    ForEach(pickerOptions) { option in
                        Button {
                            selectedUnitID = option.id
                        } label: {
                            Text(option.displayUnit(for: option.id == selectedUnitID ? selectedQuantity : nil))
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(selectedUnitLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .allowsTightening(true)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(AppColors.calorie)
                    .frame(width: 90, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: false)
            } else {
                Text("g")
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .leading)
            }
        }
    }

    private func syncQuantityTextToSelectedUnit() {
        let option = selectedOption
        let quantity = option.gramsPerUnit > 0 ? servingSizeGrams / option.gramsPerUnit : servingSizeGrams
        quantityText = Self.formatQuantity(quantity)
    }

    static func formatQuantity(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        if abs(value) < 10 {
            return String(format: "%.2f", value).trimmingTrailingZeros()
        }
        return String(format: "%.1f", value).trimmingTrailingZeros()
    }
}

private extension String {
    func trimmingTrailingZeros() -> String {
        var value = self
        while value.contains(".") && value.last == "0" {
            value.removeLast()
        }
        if value.last == "." {
            value.removeLast()
        }
        return value
    }
}

extension ServingUnitOption {
    static func normalizedOptions(_ options: [ServingUnitOption], totalGrams: Double) -> [ServingUnitOption] {
        var seen = Set<String>()
        var normalized: [ServingUnitOption] = []
        var liquidGramsPerMilliliter: Double?

        for rawOption in options {
            var option = rawOption
            if option.quantity == nil, option.gramsPerUnit > 0 {
                option.quantity = totalGrams / option.gramsPerUnit
            }
            guard option.isValid, !option.isGramUnit, !seen.contains(option.id) else { continue }
            seen.insert(option.id)
            normalized.append(option)

            if liquidGramsPerMilliliter == nil,
               let milliliters = millilitersPerLiquidUnit(option.normalizedUnit),
               milliliters > 0 {
                liquidGramsPerMilliliter = option.gramsPerUnit / milliliters
            }
        }

        if let liquidGramsPerMilliliter {
            appendCommonLiquidUnits(
                gramsPerMilliliter: liquidGramsPerMilliliter,
                totalGrams: totalGrams,
                seen: &seen,
                options: &normalized
            )
        }

        return Array(normalized.prefix(9))
    }

    static func pickerOptions(for options: [ServingUnitOption]) -> [ServingUnitOption] {
        var seen: Set<String> = [ServingUnitOption.grams.id]
        let nonGramOptions = options.filter { option in
            option.isValid && !option.isGramUnit && seen.insert(option.id).inserted
        }
        return [ServingUnitOption.grams] + nonGramOptions
    }

    static func option(matching id: String, in options: [ServingUnitOption]) -> ServingUnitOption {
        pickerOptions(for: options).first { $0.id == id } ?? .grams
    }

    static func initialUnitID(
        preferredUnit: String?,
        options: [ServingUnitOption]
    ) -> String {
        let pickerOptions = pickerOptions(for: options)
        if let preferredUnit {
            let preferredID = preferredUnit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if pickerOptions.contains(where: { $0.id == preferredID }) {
                return preferredID
            }
        }
        return options.first?.id ?? ServingUnitOption.grams.id
    }

    static func initialQuantityText(
        totalGrams: Double,
        selectedUnitID: String,
        selectedQuantity: Double?,
        options: [ServingUnitOption]
    ) -> String {
        let option = option(matching: selectedUnitID, in: options)
        if let selectedQuantity, selectedQuantity > 0, !option.isGramUnit {
            return ServingUnitEditor.formatQuantity(selectedQuantity)
        }
        let quantity = option.gramsPerUnit > 0 ? totalGrams / option.gramsPerUnit : totalGrams
        return ServingUnitEditor.formatQuantity(quantity)
    }

    private static func millilitersPerLiquidUnit(_ unit: String) -> Double? {
        switch unit {
        case "ml", "milliliter", "milliliters", "millilitre", "millilitres":
            return 1
        case "l", "liter", "liters", "litre", "litres":
            return 1_000
        case "fl oz", "fluid ounce", "fluid ounces", "floz", "oz":
            return 29.5735
        case "cup", "cups":
            return 240
        case "tbsp", "tablespoon", "tablespoons":
            return 15
        case "tsp", "teaspoon", "teaspoons":
            return 5
        case "pint", "pints":
            return 473.176
        case "quart", "quarts":
            return 946.353
        case "gallon", "gallons", "gal":
            return 3_785.412
        default:
            return nil
        }
    }

    private static func appendCommonLiquidUnits(
        gramsPerMilliliter: Double,
        totalGrams: Double,
        seen: inout Set<String>,
        options: inout [ServingUnitOption]
    ) {
        let commonUnits: [(unit: String, milliliters: Double)] = [
            ("ml", 1),
            ("fl oz", 29.5735),
            ("cup", 240),
            ("tbsp", 15),
            ("tsp", 5),
            ("l", 1_000),
            ("pint", 473.176),
            ("quart", 946.353),
            ("gallon", 3_785.412)
        ]

        for commonUnit in commonUnits {
            let gramsPerUnit = gramsPerMilliliter * commonUnit.milliliters
            let option = ServingUnitOption(
                unit: commonUnit.unit,
                gramsPerUnit: gramsPerUnit,
                quantity: totalGrams / gramsPerUnit
            )
            guard option.isValid, seen.insert(option.id).inserted else { continue }
            options.append(option)
        }
    }
}
