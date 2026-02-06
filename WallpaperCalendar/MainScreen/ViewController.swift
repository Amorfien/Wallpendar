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
            setNeedsStatusBarAppearanceUpdate()
            setNeedsUpdateOfHomeIndicatorAutoHidden()
            viewsToHide.forEach { $0.isHidden = isPreview }
            previewButton.setImage(.init(systemName: isPreview ? "eye" : "eye.slash"), for: .normal)
            previewButton.alpha = isPreview ? 0.25 : 1
        }
    }

    private lazy var viewsToHide: [UIView] = [
        loadButton,
        saveButton,
        verticalSlider,
        transparencySlider,
        calendarView.leftButton,
        calendarView.rightButton
    ]

    private let apiManager = APIManager()
    private var imageMode: ImageMode = .standart

    private var calendarHeight: Float = 250

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: R.Img.initialImages.randomElement())
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.addGestureRecognizer(longPressGestureRecognizer)
        return imageView
    }()

    private lazy var previewButton: SquareButton = {
        let button = SquareButton()
        button.setImage(.init(systemName: "eye.slash"), for: .normal)
        button.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)
        return button
    }()

    private lazy var loadButton: SquareButton = {
        let button = SquareButton()
        button.setImage(.init(systemName: "photo.on.rectangle.angled"), for: .normal)
        button.addTarget(self, action: #selector(loadImageFromLibrary), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: SquareButton = {
        let button = SquareButton()
        button.setImage(.init(systemName: "tray.and.arrow.down"), for: .normal)
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
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(UIImage.verticalArrows.withTintColor(.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()

    private lazy var transparencySlider: UISlider = {
        let slider = UISlider()
        slider.value = 0.5
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.tintColor = .white.withAlphaComponent(0.66)
        slider.addTarget(self, action: #selector(transparencyChanged(_:)), for: .valueChanged)
        slider.setThumbImage(UIImage.transparency.withTintColor(.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()

    private var calendarView = MonthCalendarView()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
    private lazy var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    private lazy var contextMenu = UIContextMenuInteraction(delegate: self)

    private lazy var photoPicker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        return picker
    }()

    override var prefersStatusBarHidden: Bool {
        return isPreview
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return isPreview
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .darkGray
        activityIndicator.color = .white
        view.addSubviews(backgroundImageView, loadButton, saveButton, previewButton, verticalSlider, transparencySlider, activityIndicator)
        backgroundImageView.addSubview(calendarView)

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        calendarView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(48)
            $0.height.equalTo(calendarHeight)
        }

        previewButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(4)
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
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        verticalSlider.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().offset((-R.Device.screenWidth / 2) + 32)
            let thumbSize = Float(verticalSlider.thumbImage(for: .normal)?.size.width ?? 56)
            $0.width.equalTo(R.Device.screenHeight + thumbSize - calendarHeight)
        }
        verticalSlider.transform = CGAffineTransform(rotationAngle: .pi / 2)

        transparencySlider.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(calendarView.snp.bottom).offset(2)
            $0.width.equalTo(calendarView)
        }
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
    private func transparencyChanged(_ sender: UISlider) {
        calendarView.backgroundColor = .darkCalendar.withAlphaComponent(CGFloat(sender.value))
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
        activityIndicator.startAnimating()
        apiManager.getImage(
            width: R.Device.screenScale * R.Device.screenWidth,
            height: R.Device.screenScale * R.Device.screenHeight,
            mode: imageMode) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    switch result {
                    case .success(let data):
                        self?.backgroundImageView.image = UIImage(data: data)
                    case .failure(let error):
                        print(error.localizedDescription)
                        var newImage: UIImage
                        repeat {
                            newImage = R.Img.initialImages.randomElement() ?? UIImage()
                        } while newImage.hash == self?.backgroundImageView.image?.hash
                        self?.backgroundImageView.image = newImage
                    }
                }
            }
    }

    @objc
    private func longPress() {
        backgroundImageView.addInteraction(contextMenu)
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
        activityIndicator.startAnimating()
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            if let error = error {
                self?.showAlert(title: "Ошибка", message: "Не удалось сохранить изображение: \(error.localizedDescription)")
            } else {
                self?.showAlert(title: "Успешно", message: "Обои сохранены в галерею")
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

extension ViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { _ in
            var childrens: [UIAction] = []
            ImageMode.allCases.forEach { mode in
                let action = UIAction(title: mode.title, state: self.imageMode == mode ? .on : .off) { _ in
                    self.imageMode = mode
                    self.tapGesture()
                }
                switch mode {
                case .blur1, .blur2: action.attributes = .disabled
                default: break
                }
                childrens.append(action)
            }
            return UIMenu(title: "Picture mode:", children: childrens)
        })
    }
}
