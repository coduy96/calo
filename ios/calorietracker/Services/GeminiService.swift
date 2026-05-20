import Foundation
import UIKit

/// Food / label / weight-trend / nutrient-goals AI calls. All go through
/// BackendClient — the actual model lives on the server side and is
/// configurable via Supabase `app_config`. The struct keeps the historical
/// `GeminiService` name so call sites (HomeView, ContentView, etc.) don't
/// need to change.
struct GeminiService {
    struct FoodAnalysis {
        var name: String
        var calories: Int
        var protein: Int
        var carbs: Int
        var fat: Int
        var servingSizeGrams: Double
        var emoji: String?
        var sugar: Double?
        var addedSugar: Double?
        var fiber: Double?
        var saturatedFat: Double?
        var monounsaturatedFat: Double?
        var polyunsaturatedFat: Double?
        var cholesterol: Double?
        var sodium: Double?
        var potassium: Double?
        var servingUnitOptions: [ServingUnitOption] = []
        var selectedServingUnit: String?
        var selectedServingQuantity: Double?
    }

    struct NutritionLabelAnalysis {
        var name: String
        var caloriesPer100g: Double
        var proteinPer100g: Double
        var carbsPer100g: Double
        var fatPer100g: Double
        var servingSizeGrams: Double?
        var sugarPer100g: Double?
        var addedSugarPer100g: Double?
        var fiberPer100g: Double?
        var saturatedFatPer100g: Double?
        var monounsaturatedFatPer100g: Double?
        var polyunsaturatedFatPer100g: Double?
        var cholesterolPer100g: Double?
        var sodiumPer100g: Double?
        var potassiumPer100g: Double?
        var servingUnitOptions: [ServingUnitOption] = []

        func scaled(to grams: Double) -> FoodAnalysis {
            let selectedOption = servingUnitOptions.first
            let scale = grams / 100
            return FoodAnalysis(
                name: name,
                calories: Int(round(caloriesPer100g * scale)),
                protein: Int(round(proteinPer100g * scale)),
                carbs: Int(round(carbsPer100g * scale)),
                fat: Int(round(fatPer100g * scale)),
                servingSizeGrams: grams,
                sugar: sugarPer100g.map { round($0 * scale * 10) / 10 },
                addedSugar: addedSugarPer100g.map { round($0 * scale * 10) / 10 },
                fiber: fiberPer100g.map { round($0 * scale * 10) / 10 },
                saturatedFat: saturatedFatPer100g.map { round($0 * scale * 10) / 10 },
                monounsaturatedFat: monounsaturatedFatPer100g.map { round($0 * scale * 10) / 10 },
                polyunsaturatedFat: polyunsaturatedFatPer100g.map { round($0 * scale * 10) / 10 },
                cholesterol: cholesterolPer100g.map { round($0 * scale * 10) / 10 },
                sodium: sodiumPer100g.map { round($0 * scale * 10) / 10 },
                potassium: potassiumPer100g.map { round($0 * scale * 10) / 10 },
                servingUnitOptions: servingUnitOptions,
                selectedServingUnit: selectedOption?.unit,
                selectedServingQuantity: selectedOption?.quantity(for: grams)
            )
        }
    }

