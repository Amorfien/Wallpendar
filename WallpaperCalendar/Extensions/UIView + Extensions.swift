//
//  UIView + Extensions.swift
//  xStitch
//
//  Created by Pavel Grigorev on 09.07.2024.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }
}
