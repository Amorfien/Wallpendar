//
//  ViewController.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 05.02.2026.
//

import UIKit
import SnapKit
import Photos

class ViewController: UIViewController {

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: .snegir)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.init(systemName: "square.and.arrow.down"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.2)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(saveImageToLibrary), for: .touchUpInside)
        return button
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.init(systemName: "square.and.arrow.up"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.2)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(shareImage), for: .touchUpInside)
        return button
    }()

    private lazy var verticalSlider: UISlider = {
        let slider = UISlider()
        let screenHalfHeight = Float(UIScreen.main.bounds.height / 2)
        slider.value = 0
        slider.maximumValue = screenHalfHeight - 125
        slider.minimumValue = -screenHalfHeight + 125
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        return slider
    }()

    private var calendarView = MonthCalendarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBlue
        view.addSubviews(backgroundImageView, calendarView, saveButton, shareButton, verticalSlider)

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        calendarView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(48)
            $0.height.equalTo(250)
        }

        saveButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.size.equalTo(44)
        }
        shareButton.snp.makeConstraints {
            $0.top.size.equalTo(saveButton)
            $0.trailing.equalTo(saveButton.snp.leading).offset(-16)
        }
        verticalSlider.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(48)
            $0.top.equalTo(saveButton.snp.bottom).offset(16)
        }
    }

    private func getWallpaper() -> UIImage {
        let viewsToHide = [saveButton, shareButton, calendarView.stepper]
        viewsToHide.forEach {
            $0.alpha = 0
            $0.isHidden = true
        }
        view.layoutIfNeeded()

        // Конвертируем snapshot в UIImage
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        UIView.animate(withDuration: 1.2, delay: 2) {
            viewsToHide.forEach { $0.alpha = 1 }
        }
        viewsToHide.forEach { $0.isHidden = false }
        return image
    }

    @objc
    private func sliderValueChanged(_ sender: UISlider) {
        calendarView.snp.remakeConstraints {
            $0.centerY.equalToSuperview().offset(sender.value)
            $0.horizontalEdges.equalToSuperview().inset(48)
            $0.height.equalTo(250)
        }
    }

    @objc
    private func saveImageToLibrary() {

        let image = getWallpaper()

        // Запрашиваем разрешение на доступ к фото библиотеке
        requestPhotoLibraryPermission { [weak self] granted in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if granted {
                    self.saveImageToPhotoLibrary(image)
                } else {
                    self.showPermissionAlert()
                }
            }
        }
    }

    @objc
    private func shareImage() {
        let image = getWallpaper()

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = saveButton
        present(activityVC, animated: true)
    }

    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        // Показываем индикатор загрузки
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        // Сохраняем изображение
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // Убираем индикатор
        DispatchQueue.main.async {
            self.view.subviews
                .compactMap { $0 as? UIActivityIndicatorView }
                .forEach { $0.stopAnimating(); $0.removeFromSuperview() }

            if let error = error {
                self.showAlert(title: "Ошибка", message: "Не удалось сохранить изображение: \(error.localizedDescription)")
            } else {
                self.showAlert(title: "Успешно", message: "Обои сохранены в галерею")
            }
        }
    }

    private func showPermissionAlert() {
        showAlert(
            title: "Нет доступа к фото",
            message: "Пожалуйста, разрешите доступ к фото библиотеке в настройках приложения",
            primaryAction: UIAlertAction(title: "Настройки", style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsUrl)
            },
            secondaryAction: UIAlertAction(title: "Отмена", style: .cancel)
        )
    }

    private func showAlert(title: String, message: String,
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

