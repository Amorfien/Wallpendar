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
        static var screenHeight: CGFloat {
            UIScreen.currentHeight
        }
        static var screenWidth: CGFloat {
            UIScreen.currentWidth
        }
        static var screenScale: CGFloat {
            UIScreen.currentScale
        }
    }
}
