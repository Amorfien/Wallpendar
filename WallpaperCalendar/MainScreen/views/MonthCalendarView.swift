//
//  MonthCalendarView.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 05.02.2026.
//


import UIKit
import SnapKit

final class MonthCalendarView: UIView {

    // MARK: - Nested Properties
    enum Appearance {
        case light
        case dark
    }

    enum Material {
        case shade
        case blur
        case glass
    }

    private(set) var appearance: Appearance = .dark {
        didSet {
            switch material {
            case .shade:
                alphaView.backgroundColor = configuration.backgroundColor
                    .withAlphaComponent(configuration.backgroundAlpha)
                alphaView.layer.borderColor = appearance == .light
                ? UIColor.black.withAlphaComponent(0.5).cgColor
                : UIColor.white.withAlphaComponent(0.7).cgColor
            case .blur: visualEffectView.effect = appearance == .light ? lightBlur : darkBlur
            case .glass: visualEffectView.effect = clearGlass
            }

            guard appearance != oldValue else { return }
            self.configuration.dayTextColor = appearance == .light ? .black : .white
            self.configuration.monthHeaderColor = appearance == .light ? .black : .white
            self.configuration.weekdayHeaderColor = appearance == .light ? .darkText : .lightGray
            updateDayColors()
            updateHeaderColors()
            monthHeaderLabel.textColor = configuration.monthHeaderColor
        }
    }

    private(set) var material: Material = .blur {
        didSet {
            guard material != oldValue else { return }
            visualEffectView.isHidden = material == .shade
            alphaView.isHidden = material != .shade
            transparencySlider.isHidden = material != .shade
            colorStackView.isHidden = material != .shade
            pickerButton.isHidden = material != .shade

            let oldAppearance = appearance
            appearance = oldAppearance
        }
    }

    var isChangeXPosition: ((CGFloat) -> Void)?
    var isChangeYPosition: ((CGFloat) -> Void)?
    var isStartDragging: (() -> Void)?
    var isEndDragging: (() -> Void)?
    var isNeedToPresentColorPicker: ((UIColorPickerViewController) -> Void)?
    var isNeedToShowVertical: ((Bool) -> Void)?
    var isNeedToShowHorizontal: ((Bool) -> Void)?

    lazy var viewsToHide: [UIView] = [
        leftButton,
        rightButton,
        transparencySlider,
        sizeView,
        colorStackView,
        pickerButton
    ]

    private var configuration: CalendarConfiguration

    private var currentMonthOffset = 0

