import SwiftUI
import UIKit

struct MinuteWheelPicker: UIViewRepresentable {
    let range: ClosedRange<Int>
    @Binding var selection: Int
    var rowHeight: CGFloat = 50

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator

        let initialRow = max(range.lowerBound, min(range.upperBound, selection)) - range.lowerBound
        picker.selectRow(initialRow, inComponent: 0, animated: false)

        picker.backgroundColor = .clear
        picker.subviews.forEach { $0.backgroundColor = .clear }
        
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        let desiredRow = selection - range.lowerBound
        if uiView.selectedRow(inComponent: 0) != desiredRow {
            uiView.selectRow(desiredRow, inComponent: 0, animated: true)
        }
        uiView.setNeedsLayout()
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: MinuteWheelPicker

        init(_ parent: MinuteWheelPicker) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.range.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            parent.rowHeight
        }
        
        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            return pickerView.bounds.width
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {

            let label = (view as? UILabel) ?? UILabel()
            
            label.textAlignment = .center
            label.backgroundColor = .clear
            label.textColor = .white
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5

            let value = parent.range.lowerBound + row
            label.text = String(format: "%02d", value)

            guard let scrollView = pickerView.subviews.compactMap({ $0 as? UIScrollView }).first else {
                label.font = .systemFont(ofSize: 30, weight: .black)
                return label
            }

            let rowCenterY = CGFloat(row) * parent.rowHeight
            let pickerCenterY = scrollView.contentOffset.y + scrollView.bounds.midY
            let distance = abs(rowCenterY - pickerCenterY)
            let normalized = min(distance / parent.rowHeight, 1.0)

            let maxFont: CGFloat = 80
            let minFont: CGFloat = 35
            
            let fontSize = max(minFont, maxFont - (normalized * 45))
            
            let alpha = max(0.5, 1.0 - (normalized * 0.5))
            
            let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .black)
            if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                label.font = UIFont(descriptor: descriptor, size: fontSize)
            } else {
                label.font = systemFont
            }
            
            label.alpha = alpha

            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let value = parent.range.lowerBound + row
            DispatchQueue.main.async {
                self.parent.selection = value
            }
        }
    }
}
