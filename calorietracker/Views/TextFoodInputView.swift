import SwiftUI

struct TextFoodInputView: View {
    @State private var foodDescription = ""
    @State private var placeholderIndex = 0
    @Environment(\.dismiss) private var dismiss

    var onSubmit: (String) -> Void

    private let placeholders = [
        "2 eggs, toast with butter and a coffee",
        "Chipotle burrito bowl with chicken and rice",
        "Domino's pepperoni pizza, 2 slices",
        "Greek yogurt with granola and blueberries",
    ]

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack(alignment: .leading) {
                    if foodDescription.isEmpty {
                        Text(placeholders[placeholderIndex])
                            .foregroundStyle(.tertiary)
                            .font(.title3)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .id(placeholderIndex)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $foodDescription, axis: .vertical)
                        .font(.title3)
                        .lineLimit(1...4)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)

                Button {
                    onSubmit(foodDescription)
                } label: {
                    Text("Analyze")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.calorie)
                .disabled(foodDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
                Spacer()
            }
            .background(AppColors.appBackground)
            .navigationTitle("Text Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onReceive(timer) { _ in
                guard foodDescription.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    placeholderIndex = (placeholderIndex + 1) % placeholders.count
                }
            }
        }
    }
}
