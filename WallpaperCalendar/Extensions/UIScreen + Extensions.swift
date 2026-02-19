//
//  UIWindow + Extensions.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 10.02.2026.
//

import UIKit

extension UIScreen {

    static var currentBounds: CGRect {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.bounds
        }
        return .zero
    }

    static var currentWidth: CGFloat {
        currentBounds.width
    }

    static var currentHeight: CGFloat {
        currentBounds.height
    }

    static var currentScale: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.scale
        } else {
            return 3.0
        }
    }
}
