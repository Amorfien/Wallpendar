//
//  UIViewController + Extensions.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 06.02.2026.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String, message: String,
                   primaryAction: UIAlertAction? = nil,
                   secondaryAction: UIAlertAction? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let primaryAction = primaryAction {
            alert.addAction(primaryAction)
        }
        
        if let secondaryAction = secondaryAction {
            alert.addAction(secondaryAction)
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }
}
