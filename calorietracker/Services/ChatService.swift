import Foundation

/// Routes a multi-turn chat (system context + user/assistant message history + new user message)
/// to the currently-selected LLM provider. Builds the system prompt from the user's live profile,
/// weight history, food log, and computed forecast so the model always answers with fresh data.
struct ChatService {
    enum ChatError: LocalizedError {
        case noAPIKey
        case networkError(Error)
        case apiError(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured. Add your key in Settings → AI Provider."
            case .networkError(let err):
                return "Network error: \(err.localizedDescription)"
            case .apiError(let msg):
                return "API error: \(msg)"
            case .invalidResponse:
                return "Could not understand the AI response. Please try again."
            }
        }
    }

    // MARK: - Public entry point

    static func sendMessage(
        history: [ChatMessage],
        newUserMessage: String,
        profile: UserProfile,
        weights: [WeightEntry],
        foods: [FoodEntry],
        useMetric: Bool
    ) async throws -> String {
        let systemPrompt = buildSystemPrompt(
            profile: profile,
            weights: weights,
            foods: foods,
            useMetric: useMetric
        )

        let provider = AIProviderSettings.selectedProvider
        let model = AIProviderSettings.selectedModel
        let baseURL = AIProviderSettings.currentBaseURL

        guard AIProviderSettings.currentAPIKey != nil || provider == .ollama else {
            throw ChatError.noAPIKey
        }

        switch provider.apiFormat {
        case .gemini:
            return try await callGemini(baseURL: baseURL, model: model, systemPrompt: systemPrompt, history: history, newUserMessage: newUserMessage)
        case .anthropic:
            return try await callAnthropic(baseURL: baseURL, model: model, systemPrompt: systemPrompt, history: history, newUserMessage: newUserMessage)
        case .openaiCompatible:
            return try await callOpenAICompatible(baseURL: baseURL, model: model, systemPrompt: systemPrompt, history: history, newUserMessage: newUserMessage, provider: provider)
        }
    }

    // MARK: - System prompt builder

    private static func buildSystemPrompt(profile: UserProfile, weights: [WeightEntry], foods: [FoodEntry], useMetric: Bool) -> String {
        let forecast = WeightAnalysisService.compute(weights: weights, foods: foods, profile: profile)

        let wUnit: (Double) -> String = { kg in
            useMetric ? String(format: "%.1f kg", kg) : String(format: "%.1f lbs", kg * 2.20462)
        }
        let weekly: (Double) -> String = { kg in
            useMetric ? String(format: "%+.2f kg/week", kg) : String(format: "%+.2f lbs/week", kg * 2.20462)
        }

        let bmrFormula = profile.bodyFatPercentage != nil ? "Katch-McArdle (uses body fat %)" : "Mifflin-St Jeor (body fat not set)"

        // Recent weights (last 10) compact line for LLM to reason about trend
        let recentWeights = weights.sorted { $0.date > $1.date }.prefix(10)
        let weightLog = recentWeights.reversed().map { entry -> String in
            let dateStr = ChatService.shortDateFormatter.string(from: entry.date)
            return "\(dateStr): \(wUnit(entry.weightKg))"
        }.joined(separator: ", ")

        // Recent foods by day (last 7 days of totals)
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentFoods = foods.filter { $0.timestamp >= weekAgo }
        var dailyCal: [String: Int] = [:]
        for entry in recentFoods {
            let dayKey = ChatService.shortDateFormatter.string(from: entry.timestamp)
            dailyCal[dayKey, default: 0] += entry.calories
        }
        let caloriesLog = dailyCal.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value) kcal" }.joined(separator: ", ")

        var lines: [String] = []
        lines.append("You are Coach, an AI nutrition and weight-change assistant inside a calorie tracking app. Answer in plain English, be specific and factual, and always ground your recommendations in the user's own data below. Avoid medical advice; when relevant, suggest consulting a doctor. Be concise — 2–5 sentences per response unless the user asks for detail.")
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
        if !weightLog.isEmpty {
            lines.append("## Recent weights (oldest → newest)")
            lines.append(weightLog)
            lines.append("")
        }
        if !caloriesLog.isEmpty {
            lines.append("## Last 7 days of calorie totals")
            lines.append(caloriesLog)
            lines.append("")
        }
        lines.append("When the user asks how to lose or gain, give a concrete calorie target and at least one actionable food or activity change. When they ask expected weight, reference the forecast numbers above.")
        return lines.joined(separator: "\n")
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    // MARK: - Gemini (v1beta generateContent with system_instruction)

    private static func callGemini(baseURL: String, model: String, systemPrompt: String, history: [ChatMessage], newUserMessage: String) async throws -> String {
        guard let apiKey = AIProviderSettings.currentAPIKey else { throw ChatError.noAPIKey }
        guard let url = URL(string: "\(baseURL)/models/\(model):generateContent") else {
            throw ChatError.apiError("Invalid API URL.")
        }

        var contents: [[String: Any]] = []
        for msg in history {
            let role = msg.role == .user ? "user" : "model"
            contents.append(["role": role, "parts": [["text": msg.content]]])
        }
        contents.append(["role": "user", "parts": [["text": newUserMessage]]])

        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": systemPrompt]]],
            "contents": contents,
        ]

        let data = try await send(
            url: url,
            headers: ["Content-Type": "application/json", "X-goog-api-key": apiKey],
            body: body
        )

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            throw ChatError.invalidResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - OpenAI-compatible (/chat/completions)

    private static func callOpenAICompatible(baseURL: String, model: String, systemPrompt: String, history: [ChatMessage], newUserMessage: String, provider: AIProvider) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw ChatError.apiError("Invalid API URL.")
        }
        var messages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
        for msg in history {
            messages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        messages.append(["role": "user", "content": newUserMessage])

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
        ]

        var headers = ["Content-Type": "application/json"]
        if let apiKey = AIProviderSettings.currentAPIKey {
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        if provider == .openrouter {
            headers["HTTP-Referer"] = "https://github.com/apoorvdarshan/fud-ai"
            headers["X-Title"] = "Fud AI"
        }

        let data = try await send(url: url, headers: headers, body: body)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw ChatError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Anthropic Messages API

    private static func callAnthropic(baseURL: String, model: String, systemPrompt: String, history: [ChatMessage], newUserMessage: String) async throws -> String {
        guard let apiKey = AIProviderSettings.currentAPIKey else { throw ChatError.noAPIKey }
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw ChatError.apiError("Invalid API URL.")
        }
        var messages: [[String: Any]] = []
        for msg in history {
            messages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        messages.append(["role": "user", "content": newUserMessage])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": messages,
        ]

        let data = try await send(
            url: url,
            headers: [
                "Content-Type": "application/json",
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
            ],
            body: body
        )

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstText = contentArray.first(where: { ($0["type"] as? String) == "text" }),
              let text = firstText["text"] as? String
        else {
            throw ChatError.invalidResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Shared HTTP

    private static func send(url: URL, headers: [String: String], body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Retry transient overload responses (503/429/529) with exponential backoff: 1s, 2s, 4s.
        // Mirrors GeminiService — "model experiencing high demand" is usually a global throttle
        // on the chosen model, so a quick retry resolves it invisibly most of the time.
        let retryDelaysNs: [UInt64] = [1_000_000_000, 2_000_000_000, 4_000_000_000]
        var lastError: ChatError = .apiError("Request failed")

        for attempt in 0...retryDelaysNs.count {
            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch {
                throw ChatError.networkError(error)
            }

            guard let http = response as? HTTPURLResponse else { return data }

            if http.statusCode == 200 { return data }

            let parsed = parseErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            lastError = .apiError(friendlyMessage(for: http.statusCode, raw: parsed))

            let isRetryable = http.statusCode == 503
                           || http.statusCode == 529
                           || http.statusCode == 429
            if isRetryable && attempt < retryDelaysNs.count {
                try? await Task.sleep(nanoseconds: retryDelaysNs[attempt])
                continue
            }
            throw lastError
        }
        throw lastError
    }

    private static func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        if let message = json["error"] as? String {
            return message
        }
        return nil
    }

    private static func friendlyMessage(for status: Int, raw: String) -> String {
        switch status {
        case 503, 529:
            return "The AI provider is overloaded right now. We retried a few times — please try again in a minute, or switch to a different provider/model in Settings → AI Provider."
        case 429:
            return "Rate limit hit on your API key. Wait a minute, or switch to another provider in Settings → AI Provider."
        case 401, 403:
            return "Your API key was rejected. Open Settings → AI Provider and re-paste a valid key."
        default:
            return raw
        }
    }
}
