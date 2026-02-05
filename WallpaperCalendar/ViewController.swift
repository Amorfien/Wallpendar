//
//  ViewController.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 05.02.2026.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

//    let calendarView = MonthCalendarView()
//    calendarView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)

    let calendarView = MonthCalendarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue

        view.addSubview(calendarView)

        calendarView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 300, height: 250))    // min 170x170
        }
    }

    private func saveImageToLibrary() {
//        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
//        view.layer.render(in: UIGraphicsGetCurrentContext()!)
//        let wallpaperImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()

        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            calendarView.layer.render(in: context.cgContext)
        }
    }
}

