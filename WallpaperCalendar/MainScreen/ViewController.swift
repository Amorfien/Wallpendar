//
//  ViewController.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 05.02.2026.
//

import UIKit
import SnapKit
import PhotosUI

class ViewController: UIViewController {

    private lazy var isPreview: Bool = false {
        didSet {
            viewsToHide.forEach { $0.isHidden = isPreview }
            previewButton.setImage(.init(systemName: isPreview ? "eye" : "eye.slash"), for: .normal)
            previewButton.alpha = isPreview ? 0.33 : 1
        }
    }

    private lazy var viewsToHide: [UIView] = [
        loadButton,
        saveButton,
        verticalSlider,
        calendarView.leftButton,
        calendarView.rightButton
    ]

    private let apiManager = APIManager()
    private var imageMode: ImageMode = .grayscale

    private var calendarHeight: Float = 250

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: R.Img.initialImages.randomElement())
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        return imageView
    }()

    private lazy var previewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.init(systemName: "eye.slash"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.2)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)
        return button
    }()

    private lazy var loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.init(systemName: "photo.on.rectangle.angled"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.2)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(loadImageFromLibrary), for: .touchUpInside)
        return button
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

    private lazy var verticalSlider: TransparentSlider = {
        let slider = TransparentSlider()
        let screenHalfHeight = R.Device.screenHeight / 2
        slider.value = 0
        slider.maximumValue = screenHalfHeight - (calendarHeight / 2)
        slider.minimumValue = -screenHalfHeight + (calendarHeight / 2)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.tintColor = .clear
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(UIImage.verticalArrowsFill.withTintColor(.white.withAlphaComponent(0.5), renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()

    private var calendarView = MonthCalendarView()

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))

    private lazy var photoPicker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        return picker
    }()

    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBlue
        view.addSubviews(backgroundImageView, calendarView, loadButton, saveButton, previewButton, verticalSlider)

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        calendarView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(48)
            $0.height.equalTo(calendarHeight)
        }

        previewButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(12)
            $0.size.equalTo(44)
        }
        loadButton.snp.makeConstraints {
            $0.trailing.size.equalTo(previewButton)
            $0.top.equalTo(previewButton.snp.bottom).offset(12)
        }
        saveButton.snp.makeConstraints {
            $0.trailing.size.equalTo(previewButton)
            $0.top.equalTo(loadButton.snp.bottom).offset(12)
        }

        verticalSlider.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().offset((-R.Device.screenWidth / 2) + 49)
            let thumbSize = Float(verticalSlider.thumbImage(for: .normal)?.size.width ?? 56)
            $0.width.equalTo(R.Device.screenHeight + thumbSize - calendarHeight)
        }
        verticalSlider.transform = CGAffineTransform(rotationAngle: .pi / 2)
    }

    // MARK: - Actions
    @objc
    private func sliderValueChanged(_ sender: UISlider) {
        calendarView.snp.remakeConstraints {
            $0.centerY.equalToSuperview().offset(sender.value)
            $0.horizontalEdges.equalToSuperview().inset(48)
            $0.height.equalTo(calendarHeight)
        }
    }

    @objc
    private func loadImageFromLibrary() {
        present(photoPicker, animated: true)
    }

    @objc
    private func previewTapped() {
        isPreview.toggle()
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
    private func tapGesture() {
        apiManager.getImage(
            width: R.Device.screenScale * R.Device.screenWidth,
            height: R.Device.screenScale * R.Device.screenHeight,
            mode: imageMode) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async { [weak self] in
                    self?.backgroundImageView.image = UIImage(data: data)
                }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    self?.backgroundImageView.image = R.Img.initialImages.randomElement()
                }
            }
        }
    }

    // MARK: - Private Methods
    private func getWallpaper() -> UIImage {
        var views = viewsToHide
        views.append(previewButton)
        views.forEach {
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
            views.forEach { $0.alpha = 1 }
        }
        views.forEach { $0.isHidden = false }
        return image
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
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self, let image = image as? UIImage else { return }
            DispatchQueue.main.async { [weak self] in
                self?.backgroundImageView.image = image
            }
        }
    }
}
