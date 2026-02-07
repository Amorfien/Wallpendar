//
//  CalendarConfiguration.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 07.02.2026.
//

import UIKit

struct CalendarConfiguration {
    var backgroundColor: UIColor
    var backgroundAlpha: CGFloat
    var dayTextColor: UIColor
    var weekendTextColor: UIColor
    var weekdayHeaderColor: UIColor
    var monthHeaderColor: UIColor
    var dayFontSize: CGFloat

    init(backgroundColor: UIColor = .darkCalendar,
         backgroundAlpha: CGFloat = 0.5,
         dayTextColor: UIColor = .white,
         weekendTextColor: UIColor = .weekend,
         weekdayHeaderColor: UIColor = .lightGray,
         monthHeaderColor: UIColor = .white.withAlphaComponent(0.85),
         dayFontSize: CGFloat = 16) {
        self.backgroundColor = backgroundColor
        self.backgroundAlpha = backgroundAlpha
        self.dayTextColor = dayTextColor
        self.weekendTextColor = weekendTextColor
        self.weekdayHeaderColor = weekdayHeaderColor
        self.monthHeaderColor = monthHeaderColor
        self.dayFontSize = dayFontSize
    }
}
