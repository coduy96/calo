# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Fud AI, please report it **privately** so it can be addressed before public disclosure.

**Preferred:** Use GitHub's [private vulnerability reporting](https://github.com/apoorvdarshan/fud-ai/security/advisories/new) — it's end-to-end private and routes directly to the maintainer.

**Alternative:** Email either of:

- **apoorv@fud-ai.app**
- **ad13dtu@gmail.com**

Please include:

- A description of the vulnerability
- Steps to reproduce (a minimal PoC is ideal)
- Affected versions (if known — check **Settings → About** in the app, or the latest `MARKETING_VERSION` in `project.pbxproj`)
- Any potential impact — data exposure, API-key leakage, code execution, etc.
- Your name / handle if you want credit in the release notes (optional)

You can expect an initial acknowledgement within **7 days**, and a more detailed response (triage + estimated fix timeline) within **14 days**. Please do not disclose the issue publicly until a fix has shipped to the App Store.

## Supported Versions

Only the latest released version on the App Store is supported with security updates. The repository's `main` branch tracks the next release.

## Scope

**In scope:**

- The iOS app source in this repository (SwiftUI codebase, widget extension, tests targets)
- API-key handling and iOS Keychain storage (`KeychainHelper`, `AIProviderSettings`, `SpeechSettings`)
- Network requests to AI and speech-to-text providers (`GeminiService`, `ChatService`, `SpeechService`)
- HealthKit read/write paths (`HealthKitManager`) and UUID-tagged sample conventions
- Widget App Group container (`group.com.apoorvdarshan.calorietracker`) and the snapshot written into it
- Local persistence layer (`UserDefaults`, Keychain) including the Coach chat history and food/weight logs

**Out of scope:**

- Vulnerabilities in third-party AI providers (report to them directly — OpenAI, Anthropic, Google, xAI, etc.)
- Vulnerabilities in third-party speech-to-text providers (report to them — Deepgram, AssemblyAI, etc.)
- Issues requiring physical device access with the device unlocked
- Social-engineering attacks against users' own API keys
- Denial-of-service against the user's own AI provider via API quota exhaustion (that's a user-controlled cost, not a security boundary)
- Issues in the marketing website ([fud-ai-web](https://github.com/apoorvdarshan/fud-ai-web)) — that's a separate repo with its own security disclosure path, though you can use the same contact emails

## Safe Harbor

If you make a good-faith effort to comply with this policy during security research, we will not pursue or support any legal action related to your research. Please don't access or modify user data, avoid service disruption, and give us reasonable time to fix issues before disclosure.

## Credit

Researchers who responsibly disclose valid vulnerabilities will be credited in the release notes and in the commit message that ships the fix (unless they request to remain anonymous).
