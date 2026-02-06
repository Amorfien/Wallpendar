//
//  TransparentSlider.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit

final class TransparentSlider: UISlider {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let thumbRect = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        let expandedThumbRect = thumbRect.insetBy(dx: -10, dy: -10) // Расширяем область ползунка
        return expandedThumbRect.contains(point)
    }
}
