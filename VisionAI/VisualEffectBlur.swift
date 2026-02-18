import SwiftUI
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    init(blurStyle: UIBlurEffect.Style = .systemMaterialDark) {
        self.blurStyle = blurStyle
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        view.effect = UIBlurEffect(style: blurStyle)
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        DispatchQueue.main.async {
            uiView.effect = UIBlurEffect(style: blurStyle)
        }
    }
}