    enum AnalysisError: LocalizedError {
        case imageConversionFailed
        case invalidResponse
        case backend(BackendClient.BackendError)

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return String(localized: "Failed to process the image.")
            case .invalidResponse:
                return String(localized: "Could not understand the AI response. Please try again.")
            case .backend(let err):
                return err.errorDescription
            }
        }
    }

    // MARK: - Public API

    /// Instruction appended to every prompt that emits a user-facing `name`
    /// field. Tells the model to localize human-readable text to the user's
    /// chosen app language while keeping JSON keys and unit identifiers in
    /// English so downstream parsing/matching stays stable.
    private static var languageDirective: String {
        let lang = AppLanguageSettings.current.promptLanguageName
        return "IMPORTANT: Write the `name` field and any other human-readable text in \(lang). Keep all JSON keys, the `emoji` value, and `unit` identifiers (slice/piece/ml/cup/tbsp/tsp/can/packet/bar/scoop/bowl/fl oz) in English — they are matched programmatically."
    }

    static func analyzeTextInput(description: String) async throws -> FoodAnalysis {
        let prompt = """
        Estimate the nutritional content for: \(description)
        Parse any quantities, brands, and multiple items from the text. If a brand is mentioned, use that brand's known nutritional data. If multiple items are described, sum up the total nutrition.
        Respond ONLY with JSON:
        {"name":"...","calories":0,"protein":0,"carbs":0,"fat":0,"serving_size_grams":0.0,"emoji":"🍽️","sugar":0.0,"added_sugar":0.0,"fiber":0.0,"saturated_fat":0.0,"monounsaturated_fat":0.0,"polyunsaturated_fat":0.0,"cholesterol":0.0,"sodium":0.0,"potassium":0.0,"unit_options":[]}
        Calories/protein/carbs/fat are integers. serving_size_grams is the estimated total weight in grams. Micronutrients are numbers (sugar/fiber/sat fat/mono fat/poly fat in grams, cholesterol/sodium/potassium in milligrams).
        The [] in unit_options above is only a JSON shape placeholder; replace it with options when a non-gram unit is obvious.
        unit_options is required when the text names an obvious non-gram serving unit, and optional otherwise. Use slice/piece for pizza, cake, bread, cookies, fruit pieces, etc.; use ml/cup/fl oz for drinks, milk, soup, smoothies, sauces, etc.; use tbsp/tsp for spooned foods; use can/packet when packaged. Its quantity must describe the whole analyzed amount, not always 1. Do not copy any sample number; use the quantity stated or clearly implied by the meal. Use [] only when no non-gram unit is apparent. Do not include g/grams in unit_options.
        Include a single food emoji that best represents the food. Use null for any nutrient you cannot estimate.

        \(languageDirective)
        """
        let text = try await callAI(task: .food, prompt: prompt, image: nil)
        let analysis = try parseFoodAnalysis(from: text)
        return await addingFallbackServingUnits(to: analysis, image: nil, description: description)
    }

    static func autoAnalyze(image: UIImage) async throws -> FoodAnalysis {
        let prompt = """
        Analyze this image. It could be either a photo of food OR a nutrition facts label.

        If it's a food photo: identify the food and estimate nutritional content for the serving shown.
        If it's a nutrition label: read the values and calculate for one serving size as listed on the label.

        Respond ONLY with JSON:
        {"name":"...","calories":0,"protein":0,"carbs":0,"fat":0,"serving_size_grams":0.0,"sugar":0.0,"added_sugar":0.0,"fiber":0.0,"saturated_fat":0.0,"monounsaturated_fat":0.0,"polyunsaturated_fat":0.0,"cholesterol":0.0,"sodium":0.0,"potassium":0.0,"unit_options":[]}
        Calories/protein/carbs/fat are integers. serving_size_grams is the estimated weight in grams of the serving. Micronutrients are numbers (sugar/fiber/sat fat/mono fat/poly fat in grams, cholesterol/sodium/potassium in milligrams).
        The [] in unit_options above is only a JSON shape placeholder; replace it with options when a non-gram unit is obvious.
        unit_options is required for obvious non-gram units visible in the image or label. Use slice/piece for pizza, cake, bread, cookies, fruit pieces, etc.; use ml/cup/fl oz for drinks, milk, soup, smoothies, sauces, etc.; use tbsp/tsp for spooned foods; use can/packet when packaged. Its quantity must describe the whole analyzed amount, not always 1. For a whole or mostly-whole divisible food like cake, pie, or pizza, count the visible pieces/slices and derive grams_per_unit from serving_size_grams / quantity. If N slices are visible, return quantity N. Use quantity 1 only when a single piece/slice is actually the analyzed portion. Use [] only when no non-gram unit is apparent. Do not include g/grams in unit_options.
        Use null for any nutrient you cannot estimate.

        \(languageDirective)
        """
        let text = try await callAI(task: .food, prompt: prompt, image: image)
        let analysis = try parseFoodAnalysis(from: text)
        return await addingFallbackServingUnits(to: analysis, image: image, description: nil)
    }

    static func analyzeFood(image: UIImage, description: String? = nil) async throws -> FoodAnalysis {
        var prompt = """
        Analyze this food image. Identify the food and estimate its nutritional content.

        Respond ONLY with a JSON object in this exact format, no other text:
        {"name":"Food Name","calories":0,"protein":0,"carbs":0,"fat":0,"serving_size_grams":0.0,"sugar":0.0,"added_sugar":0.0,"fiber":0.0,"saturated_fat":0.0,"monounsaturated_fat":0.0,"polyunsaturated_fat":0.0,"cholesterol":0.0,"sodium":0.0,"potassium":0.0,"unit_options":[]}

        Calories/protein/carbs/fat are integers. serving_size_grams is the estimated weight in grams of the serving shown. Micronutrients are numbers (sugar/fiber/sat fat/mono fat/poly fat in grams, cholesterol/sodium/potassium in milligrams).
        The [] in unit_options above is only a JSON shape placeholder; replace it with options when a non-gram unit is obvious.
        unit_options is required for obvious non-gram units visible in the food. Use slice/piece for pizza, cake, bread, cookies, fruit pieces, etc.; use ml/cup/fl oz for drinks, milk, soup, smoothies, sauces, etc.; use tbsp/tsp for spooned foods; use can/packet when packaged. Its quantity must describe the whole analyzed amount, not always 1. For a whole or mostly-whole divisible food like cake, pie, or pizza, count the visible pieces/slices and derive grams_per_unit from serving_size_grams / quantity. If N slices are visible, return quantity N. Use quantity 1 only when a single piece/slice is actually the analyzed portion. Use [] only when no non-gram unit is apparent. Do not include g/grams in unit_options.
        Give your best estimate for the visible food amount shown in the image. For whole/mostly-whole cakes, pizzas, pies, loaves, or similar foods, estimate the total visible item/remaining item weight rather than defaulting to one slice. Use null for any nutrient you cannot estimate.
        """

        if let description, !description.trimmingCharacters(in: .whitespaces).isEmpty {
            prompt += "\n\nAdditional context from the user about this meal: \(description)\nUse this context to improve accuracy of identification, portion size, and nutrition estimates."
        }

        prompt += "\n\n\(languageDirective)"

        let text = try await callAI(task: .food, prompt: prompt, image: image)
        let analysis = try parseFoodAnalysis(from: text)
        return await addingFallbackServingUnits(to: analysis, image: image, description: description)
    }

    static func analyzeNutritionLabel(image: UIImage) async throws -> NutritionLabelAnalysis {
        let prompt = """
        Read this nutrition label image. Extract the nutritional values per 100g (or per 100ml).
        If the label shows per-serving values, convert them to per-100g using the serving size.

        For the name, identify the product or brand name visible on the packaging or label.
        If no name is visible, describe the food type (e.g. "Protein Bar", "Yogurt", "Cereal").

        Respond ONLY with JSON:
        {"name":"Product Name","calories_per_100g":0.0,"protein_per_100g":0.0,"carbs_per_100g":0.0,"fat_per_100g":0.0,"serving_size_grams":0.0,"sugar_per_100g":0.0,"added_sugar_per_100g":0.0,"fiber_per_100g":0.0,"saturated_fat_per_100g":0.0,"monounsaturated_fat_per_100g":0.0,"polyunsaturated_fat_per_100g":0.0,"cholesterol_per_100g":0.0,"sodium_per_100g":0.0,"potassium_per_100g":0.0,"unit_options":[]}

        The [] in unit_options above is only a JSON shape placeholder; replace it with options when a non-gram unit is visible.
        All values should be numbers. If serving size or any nutrient is not available, use null. unit_options is required when a non-gram label serving unit is visible, such as slice, piece, tbsp, cup, ml, fl oz, can, or packet. Do not copy any sample number; use the quantity shown on the label. Use [] only when no non-gram unit is visible. Do not include g/grams in unit_options.

        \(languageDirective)
        For the `name` field: if a product/brand name is printed on the label, copy it verbatim regardless of script; otherwise translate the food type to the target language.
        """
        let text = try await callAI(task: .label, prompt: prompt, image: image)
        let analysis = try parseNutritionLabel(from: text)
        return await addingFallbackServingUnits(to: analysis, image: image)
    }

    static func suggestOptionalNutrientGoals(
        profile: UserProfile,
        currentGoals: OptionalNutrientGoals,
        useMetric: Bool
    ) async throws -> OptionalNutrientGoals {
        let weight = useMetric
            ? String(format: "%.1f kg", profile.weightKg)
            : String(format: "%.1f lb", profile.weightKg * 2.20462)
        let height = useMetric
            ? String(format: "%.0f cm", profile.heightCm)
            : String(format: "%.1f in", profile.heightCm / 2.54)
        let bodyFat = profile.bodyFatPercentage.map { "\(Int(($0 * 100).rounded()))%" } ?? "not set"
        let goalWeight = profile.goalWeightKg.map { kg in
            useMetric ? String(format: "%.1f kg", kg) : String(format: "%.1f lb", kg * 2.20462)
        } ?? "not set"
        let currentGoalLines = OptionalNutrient.allCases
            .map { "- \($0.displayName): \(currentGoals.goal(for: $0)) \($0.unit) (\($0.goalStyle))" }
            .joined(separator: "\n")

        let prompt = """
        You are setting daily non-macro nutrient goals for a food tracking app.
        Return ONLY valid JSON with these exact numeric keys:
        {"fiber":30,"sugar":50,"added_sugar":25,"saturated_fat":20,"cholesterol":300,"sodium":2300,"potassium":3500}

        Do not include calories, protein, carbs, or fat. Do not change calorie or macro targets.
        Use reasonable general-adult nutrition targets unless the user's profile strongly suggests a small adjustment.
        Treat fiber and potassium as target/minimum style goals. Treat sugar, added sugar, saturated fat, cholesterol, and sodium as daily limit-style goals.
        Keep values in normal consumer-tracker ranges and round to practical app-friendly numbers.

        User profile:
        - Gender: \(profile.gender.displayName)
        - Age: \(profile.age)
        - Height: \(height)
        - Weight: \(weight)
        - Activity: \(profile.activityLevel.displayName)
        - Weight goal: \(profile.goal.displayName)
        - Goal weight: \(goalWeight)
        - Body fat: \(bodyFat)
        - Current calorie target: \(profile.effectiveCalories) kcal
        - Current macro targets: \(profile.effectiveProtein)g protein, \(profile.effectiveCarbs)g carbs, \(profile.effectiveFat)g fat

        Current non-macro nutrient defaults/custom values:
        \(currentGoalLines)
        """

        let text = try await callAI(task: .goals, prompt: prompt, image: nil)
        return try parseOptionalNutrientGoals(from: text, fallback: currentGoals)
    }

    static func analyzeWeightTrend(
        profile: UserProfile,
        forecast: WeightForecast,
        recentAvgMacros: (protein: Int, carbs: Int, fat: Int)?,
        useMetric: Bool
    ) async throws -> String {
        let unit = useMetric ? "kg" : "lbs"
        let wUnit: (Double) -> String = { kg in
            useMetric ? String(format: "%.1f kg", kg) : String(format: "%.1f lbs", kg * 2.20462)
        }
        let weekly: (Double) -> String = { kg in
            useMetric ? String(format: "%+.2f kg/week", kg) : String(format: "%+.2f lbs/week", kg * 2.20462)
        }

        var lines: [String] = []
        lines.append("User profile:")
        lines.append("- Gender: \(profile.gender.rawValue)")
        lines.append("- Age: \(profile.age)")
        lines.append("- Height: \(useMetric ? String(format: "%.0f cm", profile.heightCm) : String(format: "%.1f in", profile.heightCm / 2.54))")
        lines.append("- Current weight: \(wUnit(forecast.currentWeightKg))")
        lines.append("- Activity level: \(profile.activityLevel.displayName)")
        lines.append("- Goal: \(profile.goal.displayName)")
        if let goal = profile.goalWeightKg {
            lines.append("- Goal weight: \(wUnit(goal))")
        }
        if let bf = profile.bodyFatPercentage {
            lines.append("- Body fat: \(Int(bf * 100))%")
        }
        lines.append("")
        lines.append("Energy balance (from \(forecast.daysOfFoodData) days of logged food):")
        lines.append("- Avg daily intake: \(forecast.avgDailyCalories) kcal")
        lines.append("- TDEE estimate: \(forecast.tdee) kcal")
        lines.append("- Daily balance: \(forecast.dailyEnergyBalance >= 0 ? "+" : "")\(forecast.dailyEnergyBalance) kcal")
        if let macros = recentAvgMacros {
            lines.append("- Avg macros: \(macros.protein)g protein, \(macros.carbs)g carbs, \(macros.fat)g fat")
        }
        lines.append("")
        lines.append("Projection:")
        lines.append("- Predicted (from diet): \(weekly(forecast.predictedWeeklyChangeKg))")
        if let observed = forecast.observedWeeklyChangeKg {
            lines.append("- Observed (from \(forecast.weightEntriesUsed) weight entries): \(weekly(observed))")
        }
        lines.append("- Expected weight in 30 days: \(wUnit(forecast.predictedWeight30dKg))")
        lines.append("- Expected weight in 90 days: \(wUnit(forecast.predictedWeight90dKg))")
        if let days = forecast.daysToGoal {
            lines.append("- At current pace, reach goal in ~\(days) days")
        }
        if forecast.trendsDisagree {
            lines.append("- NOTE: predicted and observed trends differ by >0.3 kg/week (possibly under-logging food).")
        }

        let langName = AppLanguageSettings.current.promptLanguageName
        let prompt = """
        You are a nutrition coach analyzing a user's weight trend. Write 3–4 short sentences in \(langName) (plain prose, no bullets, no markdown, no bold) that:
        1. State the predicted weight in \(unit) 30 days out and whether they're on track for their goal.
        2. Give one or two specific, actionable suggestions (e.g. calorie target, protein amount, activity change) grounded in the numbers below.
        3. If predicted and observed trends disagree, mention possible under-logging briefly.
        Be direct, factual, and encouraging. Do not exceed 100 words. Write the entire response in \(langName).

        \(lines.joined(separator: "\n"))
        """
        return try await callAI(task: .weight, prompt: prompt, image: nil)
    }

    // MARK: - Backend call

    private static func callAI(task: BackendClient.Task, prompt: String, image: UIImage?) async throws -> String {
        var imageBase64: String?
        if let image {
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw AnalysisError.imageConversionFailed
            }
            imageBase64 = data.base64EncodedString()
        }

        let message = BackendClient.Message(
            role: .user,
            content: prompt,
            imageBase64: imageBase64
        )

        do {
            let response = try await BackendClient.generate(task: task, messages: [message])
            guard let text = response.text, !text.isEmpty else {
                throw AnalysisError.invalidResponse
            }
            return text
        } catch let err as BackendClient.BackendError {
            throw AnalysisError.backend(err)
        }
    }

    // MARK: - Parsing (unchanged)

    private static func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let openFence = cleaned.range(of: "```json", options: .caseInsensitive)
            ?? cleaned.range(of: "```") {
            cleaned = String(cleaned[openFence.upperBound...])
            if let closeFence = cleaned.range(of: "```", options: .backwards) {
                cleaned = String(cleaned[..<closeFence.lowerBound])
            }
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstBrace = cleaned.firstIndex(of: "{") else { return cleaned }
        var depth = 0
        var inString = false
        var escape = false
        var endIndex: String.Index?
        for idx in cleaned[firstBrace...].indices {
            let ch = cleaned[idx]
            if escape { escape = false; continue }
            if ch == "\\" { escape = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            if inString { continue }
            if ch == "{" { depth += 1 }
            else if ch == "}" {
                depth -= 1
                if depth == 0 {
                    endIndex = cleaned.index(after: idx)
                    break
                }
            }
        }
        if let end = endIndex {
            return String(cleaned[firstBrace..<end])
        }
        return cleaned
    }

    private static func parseFoodAnalysis(from text: String) throws -> FoodAnalysis {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let calories = (json["calories"] as? NSNumber)?.intValue,
              let protein = (json["protein"] as? NSNumber)?.intValue,
              let carbs = (json["carbs"] as? NSNumber)?.intValue,
              let fat = (json["fat"] as? NSNumber)?.intValue
        else { throw AnalysisError.invalidResponse }
        let servingSizeGrams = (json["serving_size_grams"] as? NSNumber)?.doubleValue ?? 100
        let unitOptions = parseServingUnitOptions(from: json, servingSizeGrams: servingSizeGrams)
        let selectedOption = unitOptions.first
        return FoodAnalysis(
            name: name, calories: calories, protein: protein, carbs: carbs, fat: fat,
            servingSizeGrams: servingSizeGrams,
            emoji: json["emoji"] as? String,
            sugar: (json["sugar"] as? NSNumber)?.doubleValue,
            addedSugar: (json["added_sugar"] as? NSNumber)?.doubleValue,
            fiber: (json["fiber"] as? NSNumber)?.doubleValue,
            saturatedFat: (json["saturated_fat"] as? NSNumber)?.doubleValue,
            monounsaturatedFat: (json["monounsaturated_fat"] as? NSNumber)?.doubleValue,
            polyunsaturatedFat: (json["polyunsaturated_fat"] as? NSNumber)?.doubleValue,
            cholesterol: (json["cholesterol"] as? NSNumber)?.doubleValue,
            sodium: (json["sodium"] as? NSNumber)?.doubleValue,
            potassium: (json["potassium"] as? NSNumber)?.doubleValue,
            servingUnitOptions: unitOptions,
            selectedServingUnit: selectedOption?.unit,
            selectedServingQuantity: selectedOption?.quantity(for: servingSizeGrams)
        )
    }

    private static func parseNutritionLabel(from text: String) throws -> NutritionLabelAnalysis {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let caloriesPer100g = (json["calories_per_100g"] as? NSNumber)?.doubleValue,
              let proteinPer100g = (json["protein_per_100g"] as? NSNumber)?.doubleValue,
              let carbsPer100g = (json["carbs_per_100g"] as? NSNumber)?.doubleValue,
              let fatPer100g = (json["fat_per_100g"] as? NSNumber)?.doubleValue
        else { throw AnalysisError.invalidResponse }
        let servingSizeGrams = (json["serving_size_grams"] as? NSNumber)?.doubleValue
        return NutritionLabelAnalysis(
            name: name, caloriesPer100g: caloriesPer100g, proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g, fatPer100g: fatPer100g,
            servingSizeGrams: servingSizeGrams,
            sugarPer100g: (json["sugar_per_100g"] as? NSNumber)?.doubleValue,
            addedSugarPer100g: (json["added_sugar_per_100g"] as? NSNumber)?.doubleValue,
            fiberPer100g: (json["fiber_per_100g"] as? NSNumber)?.doubleValue,
            saturatedFatPer100g: (json["saturated_fat_per_100g"] as? NSNumber)?.doubleValue,
            monounsaturatedFatPer100g: (json["monounsaturated_fat_per_100g"] as? NSNumber)?.doubleValue,
            polyunsaturatedFatPer100g: (json["polyunsaturated_fat_per_100g"] as? NSNumber)?.doubleValue,
            cholesterolPer100g: (json["cholesterol_per_100g"] as? NSNumber)?.doubleValue,
            sodiumPer100g: (json["sodium_per_100g"] as? NSNumber)?.doubleValue,
            potassiumPer100g: (json["potassium_per_100g"] as? NSNumber)?.doubleValue,
            servingUnitOptions: parseServingUnitOptions(from: json, servingSizeGrams: servingSizeGrams)
        )
    }

    private static func parseOptionalNutrientGoals(
        from text: String,
        fallback: OptionalNutrientGoals
    ) throws -> OptionalNutrientGoals {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw AnalysisError.invalidResponse }

        var goals = fallback.mergedWithDefaults()
        var parsedAnyValue = false

        for nutrient in OptionalNutrient.allCases {
            let rawValue = json[nutrient.jsonKey] ?? json[nutrient.rawValue]
            guard let number = rawValue as? NSNumber else { continue }
            goals.setGoal(number.intValue, for: nutrient)
            parsedAnyValue = true
        }

        guard parsedAnyValue else { throw AnalysisError.invalidResponse }
        return goals.mergedWithDefaults()
    }

    private static func addingFallbackServingUnits(
        to analysis: FoodAnalysis,
        image: UIImage?,
        description: String?
    ) async -> FoodAnalysis {
        guard analysis.servingUnitOptions.isEmpty else { return analysis }
        guard let options = try? await inferServingUnitOptions(
            name: analysis.name,
            servingSizeGrams: analysis.servingSizeGrams,
            image: image,
            description: description
        ), !options.isEmpty else {
            return analysis
        }

        var updated = analysis
        updated.servingUnitOptions = options
        updated.selectedServingUnit = options.first?.unit
        updated.selectedServingQuantity = options.first?.quantity(for: analysis.servingSizeGrams)
        return updated
    }

    private static func addingFallbackServingUnits(
        to analysis: NutritionLabelAnalysis,
        image: UIImage
    ) async -> NutritionLabelAnalysis {
        guard analysis.servingUnitOptions.isEmpty else { return analysis }
        guard let servingSizeGrams = analysis.servingSizeGrams,
              let options = try? await inferServingUnitOptions(
                name: analysis.name,
                servingSizeGrams: servingSizeGrams,
                image: image,
                description: nil
              ), !options.isEmpty else {
            return analysis
        }

        var updated = analysis
        updated.servingUnitOptions = options
        return updated
    }

    private static func inferServingUnitOptions(
        name: String,
        servingSizeGrams: Double,
        image: UIImage?,
        description: String?
    ) async throws -> [ServingUnitOption] {
        let context = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextLine = context.map { "\nUser context: \($0)" } ?? ""
        let prompt = """
        The previous food analysis returned grams only. Infer non-gram serving unit options for the same food and amount.

        Food: \(name)
        Total grams for the analyzed amount: \(String(format: "%.1f", servingSizeGrams))\(contextLine)

        Return ONLY JSON:
        {"unit_options":[{"unit":"slice","quantity":8.0,"grams_per_unit":45.0}]}

        Rules:
        - Replace the sample numbers with the actual best estimate. Do not copy 8 or 45 unless they fit the food.
        - If the image shows countable portions, count visible pieces/slices. For pizza, cake, pie, bread, cookies, fruit pieces, nuggets, or sweets, use slice or piece.
        - For liquids or pourable foods like milk, juice, soup, smoothies, dal, sauces, or yogurt, use ml when the volume is clearer than a count.
        - For spooned foods like peanut butter, honey, oil, chutney, or ghee, use tbsp or tsp.
        - For packaged foods/drinks, use can, packet, bar, scoop, or bowl only when that unit is visible or strongly implied.
        - grams_per_unit is grams for one unit. For countable units, use total grams / visible quantity. For ml, use grams per ml.
        - Return [] only if no non-gram unit is apparent.
        - IMPORTANT: Keep `unit` values in English (slice/piece/ml/cup/fl oz/tbsp/tsp/can/packet/bar/scoop/bowl) — they are matched programmatically.

        Good outputs:
        {"unit_options":[{"unit":"slice","quantity":8.0,"grams_per_unit":45.0}]}
        {"unit_options":[{"unit":"ml","quantity":250.0,"grams_per_unit":1.03},{"unit":"cup","quantity":1.0,"grams_per_unit":250.0}]}
        {"unit_options":[{"unit":"tbsp","quantity":2.0,"grams_per_unit":16.0}]}
        {"unit_options":[{"unit":"can","quantity":1.0,"grams_per_unit":330.0}]}
        {"unit_options":[{"unit":"piece","quantity":5.0,"grams_per_unit":18.0}]}
        """

        let text = try await callAI(task: .food, prompt: prompt, image: image)
        return try parseServingUnitOptions(from: text, servingSizeGrams: servingSizeGrams)
    }

    private static func parseServingUnitOptions(from text: String, servingSizeGrams: Double?) throws -> [ServingUnitOption] {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw AnalysisError.invalidResponse }
        return parseServingUnitOptions(from: json, servingSizeGrams: servingSizeGrams)
    }

    private static func parseServingUnitOptions(from json: [String: Any], servingSizeGrams: Double?) -> [ServingUnitOption] {
        let rawOptions = json["unit_options"] as? [[String: Any]]
            ?? json["serving_unit_options"] as? [[String: Any]]
            ?? []

        var seen = Set<String>()
        var options: [ServingUnitOption] = []
        for raw in rawOptions {
            guard let unit = raw["unit"] as? String,
                  let gramsPerUnit = doubleValue(raw["grams_per_unit"] ?? raw["gramsPerUnit"])
            else { continue }

            var option = ServingUnitOption(
                unit: unit,
                gramsPerUnit: gramsPerUnit,
                quantity: doubleValue(raw["quantity"])
            )
            if option.quantity == nil, let servingSizeGrams, gramsPerUnit > 0 {
                option.quantity = servingSizeGrams / gramsPerUnit
            }

            guard option.isValid, !option.isGramUnit, !seen.contains(option.id) else { continue }
            seen.insert(option.id)
            options.append(option)
        }
        return Array(options.prefix(4))
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String {
            return Double(string)
        }
        return nil
    }
}
