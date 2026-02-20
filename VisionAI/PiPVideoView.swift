import SwiftUI
import AVFoundation
import CoreMedia

class PiPContainerView: UIView {
    let pipLayer: AVSampleBufferDisplayLayer

    init(pipLayer: AVSampleBufferDisplayLayer) {
        self.pipLayer = pipLayer
        super.init(frame: .zero)
        backgroundColor = .clear
        transform = CGAffineTransform(scaleX: -1, y: 1)
        layer.addSublayer(pipLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pipLayer.frame = bounds
        CATransaction.commit()
    }
}

struct PiPVideoView: UIViewRepresentable {
    let pipLayer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> PiPContainerView {
        return PiPContainerView(pipLayer: pipLayer)
    }

    func updateUIView(_ uiView: PiPContainerView, context: Context) {}
}
