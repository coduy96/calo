import SwiftUI

struct AnalyzingView: View {
    let image: UIImage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 250, maxHeight: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)

            ProgressView()
                .controlSize(.large)

            Text("Analyzing your food...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
