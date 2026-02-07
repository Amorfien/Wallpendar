//
//  SquareButton.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit
import SnapKit

final class SquareButton: UIButton {

    var isButtonTapped: (() -> Void)?

    convenience init(with image: UIImage?) {
        self.init(type: .system)
        setImage(image, for: .normal)
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
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        self.snp.makeConstraints {
            $0.size.equalTo(44)
        }
    }

    @objc
    private func buttonTapped() { isButtonTapped?() }
}
