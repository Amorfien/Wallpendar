//
//  ResizeHandleView.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 27.02.2026.
//


import UIKit

final class ResizeHandleView: UIView {
    
    private let cornerRadius: CGFloat = 16
    private let thickness: CGFloat = 12

    private let shapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        let size = CGSize(width: 44, height: 44)
        super.init(frame: CGRect(origin: .zero, size: size))
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isUserInteractionEnabled = true
        backgroundColor = .clear

        shapeLayer.fillColor = UIColor.gray.withAlphaComponent(0.6).cgColor
        layer.addSublayer(shapeLayer)
        print(frame)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        shapeLayer.path = makePath().cgPath
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        shapeLayer.lineWidth = 1.3
    }
    
    private func makePath() -> UIBezierPath {
        
        let path = UIBezierPath()
        
        let R = cornerRadius
        let t = thickness

        let center = CGPoint(
            x: bounds.width - R,
            y: bounds.height - R
        )
        
        // Внешняя дуга
        path.addArc(
            withCenter: center,
            radius: R + t / 2,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )

        // Нижний наконечник
        let bottomCapCenter = CGPoint(
            x: center.x,
            y: center.y + R
        )

        path.addArc(
            withCenter: bottomCapCenter,
            radius: t / 2,
            startAngle: .pi / 2,
            endAngle: -.pi / 2,
            clockwise: true
        )

        // Внутренняя дуга
        path.addArc(
            withCenter: center,
            radius: R - t / 2,
            startAngle: .pi / 2,
            endAngle: 0,
            clockwise: false
        )

        // Правый наконечник
        let rightCapCenter = CGPoint(
            x: center.x + R,
            y: center.y
        )

        path.addArc(
            withCenter: rightCapCenter,
            radius: t / 2,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )

        path.close()

        return path
    }
}
