//
//  ContentView.swift
//  calorietracker
//
//  Created by Apoorv Darshan on 05/02/26.
//

import SwiftUI

// MARK: - Color Theme
extension Color {
    static let appBackground = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let cardBackgroundLight = Color(red: 0.15, green: 0.15, blue: 0.18)
    static let accentTeal = Color(red: 0.0, green: 0.85, blue: 0.65)
    static let accentOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.55)
    static let textTertiary = Color(white: 0.4)
}

// MARK: - Main Content View
struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("Diary")
                }

            RecipesView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Recipes")
                }

            FastingView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Fasting")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .tint(Color.accentTeal)
    }
}

// MARK: - Today View (Main Dashboard)
struct TodayView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HeaderView()

                    // Main Content
                    VStack(spacing: 16) {
                        // Summary Section
                        SummaryCard()

                        // Nutrition Section
                        NutritionSection()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Title Section
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Text("Week 175")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Badges
                HStack(spacing: 8) {
                    // Calorie Goal Badge
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentTeal)
                        Text("2000")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())

                    // Streak Badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentOrange)
                        Text("135")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            // Calorie Ring Section
            HStack(spacing: 24) {
                // Eaten
                VStack(spacing: 4) {
                    Text("1,020")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Eaten")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                // Circular Progress
                ZStack {
                    // Background Circle
                    Circle()
                        .stroke(Color.cardBackgroundLight, lineWidth: 12)
                        .frame(width: 100, height: 100)

                    // Progress Arc
                    Circle()
                        .trim(from: 0, to: 0.51)
                        .stroke(
                            Color.accentTeal,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    // Center Text
                    VStack(spacing: 0) {
                        Text("868")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Remaining")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }

                // Protein
                VStack(spacing: 4) {
                    Text("Protein")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                    Text("46")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Macro Progress Bars
            HStack(spacing: 20) {
                MacroProgressBar(label: "Carbs", current: 97, goal: 207, unit: "g", color: .accentTeal)
                MacroProgressBar(label: "Protein", current: 46, goal: 115, unit: "g", color: .accentTeal)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Macro Progress Bar
struct MacroProgressBar: View {
    let label: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color

    var progress: CGFloat {
        min(CGFloat(current) / CGFloat(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cardBackgroundLight)
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(current) / \(goal) \(unit)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.textTertiary)
        }
    }
}

// MARK: - Nutrition Section
struct NutritionSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nutrition")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("More")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.accentTeal)
            }

            VStack(spacing: 0) {
                MealRow(
                    emoji: "🍳",
                    meal: "Breakfast",
                    calories: 466,
                    totalCalories: 566,
                    description: "Fried eggs with mix...",
                    hasAI: true,
                    isFirst: true
                )

                Divider()
                    .background(Color.cardBackgroundLight)
                    .padding(.leading, 56)

                MealRow(
                    emoji: "🍝",
                    meal: "Lunch",
                    calories: 354,
                    totalCalories: 755,
                    description: "Farfalle pasta with ca...",
                    hasAI: true,
                    isFirst: false
                )

                Divider()
                    .background(Color.cardBackgroundLight)
                    .padding(.leading, 56)

                MealRow(
                    emoji: "🥗",
                    meal: "Dinner",
                    calories: 0,
                    totalCalories: 679,
                    description: "Add food",
                    hasAI: false,
                    isFirst: false
                )

                Divider()
                    .background(Color.cardBackgroundLight)
                    .padding(.leading, 56)

                MealRow(
                    emoji: "🍎",
                    meal: "Snacks",
                    calories: 200,
                    totalCalories: 400,
                    description: "Apple, Almonds",
                    hasAI: false,
                    isFirst: false
                )
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

// MARK: - Meal Row
struct MealRow: View {
    let emoji: String
    let meal: String
    let calories: Int
    let totalCalories: Int
    let description: String
    let hasAI: Bool
    let isFirst: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Emoji Circle
            ZStack {
                Circle()
                    .fill(Color.cardBackgroundLight)
                    .frame(width: 44, height: 44)

                Text(emoji)
                    .font(.system(size: 20))
            }

            // Meal Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(meal)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }

                HStack(spacing: 6) {
                    Text("\(calories) / \(totalCalories) Cal")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)

                    if hasAI {
                        Text("AI")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Add Button
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.cardBackgroundLight)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Placeholder Views for Other Tabs
struct RecipesView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Recipes")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }
}

struct FastingView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Fasting")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Profile")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
