import Foundation

/// Multi-turn coach chat. The conversation lives client-side; each turn goes
/// through BackendClient (which speaks to whichever LLM is configured in
/// `app_config`). Tool definitions are forwarded server-side; tool execution
/// stays on the device (CoachTools reads from local stores). The loop is:
/// send messages → if response includes tool_calls, run them locally, append
/// tool result messages, send again → repeat until plain text comes back.
struct ChatService {
    enum ChatError: LocalizedError {
        case backend(BackendClient.BackendError)
        case invalidResponse
        case toolRoundLimit

        var errorDescription: String? {
            switch self {
            case .backend(let err):
                return err.errorDescription
            case .invalidResponse:
                return String(localized: "Could not understand the AI response. Please try again.")
            case .toolRoundLimit:
                return String(localized: "Coach exceeded the tool-call round limit. Try rephrasing your question.")
            }
        }
    }

    /// Hard cap on tool-call rounds per user message. Generous — most real
    /// questions resolve in 1–2 calls. Without a cap, a misbehaving model
    /// could loop forever on recursive calls.
    private static let maxToolRounds = 6

    // MARK: - Public entry point

    static func sendMessage(
        history: [ChatMessage],
        newUserMessage: String,
        imageData: Data? = nil,
        profile: UserProfile,
        weights: [WeightEntry],
        bodyFats: [BodyFatEntry],
        foods: [FoodEntry],
        useMetric: Bool
    ) async throws -> String {
        let systemPrompt = buildSystemPrompt(
            profile: profile,
            weights: weights,
            bodyFats: bodyFats,
            foods: foods,
            useMetric: useMetric
        )
        let tools = CoachTools(weights: weights, bodyFats: bodyFats, foods: foods, useMetric: useMetric)
        let toolDefs = toolDefinitions()

        var messages: [BackendClient.Message] = []
        for msg in history {
            messages.append(.init(
                role: msg.role == .user ? .user : .assistant,
                content: msg.content
            ))
        }
        messages.append(.init(
            role: .user,
            content: newUserMessage,
            imageBase64: imageData?.base64EncodedString()
        ))

        for _ in 0..<maxToolRounds {
            let response: BackendClient.GenerateResponse
            do {
                response = try await BackendClient.generate(
                    task: .chat,
                    system: systemPrompt,
                    messages: messages,
                    tools: toolDefs
                )
            } catch let err as BackendClient.BackendError {
                throw ChatError.backend(err)
            }

            // If the model called any tools, run them locally, append the
            // results as tool-role messages, and loop. Otherwise return text.
            if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                for call in toolCalls {
                    let args = call.arguments.mapValues { $0.rawValue }
                    let result = tools.execute(name: call.name, arguments: args)
                    messages.append(.init(
                        role: .tool,
                        toolCallID: call.id,
                        toolResult: result
                    ))
                }
                continue
            }

            if let text = response.text, !text.isEmpty {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            throw ChatError.invalidResponse
        }
        throw ChatError.toolRoundLimit
    }

    // MARK: - System prompt builder

