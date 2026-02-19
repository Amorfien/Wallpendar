//
//  Resources.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit

enum R {

    enum Img {
        static let initialImages: [UIImage] = [
            .sample0,
            .sample1,
            .sample2,
            .sample3,
            .sample4,
            .sample5,
            .sample6,
            .sample7,
            .sample8,
            .sample9
        ]
        static let grayScaleImages: [UIImage] = [
            .sampleGrayscale0,
            .sampleGrayscale1,
            .sampleGrayscale2
        ]
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
