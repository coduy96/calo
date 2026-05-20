import Foundation

/// Single entry point for every paid LLM feature. The backend (Supabase Edge
/// Function at `${BackendConfig.baseURL}/api`) handles auth (via the
/// X-Install-ID header), per-install quotas, and the actual LLM call —
/// provider/model are picked server-side from `app_config`, so we never know
/// or care what's running behind it. Restoring a purchase moves the
/// entitlement via the RevenueCat TRANSFER webhook; the same install_id keeps
/// working.
enum BackendClient {
    // MARK: - Wire format

    /// Normalized provider-agnostic message. Maps cleanly to Gemini's
    /// contents[], OpenAI's messages[], or Anthropic's messages[] on the
    /// server side. Tool turns use `role: .tool` + `toolCallID` + `toolResult`.
    struct Message: Encodable {
        enum Role: String, Encodable {
            case user
            case assistant
            case tool
        }
        let role: Role
        let content: String?
        let imageBase64: String?
        let toolCallID: String?
        let toolResult: String?

        init(role: Role, content: String? = nil, imageBase64: String? = nil, toolCallID: String? = nil, toolResult: String? = nil) {
            self.role = role
            self.content = content
            self.imageBase64 = imageBase64
            self.toolCallID = toolCallID
            self.toolResult = toolResult
        }

        enum CodingKeys: String, CodingKey {
            case role
            case content
            case imageBase64 = "image_base64"
            case toolCallID = "tool_call_id"
            case toolResult = "tool_result"
        }
    }

    /// Tool definition forwarded to the LLM. `parameters` is a JSON Schema —
    /// kept as Data so callers can hand-build the JSON shape provider-style
    /// without going through Codable gymnastics.
    struct ToolDef {
        let name: String
        let description: String
        let parameters: [String: Any]
    }

    struct ToolCall: Decodable {
        let id: String
        let name: String
        let arguments: [String: AnyJSON]
    }

    struct GenerateResponse: Decodable {
        let text: String?
        let toolCalls: [ToolCall]?

        enum CodingKeys: String, CodingKey {
            case text
            case toolCalls = "tool_calls"
        }
    }

    enum Task: String {
        case food
        case label
        case chat
        case weight
        case goals
    }

    enum BackendError: LocalizedError {
        case missingBackendURL
        case subscriptionRequired
        case quotaExceeded
        case network(Error)
        case upstream(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingBackendURL:
                return String(localized: "App is misconfigured: missing backend URL.")
            case .subscriptionRequired:
                return String(localized: "Subscription required.")
            case .quotaExceeded:
                return String(localized: "You've hit today's usage limit. Try again tomorrow.")
            case .network(let err):
                return String(localized: "Network error: \(err.localizedDescription)")
            case .upstream(let msg):
                return String(localized: "Server error: \(msg)")
            case .invalidResponse:
                return String(localized: "Unexpected response from the server.")
            }
        }
    }

    // MARK: - Public API

    static func generate(
        task: Task,
        system: String? = nil,
        messages: [Message],
        tools: [ToolDef] = []
    ) async throws -> GenerateResponse {
        var body: [String: Any] = [
            "task": task.rawValue,
            "messages": messages.map(encodeMessage),
        ]
        if let system, !system.isEmpty {
            body["system"] = system
        }
        if !tools.isEmpty {
            body["tools"] = tools.map { tool in
                [
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.parameters,
                ] as [String: Any]
            }
        }
        let data = try await postJSON(path: "generate", body: body)
        do {
            return try JSONDecoder().decode(GenerateResponse.self, from: data)
        } catch {
            throw BackendError.invalidResponse
        }
    }

    static func transcribe(audioData: Data, mimeType: String = "audio/m4a", languageCode: String? = nil) async throws -> String {
        var body: [String: Any] = [
            "audio_base64": audioData.base64EncodedString(),
            "mime_type": mimeType,
        ]
        if let languageCode {
            body["language"] = languageCode
        }
        let data = try await postJSON(path: "transcribe", body: body)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String,
              !text.isEmpty
        else {
            throw BackendError.invalidResponse
        }
        return text
    }

    // MARK: - HTTP

    private static func postJSON(path: String, body: [String: Any]) async throws -> Data {
        guard let url = BackendConfig.url(for: path) else {
            throw BackendError.missingBackendURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ios", forHTTPHeaderField: "X-Voidpen-Platform")
        request.setValue(AppIdentity.installID, forHTTPHeaderField: "X-Install-ID")
        // Backwards-compat header for any old route still keyed on the legacy name.
        request.setValue(AppIdentity.installID, forHTTPHeaderField: "X-Voidpen-Install-ID")
        if let anonKey = BackendConfig.anonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        // Long timeout for transcribe — base64 audio uploads add seconds on
        // slow networks and Gemini audio transcription itself can take 5–10s.
        request.timeoutInterval = 60

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BackendError.network(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        if http.statusCode == 402 {
            throw BackendError.subscriptionRequired
        }
        if http.statusCode == 429 {
            throw BackendError.quotaExceeded
        }
        if !(200..<300).contains(http.statusCode) {
            let message = parseErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw BackendError.upstream(message)
        }
        return data
    }

    private static func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (json["message"] as? String) ?? (json["error"] as? String)
    }

    private static func encodeMessage(_ msg: Message) -> [String: Any] {
        var out: [String: Any] = ["role": msg.role.rawValue]
        if let v = msg.content { out["content"] = v }
        if let v = msg.imageBase64 { out["image_base64"] = v }
        if let v = msg.toolCallID { out["tool_call_id"] = v }
        if let v = msg.toolResult { out["tool_result"] = v }
        return out
    }
}

// MARK: - AnyJSON helper

/// Wraps Codable's lack of a built-in heterogeneous JSON value type. Decoding
/// `arguments: { ... }` from a tool call needs to handle whatever shape the
/// LLM emits; callers usually re-serialize this to JSON to hand to whatever
/// downstream parser they have.
enum AnyJSON: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([AnyJSON])
    case object([String: AnyJSON])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(Double.self) { self = .number(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([AnyJSON].self) { self = .array(v); return }
        if let v = try? c.decode([String: AnyJSON].self) { self = .object(v); return }
        self = .null
    }

    var rawValue: Any {
        switch self {
        case .string(let v): return v
        case .number(let v): return v
        case .bool(let v): return v
        case .null: return NSNull()
        case .array(let arr): return arr.map { $0.rawValue }
        case .object(let obj): return obj.mapValues { $0.rawValue }
        }
    }
}