    private static func buildSystemPrompt(profile: UserProfile, weights: [WeightEntry], bodyFats: [BodyFatEntry], foods: [FoodEntry], useMetric: Bool) -> String {
        let forecast = WeightAnalysisService.compute(weights: weights, foods: foods, profile: profile)
        let currentDateFormatter = DateFormatter()
        currentDateFormatter.dateFormat = "yyyy-MM-dd"
        currentDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        currentDateFormatter.timeZone = .current
        let currentDate = currentDateFormatter.string(from: Date())
        let currentTimeZone = TimeZone.current.identifier

        let wUnit: (Double) -> String = { kg in
            useMetric ? String(format: "%.1f kg", kg) : String(format: "%.1f lbs", kg * 2.20462)
        }
        let weekly: (Double) -> String = { kg in
            useMetric ? String(format: "%+.2f kg/week", kg) : String(format: "%+.2f lbs/week", kg * 2.20462)
        }

        let bmrFormula: String
        if profile.usesBodyFatForBMR {
            bmrFormula = "Katch-McArdle (uses body fat %)"
        } else if profile.bodyFatPercentage != nil {
            bmrFormula = "Mifflin-St Jeor (user disabled the body-fat override in Settings)"
        } else {
            bmrFormula = "Mifflin-St Jeor (body fat not set)"
        }

        var lines: [String] = []
        lines.append("You are Coach, an AI nutrition and weight-change assistant inside a calorie tracking app. Answer in plain English, be specific and factual, and ground your recommendations in the user's own data. Avoid medical advice; when relevant, suggest consulting a doctor. Be concise — 2–5 sentences per response unless the user asks for detail.")
        lines.append("")
        lines.append("## Current date")
        lines.append("- Today: \(currentDate) (\(currentTimeZone))")
        lines.append("- Treat \"today\" as \(currentDate) when choosing tool date ranges.")
        lines.append("")
        lines.append("## How to use the data tools")
        lines.append("You have access to functions that fetch the user's history on demand. The user profile + formulas + forecast below cover what's needed for most questions. Call a tool ONLY when the user asks about specific past dates, longer time ranges, individual meals, or trends that need raw data. Examples:")
        lines.append("- \"How was my weight in March?\" → call get_weight_history(from, to)")
        lines.append("- \"What did I eat last Tuesday?\" → call get_food_entries(from, to)")
        lines.append("- \"What's my data range?\" → call get_data_summary")
        lines.append("Do NOT call tools for questions you can answer from the profile/forecast below.")
        lines.append("")
        lines.append("## User profile")
        lines.append("- Gender: \(profile.gender.rawValue)")
        lines.append("- Age: \(profile.age)")
        lines.append("- Height: \(useMetric ? String(format: "%.0f cm", profile.heightCm) : String(format: "%.1f in", profile.heightCm / 2.54))")
        lines.append("- Current weight: \(wUnit(profile.weightKg))")
        lines.append("- Activity: \(profile.activityLevel.displayName)")
        lines.append("- Goal: \(profile.goal.displayName)")
        if let goal = profile.goalWeightKg {
            lines.append("- Goal weight: \(wUnit(goal))")
        }
        if let bf = profile.bodyFatPercentage {
            lines.append("- Body fat: \(Int(bf * 100))%")
        }
        if let goalBF = profile.goalBodyFatPercentage {
            lines.append("- Goal body fat: \(Int(goalBF * 100))%")
        }
        lines.append("")
        lines.append("## Formulas in use")
        lines.append("- BMR: \(bmrFormula). Current BMR ≈ \(Int(profile.bmr)) kcal/day")
        lines.append("- TDEE: BMR × activity multiplier ≈ \(Int(profile.tdee)) kcal/day")
        lines.append("- Calorie goal: \(profile.effectiveCalories) kcal/day")
        lines.append("- Macro targets: \(profile.effectiveProtein)g protein, \(profile.effectiveCarbs)g carbs, \(profile.effectiveFat)g fat")
        lines.append("")
        lines.append("## Computed forecast (from their logged data)")
        if forecast.hasEnoughData {
            lines.append("- Days of food logged (last 90d): \(forecast.daysOfFoodData)")
            lines.append("- Weight entries available: \(forecast.weightEntriesUsed)")
            lines.append("- Avg daily intake: \(forecast.avgDailyCalories) kcal")
            lines.append("- Daily energy balance: \(forecast.dailyEnergyBalance >= 0 ? "+" : "")\(forecast.dailyEnergyBalance) kcal")
            lines.append("- Predicted change (from diet): \(weekly(forecast.predictedWeeklyChangeKg))")
            if let observed = forecast.observedWeeklyChangeKg {
                lines.append("- Observed change (from scale): \(weekly(observed))")
            }
            lines.append("- Expected weight in 30 days: \(wUnit(forecast.predictedWeight30dKg))")
            lines.append("- Expected weight in 60 days: \(wUnit(forecast.predictedWeight60dKg))")
            lines.append("- Expected weight in 90 days: \(wUnit(forecast.predictedWeight90dKg))")
            if let days = forecast.daysToGoal {
                lines.append("- Days to goal at current pace: ~\(days) days")
            }
            if forecast.trendsDisagree {
                lines.append("- NOTE: Predicted and observed trends differ by >0.3 kg/week — user may be under-logging food.")
            }
        } else {
            lines.append("- Not enough data yet (need ≥2 days food + ≥2 weights). Encourage the user to log more.")
        }
        lines.append("")
        lines.append("## Data available")
        lines.append("- \(weights.count) weight entries, \(bodyFats.count) body-fat readings, \(foods.count) food entries logged total. Use get_data_summary to see exact date ranges.")
        lines.append("")
        lines.append("When the user asks how to lose or gain, give a concrete calorie target and at least one actionable food or activity change. When they ask expected weight, reference the forecast numbers above.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Tool definitions

    private static func toolDefinitions() -> [BackendClient.ToolDef] {
        let dateRangeSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "from": ["type": "string", "description": "ISO date yyyy-MM-dd, inclusive start"],
                "to": ["type": "string", "description": "ISO date yyyy-MM-dd, inclusive end"],
                "limit": ["type": "integer", "description": "Optional max entries to return"],
            ],
            "required": ["from", "to"],
        ]
        let summarySchema: [String: Any] = ["type": "object", "properties": [String: Any]()]

        return CoachTools.toolNames.map { name in
            BackendClient.ToolDef(
                name: name,
                description: CoachTools.toolDescriptions[name] ?? "",
                parameters: name == "get_data_summary" ? summarySchema : dateRangeSchema
            )
        }
    }
}
