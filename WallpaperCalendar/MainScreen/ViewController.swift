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
            viewsToHide.forEach { $0.alpha = isPreview ? 0 : 1 }
            previewButton.setImage(.init(systemName: isPreview ? "eye" : "eye.slash"), for: .normal)
            previewButton.alpha = isPreview ? 0.25 : 1
        }
    }

    private var isDoublePreview: Bool = false

    private lazy var viewsToHide: [UIView] = [
        reloadButton,
        galleryButton,
        saveButton
    ] + calendarView.viewsToHide

    private let apiManager = APIManager()
    private var imageMode: ImageMode = .standart

    private let startCalendarSize = CGSize(width: R.Device.screenWidth - 96, height: 250)
    private lazy var startCalendarPositionOffset = CGPoint(
        x: (R.Device.screenWidth - startCalendarSize.width) / 2,
        y: R.Device.screenHeight / 2)

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: R.Img.initialImages.randomElement())
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let reloadButton = SquareButton(with: .init(systemName: "arrow.trianglehead.2.clockwise"))
    private let previewButton = SquareButton(with: .init(systemName: "eye.slash"))
    private let galleryButton = SquareButton(with: .init(systemName: "photo.on.rectangle.angled"))
    private let saveButton = SquareButton(with: .init(systemName: "tray.and.arrow.down"))

    private lazy var calendarView = MonthCalendarView(
        with: CalendarConfiguration.init(size: startCalendarSize,
                                         positionOffset: startCalendarPositionOffset))

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var reloadContextMenu = UIContextMenuInteraction(delegate: self)
    private lazy var calendarContextMenu = UIContextMenuInteraction(delegate: self)

    private lazy var photoPicker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        return picker
    }()

    private let verticalCenterView: UIView = {
        let view = UIView()
        view.backgroundColor = .yellow.withAlphaComponent(0.7)
        view.isHidden = true
        return view
    }()

    private let horizontalCenterView: UIView = {
        let view = UIView()
        view.backgroundColor = .yellow.withAlphaComponent(0.7)
        view.isHidden = true
        return view
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

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .darkGray
        activityIndicator.color = .white
        view.addSubviews(backgroundImageView,
                         verticalCenterView,
                         horizontalCenterView,
                         calendarView,
                         reloadButton,
                         galleryButton,
                         saveButton,
                         previewButton,
                         activityIndicator)

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        calendarView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(startCalendarPositionOffset.x)
            $0.top.equalToSuperview().offset(startCalendarPositionOffset.y)
        }
        reloadButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(8)
        }
        previewButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(8)
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
        verticalCenterView.snp.makeConstraints {
            $0.centerX.verticalEdges.equalToSuperview()
            $0.width.equalTo(2)
        }
        horizontalCenterView.snp.makeConstraints {
            $0.centerY.horizontalEdges.equalToSuperview()
            $0.height.equalTo(2)
        }

        reloadButton.addInteraction(reloadContextMenu)
        calendarView.contentView.addInteraction(calendarContextMenu)
    }

    // MARK: - Binding
    private func buttonsBinding() {

        reloadButton.isButtonTapped = { [weak self] in
            guard let self else { return }
            activityIndicator.startAnimating()
            viewsToHide.compactMap { $0 as? UIControl }.forEach { $0.isEnabled = false }
            apiManager.getImage(
                width: R.Device.screenScale * R.Device.screenWidth,
                height: R.Device.screenScale * R.Device.screenHeight,
                mode: imageMode) { [weak self] result in
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        activityIndicator.stopAnimating()
                        viewsToHide.compactMap { $0 as? UIControl }.forEach { $0.isEnabled = true }
                        switch result {
                        case .success(let data):
                            backgroundImageView.image = UIImage(data: data)
                        case .failure(let error):
                            print(error.localizedDescription)
                            var newImage: UIImage
                            repeat {
                                if imageMode == .standart {
                                    newImage = R.Img.initialImages.randomElement() ?? UIImage()
                                } else {
                                    newImage = R.Img.grayScaleImages.randomElement() ?? UIImage()
                                }
                            } while newImage.hash == backgroundImageView.image?.hash
                            backgroundImageView.image = newImage
                        }
                    }
                }

        }

        previewButton.isButtonTapped = { [weak self] in
            self?.isDoublePreview = false
            self?.isPreview.toggle()
        }

        galleryButton.isButtonTapped = { [weak self] in
            guard let self else { return }
            activityIndicator.startAnimating()
            viewsToHide.compactMap { $0 as? UIControl }.forEach { $0.isEnabled = false }
            present(photoPicker, animated: true) { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.viewsToHide.compactMap { $0 as? UIControl }.forEach { $0.isEnabled = true }
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
                        viewsToHide.compactMap { $0 as? UIControl }.forEach { $0.isEnabled = false }
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    } else {
                        showAlert(
                            title: String(localized: "permission.noAccess.title"),
                            message: String(localized: "permission.noAccess.message"),
                            primaryAction: UIAlertAction(title: String(localized: "main.settings"), style: .default) { _ in
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                                UIApplication.shared.open(settingsUrl)
                            },
                            secondaryAction: UIAlertAction(title: String(localized: "main.cancel"), style: .cancel)
                        )
                    }
                }
            }
        }

        calendarView.isChangeXPosition = { [weak self] offsetX in
            guard let self else { return }
            calendarView.snp.updateConstraints {
                $0.leading.equalToSuperview().offset(offsetX)
            }
        }
        calendarView.isChangeYPosition = { [weak self] offsetY in
            guard let self else { return }
            calendarView.snp.updateConstraints {
                $0.top.equalToSuperview().offset(offsetY)
            }
        }
        calendarView.isStartDragging = { [weak self] in
            guard let self else { return }
            if isPreview { isDoublePreview = true }
            isPreview = true
        }
        calendarView.isEndDragging = { [weak self] in
            guard let self else { return }
            verticalCenterView.isHidden = true
            horizontalCenterView.isHidden = true
            if !isDoublePreview {
                isPreview = false
            }
        }
        calendarView.isNeedToPresentColorPicker = { [weak self] picker in
            self?.present(picker, animated: true)
        }
        calendarView.isNeedToShowVertical = { [weak self] show in
            self?.verticalCenterView.isHidden = !show
        }
    }

    // MARK: - Private Methods
    private func buildWallpaper() -> UIImage {
        var views = viewsToHide
        views.append(previewButton)
        views.forEach { $0.alpha = 0 }
        view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        UIView.animate(withDuration: 1.2, delay: 2) {
            views.forEach { $0.alpha = 1 }
        }
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
            self?.viewsToHide.compactMap { $0 as? UIControl }.forEach { $0.isEnabled = true }
            if let error = error {
                self?.showAlert(title: String(localized: "main.error"), message: String(format: String(localized: "save.error.message"), error.localizedDescription))
            } else {
                self?.showAlert(title: String(localized: "main.success"), message: String(localized: "save.success.message"))
            }
        }
    }
}

