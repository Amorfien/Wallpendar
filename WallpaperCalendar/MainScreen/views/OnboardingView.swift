//
//  OnboardingView.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 28.02.2026.
//

import UIKit
import SnapKit

final class OnboardingView: UIView {

    private let imageSize = 180.0
    private let startImage = UIImage(systemName: "rectangle.and.hand.point.up.left.filled")
    private let secondImage = UIImage(systemName: "rectangle.and.hand.point.up.left.fill")

    private lazy var fingerView: UIImageView = {
        let view = UIImageView(image: startImage)
        view.tintColor = .white
        return view
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "onboarding.hint")
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation(completion: (() -> Void)? = nil) {
        fingerView.image = secondImage
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10.5, options: [.curveEaseInOut, .autoreverse], animations: { [weak self] in
            self?.fingerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } , completion: { [weak self] _ in
            self?.fingerView.transform = .identity
            self?.fingerView.image = self?.startImage
            completion?()
        })
    }

    private func setupUI() {
        isUserInteractionEnabled = false
        self.snp.makeConstraints {
            $0.size.equalTo(imageSize * 2 - 10)
        }
        self.addSubviews(fingerView, hintLabel)
        fingerView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview().offset(imageSize / 11)
            $0.size.equalTo(imageSize)
        }
        hintLabel.snp.makeConstraints {
            $0.top.equalTo(fingerView.snp.bottom)
            $0.centerX.equalToSuperview()
        }
    }
}
