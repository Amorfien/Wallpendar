//
//  CalendarConfiguration.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 07.02.2026.
//

import UIKit

struct CalendarConfiguration {
    var size: CGSize
    var positionOffset: CGPoint
    var backgroundColor: UIColor
    var backgroundAlpha: CGFloat
    var dayTextColor: UIColor
    var weekendTextColor: UIColor
    var weekdayHeaderColor: UIColor
    var monthHeaderColor: UIColor
    var dayFontSize: CGFloat
    let minSize: CGSize

    init(size: CGSize,
         positionOffset: CGPoint,
         backgroundColor: UIColor = .blueCalendar,
         backgroundAlpha: CGFloat = 0.75,
         dayTextColor: UIColor = .white,
         weekendTextColor: UIColor = .weekendLight,
         weekdayHeaderColor: UIColor = .lightGray,
         monthHeaderColor: UIColor = .white.withAlphaComponent(0.85),
         dayFontSize: CGFloat = 16,
         minSize: CGSize = .init(width: 204, height: 192)) {
        self.size = size
        self.positionOffset = positionOffset
        self.backgroundColor = backgroundColor
        self.backgroundAlpha = backgroundAlpha
        self.dayTextColor = dayTextColor
        self.weekendTextColor = weekendTextColor
        self.weekdayHeaderColor = weekdayHeaderColor
        self.monthHeaderColor = monthHeaderColor
        self.dayFontSize = dayFontSize
        self.minSize = minSize
    }
}