// MARK: - Photo Picker Delegate
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

// MARK: - Context Menu Delegate
extension ViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            guard let self else { return nil }
            var childrens: [UIMenuElement] = []

            if interaction.view is SquareButton {
                ImageMode.allCases.forEach { mode in
                    let action = UIAction(title: mode.title, state: self.imageMode == mode ? .on : .off) { _ in
                        self.imageMode = mode
                        self.reloadButton.isButtonTapped?()
                    }
                    childrens.append(action)
                }
            } else {
                let light = UIAction(title: String(localized: "calendar.appearance.dark"),
                                     image: UIImage(systemName: "character.square"),
                                     state: calendarView.appearance == .light ? .on : .off) { _ in
                    self.calendarView.changeAppearance(to: .light)
                }
                let dark = UIAction(title: String(localized: "calendar.appearance.light"),
                                    image: UIImage(systemName: "character.square.fill"),
                                    state: calendarView.appearance == .dark ? .on : .off) { _ in
                    self.calendarView.changeAppearance(to: .dark)
                }
                let alpha = UIAction(title: String(localized: "calendar.mode.shading"),
                                     image: UIImage(systemName: "aqi.medium"),
                                     state: calendarView.material == .shade ? .on : .off) { _ in
                    self.calendarView.changeMaterial(to: .shade)
                }
                let blur = UIAction(title: String(localized: "calendar.mode.blur"),
                                    image: UIImage(systemName: "app.background.dotted"),
                                    state: calendarView.material == .blur ? .on : .off) { _ in
                    self.calendarView.changeMaterial(to: .blur)
                }
                let glass = UIAction(title: String(localized: "calendar.mode.glass"),
                                     image: UIImage(systemName: "sparkles.2"),
                                     state: calendarView.material == .glass ? .on : .off) { _ in
                    self.calendarView.changeMaterial(to: .glass)
                }

                let primaryActions = UIMenu(title: String(localized: "calendar.appearance.title"), options: .displayInline, children: [
                    light, dark
                ])
                let secondaryActions = UIMenu(title: String(localized: "calendar.mode.title"), options: .displayInline, children: [
                    alpha, blur, glass
                ])
                childrens = [primaryActions, secondaryActions]
            }
            return UIMenu(title: "", children: childrens)
        })
    }
}
