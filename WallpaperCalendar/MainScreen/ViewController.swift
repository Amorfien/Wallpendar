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
        reloadButton,
        galleryButton,
        saveButton,
        transparencySlider,
        calendarView.leftButton,
        calendarView.rightButton
    ]

    private let apiManager = APIManager()
    private var imageMode: ImageMode = .standart

    private var calendarHeight: CGFloat = 250

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: R.Img.initialImages.randomElement())
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let reloadButton = SquareButton(with: .init(systemName: "arrow.trianglehead.2.clockwise"))
    private let previewButton = SquareButton(with: .init(systemName: "eye.slash"))
    private let galleryButton = SquareButton(with: .init(systemName: "photo.on.rectangle.angled"))
    private let saveButton = SquareButton(with: .init(systemName: "tray.and.arrow.down"))

    private lazy var transparencySlider: UISlider = {
        let slider = UISlider()
        slider.value = 0.5
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.addTarget(self, action: #selector(transparencyChanged(_:)), for: .valueChanged)
        slider.setThumbImage(UIImage.transparency.withTintColor(.tintColor, renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()

    private var calendarView = MonthCalendarView()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

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
        buttonsBinding()
    }

    private func setupUI() {
        view.backgroundColor = .darkGray
        activityIndicator.color = .white
        view.addSubviews(backgroundImageView,
                         calendarView,
                         reloadButton,
                         galleryButton,
                         saveButton,
                         previewButton,
                         transparencySlider,
                         activityIndicator)

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        calendarView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(R.Device.screenWidth - 96)
            $0.height.equalTo(calendarHeight)
        }
        reloadButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(4)
        }
        previewButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(4)
        }
        galleryButton.snp.makeConstraints {
            $0.trailing.equalTo(previewButton)
            $0.top.equalTo(previewButton.snp.bottom).offset(12)
        }
        saveButton.snp.makeConstraints {
            $0.trailing.equalTo(previewButton)
            $0.top.equalTo(galleryButton.snp.bottom).offset(12)
        }
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        transparencySlider.snp.makeConstraints {
            $0.top.equalTo(calendarView.snp.bottom)
            $0.centerX.width.equalTo(calendarView)
        }
    }

    // MARK: - Binding
    private func buttonsBinding() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPress.minimumPressDuration = 1.2
        reloadButton.addGestureRecognizer(longPress)
        reloadButton.isButtonTapped = { [weak self] in
            guard let self else { return }
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

        previewButton.isButtonTapped = { [weak self] in
            self?.isPreview.toggle()
        }

        galleryButton.isButtonTapped = { [weak self] in
            guard let self else { return }
            activityIndicator.startAnimating()
            present(photoPicker, animated: true) { [weak self] in
                self?.activityIndicator.stopAnimating()
            }
        }

        saveButton.isButtonTapped = { [weak self] in
            guard let self else { return }
            let image = buildWallpaper()

            requestPhotoLibraryPermission { [weak self] granted in
                guard let self else { return }

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if granted {
                        activityIndicator.startAnimating()
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    } else {
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
            }
        }

        calendarView.isChangePosition = { [weak self] offset in
            guard let self else { return }

            calendarView.snp.remakeConstraints {
                $0.centerX.equalToSuperview().offset(offset.x)
                $0.centerY.equalToSuperview().offset(offset.y)
                $0.width.equalTo(R.Device.screenWidth - 96)
                $0.height.equalTo(self.calendarHeight)
            }
        }
    }

    // MARK: - Actions

    @objc
    private func transparencyChanged(_ sender: UISlider) {
        calendarView.backgroundColor = .darkCalendar.withAlphaComponent(CGFloat(sender.value))
    }

    @objc
    private func longPress() {
        reloadButton.addInteraction(contextMenu)
    }

    // MARK: - Private Methods
    private func buildWallpaper() -> UIImage {
        var views = viewsToHide
        views.append(previewButton)
        views.forEach {
            $0.alpha = 0
            $0.isHidden = true
        }
        view.layoutIfNeeded()

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
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            guard let self else { return nil }
            var childrens: [UIAction] = []
            ImageMode.allCases.forEach { mode in
                let action = UIAction(title: mode.title, state: self.imageMode == mode ? .on : .off) { _ in
                    self.imageMode = mode
                    self.reloadButton.isButtonTapped?()
                }
                switch mode {
//                case .blur1, .blur2: action.attributes = .disabled
                default: break
                }
                childrens.append(action)
            }
            return UIMenu(title: "", children: childrens)
        })
    }
}
