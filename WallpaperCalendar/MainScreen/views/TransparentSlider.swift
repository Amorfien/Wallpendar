//
//  TransparentSlider.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit

final class TransparentSlider: UISlider {

    private var calendarHeight: CGFloat = 250

    init() {
        super.init(frame: .zero)
        tintColor = .clear
        maximumTrackTintColor = .clear
        let screenHalfHeight = R.Device.screenHeight / 2
        value = 0
        maximumValue = Float(screenHalfHeight - (calendarHeight / 2))
        minimumValue = Float(-screenHalfHeight + (calendarHeight / 2))

        setThumbImage(UIImage.verticalArrows.withTintColor(.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal), for: .normal)

        /*
        let renderer = UIGraphicsImageRenderer(size: rotateSize)
        let image = renderer.image { context in
            // Ничего не рисуем - полностью прозрачное
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: rotateSize))
        }

        setThumbImage(image, for: .normal)
         */
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let thumbRect = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        let expandedThumbRect = thumbRect.insetBy(dx: -10, dy: -10)
        return expandedThumbRect.contains(point)
    }
}