    private lazy var dateComponents: DateComponents = {
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: .now)
        dateComponents.month = Calendar.current.component(.month, from: .now)
        dateComponents.day = 1
        return dateComponents
    }()

    let contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()

    private let darkBlur = UIBlurEffect(style: .systemThinMaterialDark)
    private let lightBlur = UIBlurEffect(style: .systemThinMaterialLight)
    private let clearGlass = UIGlassEffect(style: .clear)

    private lazy var visualEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: darkBlur)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    private var alphaView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        return stack
    }()

    private let monthHeaderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()

    private lazy var leftButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.arrowshapeLeft.withTintColor(.tintColor.withAlphaComponent(0.8), renderingMode: .alwaysOriginal), for: .normal)
        button.tag = -1
        button.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var rightButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.arrowshapeRight.withTintColor(.tintColor.withAlphaComponent(0.8), renderingMode: .alwaysOriginal), for: .normal)
        button.tag = 1
        button.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var transparencySlider: UISlider = {
        let slider = UISlider()
        slider.value = Float(configuration.backgroundAlpha)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.addTarget(self, action: #selector(transparencyChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(transparencyStart), for: .touchDown)
        slider.addTarget(self, action: #selector(transparencyEnd), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        slider.setThumbImage(UIImage.transparency.withTintColor(.tintColor.withAlphaComponent(0.8), renderingMode: .alwaysOriginal), for: .normal)
        slider.tintColor = .tintColor.withAlphaComponent(0.8)
        slider.isHidden = true
        return slider
    }()
    private lazy var sizeView: UIButton = {
        let view = UIButton()
        view.setBackgroundImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right")?
            .withTintColor(.tintColor.withAlphaComponent(0.8),
                           renderingMode: .alwaysOriginal), for: .normal)
        view.addGestureRecognizer(
            UIPanGestureRecognizer(
                target: self,
                action: #selector(sizePan(_:))
            )
        )
        return view
    }()

    private lazy var colorStackView: UIStackView = {
        let stack = UIStackView()
        for (index, color) in colors.enumerated() {
            let button = UIButton()
            button.backgroundColor = color
            button.tag = index
            button.layer.cornerRadius = 3
            button.layer.borderWidth = 0.33
            button.layer.borderColor = UIColor.black.cgColor
            button.addTarget(self, action: #selector(colorButtonTap(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        stack.spacing = 4
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.isHidden = true
        return stack
    }()

    private lazy var pickerButton: UIButton = {
        let button = UIButton()
        button.setImage(.rgb, for: .normal)
        button.addTarget(self, action: #selector(pickerButtonTap), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var colorPicker: UIColorPickerViewController = {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.supportsAlpha = false
        return picker
    }()

    private var dayLabels: [UILabel] = []
    private let weekdays = [
        String(localized: "weekday.mo"),
        String(localized: "weekday.tu"),
        String(localized: "weekday.we"),
        String(localized: "weekday.th"),
        String(localized: "weekday.fr"),
        String(localized: "weekday.sa"),
        String(localized: "weekday.su"),
    ]
    private let colors: [UIColor] = [.lightCalendar, .darkCalendar, .grayCalendar, .greenCalendar, .blueCalendar, .pinkCalendar, .yellowCalendar]

    // MARK: - Initialization
    init(with configuration: CalendarConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()

        addGestureRecognizer(
            UIPanGestureRecognizer(
                target: self,
                action: #selector(positionPan(_:))
            )
        )
    }
    
    required init?(coder: NSCoder) {
        self.configuration = CalendarConfiguration(size: .zero, positionOffset: .zero)
        super.init(coder: coder)
        setupView()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerBounds = CGRect(x: 0, y: -36, width: bounds.width + 16, height: bounds.height + 16 + 36)
        return largerBounds.contains(point)
    }

    // MARK: - Public Methods
    func changeMonth(increase: Bool) {
        // Обновляем месяц в dateComponents
        let calendar = Calendar.current
        guard let currentDate = calendar.date(from: dateComponents) else { return }

        // Вычисляем новую дату
        var newDateComponents = DateComponents()
        newDateComponents.month = increase ? 1 : -1

        guard let newDate = calendar.date(byAdding: newDateComponents, to: currentDate) else { return }

        // Обновляем dateComponents
        dateComponents.year = calendar.component(.year, from: newDate)
        dateComponents.month = calendar.component(.month, from: newDate)
        dateComponents.day = 1

        // Перерисовываем календарь
        reloadCalendar()
    }

    func changeAppearance(to appearance: Appearance) {
        self.appearance = appearance
    }

    func changeMaterial(to material: Material) {
        self.material = material
    }

    // MARK: - SetupUI
    private func setupView() {
        self.snp.makeConstraints {
            $0.size.equalTo(configuration.size)
        }

        self.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.addSubviews(alphaView, visualEffectView)
        alphaView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        visualEffectView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        alphaView.backgroundColor = configuration.backgroundColor
            .withAlphaComponent(configuration.backgroundAlpha)

        contentView.addSubview(mainStackView)
        addSubviews(leftButton, rightButton, transparencySlider, sizeView, colorStackView, pickerButton)
        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
        transparencySlider.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(self.snp.bottom).inset((transparencySlider.thumbImage(for: .normal)?.size.height ?? 0) / 2 + 4)
            $0.width.equalToSuperview().inset(28)
        }
        sizeView.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().offset(15)
            $0.size.equalTo(40)
        }
        leftButton.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(4)
            $0.size.equalTo(44)
        }
        rightButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(4)
            $0.size.equalTo(44)
        }
        colorStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().inset(40)
            $0.bottom.equalTo(self.snp.top).offset(-4)
            $0.height.equalTo(32)
        }
        pickerButton.snp.makeConstraints {
            $0.verticalEdges.equalTo(colorStackView)
            $0.leading.equalTo(colorStackView.snp.trailing).offset(4)
            $0.size.equalTo(32)
        }

        setupCalendarStructure()
        updateCalendar()
    }

    private func reloadCalendar() {
        // Удаляем все вложенные вьюхи из mainStackView
        mainStackView.arrangedSubviews.forEach {
            mainStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Очищаем массив лейблов
        dayLabels.removeAll()

        // Создаем заново структуру
        setupCalendarStructure()
        updateCalendar()
    }

    private func setupCalendarStructure() {
        // Добавляем заголовок месяца
        let headerContainer = UIStackView(arrangedSubviews: [monthHeaderLabel])
        headerContainer.distribution = .fill
        headerContainer.alignment = .top

        monthHeaderLabel.textColor = configuration.monthHeaderColor
        monthHeaderLabel.font = .systemFont(ofSize: round(configuration.dayFontSize * 1.25), weight: .semibold)
        headerContainer.snp.makeConstraints {
            $0.height.equalTo(32)
        }

        mainStackView.addArrangedSubview(headerContainer)

        // Добавляем строку с днями недели
        let weekdaysStack = createWeekdaysRow()
        mainStackView.addArrangedSubview(weekdaysStack)
    }

    private func createWeekdaysRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.alignment = .bottom

        for weekday in weekdays {
            let label = UILabel()
            label.text = weekday
            label.textAlignment = .center
            label.font = .systemFont(ofSize: configuration.dayFontSize - 1, weight: .semibold)
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.textColor = configuration.weekdayHeaderColor
            stack.addArrangedSubview(label)
        }
        
        return stack
    }
    
    private func createWeekRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        for _ in 0..<7 {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: configuration.dayFontSize, weight: .medium)
            label.textColor = configuration.dayTextColor
            stack.addArrangedSubview(label)
            dayLabels.append(label)
        }
        
        return stack
    }
    
    // MARK: - Update Calendar
    private func updateCalendar() {
        // Обновляем заголовок
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "LLLL yyyy"
        
        if let date = Calendar.current.date(from: dateComponents) {
            monthHeaderLabel.text = dateFormatter.string(from: date).capitalized
        }

        // Получаем информацию о месяце
        guard let firstDayOfMonth = getFirstDayOfMonth(),
              let numberOfDays = getNumberOfDaysInMonth() else {
            return
        }

        // Создаем недели с числами
        createWeekRows(for: firstDayOfMonth, numberOfDays: numberOfDays)
        
        // Обновляем цвета для выходных
        updateDayColors()
    }
    
    private func getFirstDayOfMonth() -> Date? {
        return Calendar.current.date(from: dateComponents)
    }
    
    private func getNumberOfDaysInMonth() -> Int? {
        guard let date = getFirstDayOfMonth() else { return nil }
        return Calendar.current.range(of: .day, in: .month, for: date)?.count
    }

    private func createWeekRows(for firstDayOfMonth: Date, numberOfDays: Int) {
        // Определяем день недели для 1-го числа месяца
        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        let startOffset = firstWeekday == 1 ? 6 : firstWeekday - 2

        // Рассчитываем необходимое количество недель
        let totalCellsNeeded = startOffset + numberOfDays
        let weeksNeeded = Int(ceil(Double(totalCellsNeeded) / 7.0))

        // Заполняем недели
        for weekIndex in 0..<weeksNeeded {
            let weekStack = createWeekRow()
            mainStackView.addArrangedSubview(weekStack)

            // Заполняем неделю числами
            for dayIndex in 0..<7 {
                let globalPosition = weekIndex * 7 + dayIndex
                if let label = weekStack.arrangedSubviews[dayIndex] as? UILabel {
                    if globalPosition >= startOffset && globalPosition < startOffset + numberOfDays {
                        let dayNumber = globalPosition - startOffset + 1
                        label.text = "\(dayNumber)"
                    } else {
                        label.text = ""
                    }
                }
            }
        }
    }

    private func updateDayColors() {
        // Определяем первый день месяца для расчета позиций
        guard let firstDayOfMonth = getFirstDayOfMonth() else { return }
        
        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        let startOffset = firstWeekday == 1 ? 6 : firstWeekday - 2
        
        for (_, label) in dayLabels.enumerated() {
            guard let dayNumber = Int(label.text ?? "") else { continue }
            
            // Позиция этого дня в сетке (0-41)
            let position = startOffset + (dayNumber - 1)
            
            // Определяем день недели для этого числа
            let weekdayPosition = position % 7 // 0=пн, 1=вт, ... 5=сб, 6=вс
            
            // Суббота (5) и воскресенье (6) - выходные
            if weekdayPosition == 5 || weekdayPosition == 6 {
                label.textColor = configuration.weekendTextColor
            } else {
                label.textColor = configuration.dayTextColor
            }
        }
    }
    
    private func updateHeaderColors() {
        // Обновляем цвета заголовков дней недели
        if let weekdaysStack = mainStackView.arrangedSubviews[1] as? UIStackView {
            for (_, view) in weekdaysStack.arrangedSubviews.enumerated() {
                if let label = view as? UILabel {
                    label.textColor = configuration.weekdayHeaderColor
                }
            }
        }
    }
    
    private func updateDayFonts() {
        dayLabels.forEach { $0.font = .systemFont(ofSize: configuration.dayFontSize) }
    }

    // MARK: - Actions

    @objc
    private func colorButtonTap(_ sender: UIButton) {
        let newColor = colors[sender.tag]
        configuration.backgroundColor = newColor
        alphaView.backgroundColor = newColor.withAlphaComponent(configuration.backgroundAlpha)
    }

    @objc
    private func pickerButtonTap() {
        isNeedToPresentColorPicker?(colorPicker)
    }

    @objc
    private func stepperValueChanged(_ sender: UIButton) {
        let newValue = currentMonthOffset + sender.tag
        if newValue > -3 && newValue < 13 {
            changeMonth(increase: sender.tag > 0)
            currentMonthOffset += sender.tag
        }
    }

    @objc
    private func transparencyChanged(_ sender: UISlider) {
        alphaView.backgroundColor = configuration.backgroundColor
            .withAlphaComponent(CGFloat(sender.value))
        configuration.backgroundAlpha = CGFloat(sender.value)
        sender.minimumTrackTintColor = .tintColor.withAlphaComponent(CGFloat(min(sender.value, 0.7) + 0.3))
    }
    @objc
    private func transparencyStart() {
        viewsToHide
            .filter { !($0 is UISlider) }
            .forEach { $0.isHidden = true }
    }
    @objc
    private func transparencyEnd() {
        viewsToHide.forEach { $0.isHidden = false }
    }

    // MARK: Position Constraints
    @objc
    private func positionPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        let dumpRate = 7.0
        let centerX = (R.Device.screenWidth / 2) - (configuration.size.width / 2)
        let centerY = (R.Device.screenHeight / 2) - (configuration.size.height / 2)
        let centerThreshold = 6.0
        let maxX = R.Device.screenWidth - configuration.size.width
        let maxY = R.Device.screenHeight - configuration.size.height
        var newX = configuration.positionOffset.x + translation.x
        var newY = configuration.positionOffset.y + translation.y

        if newX < 0 {
            newX = newX / dumpRate
        } else if newX > maxX {
            newX = maxX + (newX - maxX) / dumpRate
        } else if abs(newX - centerX) < centerThreshold {
            newX = centerX
        }
        if newY < 0 {
            newY = newY / dumpRate
        } else if newY > maxY {
            newY = maxY + (newY - maxY) / dumpRate
        } else if abs(newY - centerY) < centerThreshold {
            newY = centerY
        }

        switch gesture.state {
        case .began:
            isStartDragging?()
        case .changed:
            isChangeXPosition?(newX)
            isChangeYPosition?(newY)
            isNeedToShowVertical?(newX == centerX)
            isNeedToShowHorizontal?(newY == centerY)
        case .ended:
            var finalX = min(max(configuration.positionOffset.x + translation.x, 0), maxX)
            var finalY = min(max(configuration.positionOffset.y + translation.y, 0), maxY)
            if abs(finalX - centerX) < centerThreshold {
                finalX = centerX
            }
            if abs(finalY - centerY) < centerThreshold {
                finalY = centerY
            }
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7) {
                self.isChangeXPosition?(finalX)
                self.isChangeYPosition?(finalY)
            }
            configuration.positionOffset.x = finalX
            configuration.positionOffset.y = finalY
            gesture.setTranslation(.zero, in: superview)
            isEndDragging?()
        default: break
        }
    }

    // MARK: Size Constraints
    @objc
    private func sizePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        let newSize = CGSize(width: configuration.size.width + translation.x, height: configuration.size.height + translation.y)
        let minWidth = configuration.minSize.width
        let minHeight = configuration.minSize.height

        switch gesture.state {
        case .began:
            isStartDragging?()
        case .changed:
            if newSize.width > minWidth && newSize.width < R.Device.screenWidth - 20 {
                self.snp.updateConstraints { $0.width.equalTo(newSize.width) }
            }
            if newSize.height > minHeight && newSize.height < R.Device.screenHeight / 3 {
                self.snp.updateConstraints { $0.height.equalTo(newSize.height) }
            }
        case .ended:
            if newSize.width > minWidth && newSize.width < R.Device.screenWidth - 20 {
                configuration.size.width += translation.x
            } else {
                configuration.size.width = newSize.width < minWidth ? minWidth : R.Device.screenWidth - 20
            }
            if newSize.height > minHeight && newSize.height < R.Device.screenHeight / 3 {
                configuration.size.height += translation.y
            } else {
                configuration.size.height = newSize.height < minHeight ? minHeight : R.Device.screenHeight / 3
            }
            isEndDragging?()
        default: break
        }
    }
}

// MARK: - Color Picker
extension MonthCalendarView: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                   didSelect color: UIColor,
                                   continuously: Bool) {
        configuration.backgroundColor = color
        alphaView.backgroundColor = color.withAlphaComponent(configuration.backgroundAlpha)
    }
}
