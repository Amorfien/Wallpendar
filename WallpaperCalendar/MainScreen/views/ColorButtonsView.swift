//
//  ColorButtonsView.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 13.02.2026.
//

import UIKit
import SnapKit

final class ColorButtonsView: UIView {

    var isColorButtonTapped: ((UIColor) -> Void)?

    private let buttonSize: CGFloat = 32
    private let spacing: CGFloat = 4

    private let colors: [UIColor] = [
        .lightCalendar,
        .darkCalendar,
        .grayCalendar,
        .greenCalendar,
        .blueCalendar,
        .orangeCalendar,
        .pinkCalendar,
        .yellowCalendar,
        .salatCalendar
    ]

    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let availableWidth = bounds.width
        let maxVisibleButtons = Int(floor((availableWidth + spacing) / (buttonSize + spacing)))
        for (index, button) in subviews.compactMap({ $0 as? UIButton }).enumerated() {
            button.isHidden = index >= maxVisibleButtons
        }
    }

    private func setupUI() {
        self.clipsToBounds = true
        self.snp.makeConstraints {
            $0.height.equalTo(buttonSize)
        }

        for (index, color) in colors.enumerated() {
            let button = UIButton()
            button.backgroundColor = color
            button.tag = index
            button.layer.cornerRadius = 3
            button.layer.borderWidth = 0.33
            button.layer.borderColor = UIColor.black.cgColor
            button.addTarget(self, action: #selector(colorButtonTap(_:)), for: .touchUpInside)
            self.addSubview(button)
            button.snp.makeConstraints {
                $0.size.equalTo(buttonSize)
                $0.top.equalToSuperview()
                $0.leading.equalToSuperview().offset(index * Int(buttonSize + spacing))
            }
        }
    }

    @objc
    private func colorButtonTap(_ sender: UIButton) {
        let newColor = colors[sender.tag]
        isColorButtonTapped?(newColor)
    }
}
