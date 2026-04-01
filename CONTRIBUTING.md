# Contributing to Fud AI

Thanks for your interest in contributing!

## Getting Started

1. Fork the repo
2. Clone your fork
3. Open `calorietracker.xcodeproj` in Xcode
4. Build and run on a simulator or device

No external dependencies — just Xcode and a valid Apple developer account.

## Setup

Go to **Profile > AI Provider** in the app and add your API key for any supported provider (Gemini, OpenAI, Claude, etc.). Keys are stored locally in iOS Keychain.

## Code Style

- SwiftUI with `@Observable` (not `ObservableObject`)
- Environment injection via `.environment()` (not `environmentObject`)
- Main actor isolation is default — no manual `@MainActor` needed
- Services are stateless structs with static methods
- Xcode auto-discovers files — don't edit `project.pbxproj` manually

## Pull Requests

1. Create a branch from `main`
2. Keep changes focused — one feature or fix per PR
3. Test on a real device if possible
4. Write a clear PR description

## Reporting Issues

Open an issue at [github.com/apoorvdarshan/fud-ai/issues](https://github.com/apoorvdarshan/fud-ai/issues) with:
- Steps to reproduce
- Expected vs actual behavior
- Device and iOS version
- Screenshots if relevant

## Adding AI Providers

To add a new provider:

1. Add a case to `AIProvider` enum in `Models/AIProvider.swift`
2. Set its `baseURL`, `models`, `apiFormat`, and `apiKeyPlaceholder`
3. If it uses OpenAI-compatible format, it works automatically
4. If it needs a custom format, add a handler in `GeminiService.swift`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
