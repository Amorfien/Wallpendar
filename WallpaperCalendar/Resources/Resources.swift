//
//  Resources.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit

enum R {

    enum Img {
        static let snegir = UIImage.snegir
        static let sova = UIImage.sova
        static let loshad = UIImage.loshad
        static let initialImages = [snegir, sova, loshad]
    }

    enum Device {
        static let screenHeight = UIScreen.main.bounds.height
        static let screenWidth = UIScreen.main.bounds.width
        static let screenScale = UIScreen.main.scale
    }
}
