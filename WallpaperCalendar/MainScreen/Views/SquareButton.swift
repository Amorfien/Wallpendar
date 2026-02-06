//
//  SquareButton.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit

final class SquareButton: UIButton {

    convenience init() {
        self.init(type: .system)
        setupButton()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    // MARK: - Setup
    private func setupButton() {
        backgroundColor = .black.withAlphaComponent(0.2)
        tintColor = .white
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.cgColor
    }

}
