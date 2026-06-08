import SwiftUI

struct AnalyzingView: View {
    let image: UIImage?
    var systemIcon: String = "text.magnifyingglass"
    var message: LocalizedStringKey = "Analyzing your food…"
    var subMessages: [LocalizedStringKey] = []
    var onCancel: (() -> Void)? = nil

    var body: some View {
        VoidpenLoadingHero(
            image: image,
            systemIcon: systemIcon,
            message: message,
            subMessages: subMessages,
            onCancel: onCancel
        )
    }
}
