//
//  MonthCalendarView.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 05.02.2026.
//


import UIKit
import SnapKit

struct CalendarConfiguration {
    let backgroundColor: UIColor
    let backgroundAlpha: CGFloat
    let dayTextColor: UIColor
    let weekendTextColor: UIColor
    let weekdayHeaderColor: UIColor
    let monthHeaderColor: UIColor
    let dayFontSize: CGFloat

    init(backgroundColor: UIColor = .darkCalendar,
         backgroundAlpha: CGFloat = 0.5,
         dayTextColor: UIColor = .white,
         weekendTextColor: UIColor = .systemRed,
         weekdayHeaderColor: UIColor = .lightGray,
         monthHeaderColor: UIColor = .white,
         dayFontSize: CGFloat = 16) {
        self.backgroundColor = backgroundColor
        self.backgroundAlpha = backgroundAlpha
        self.dayTextColor = dayTextColor
        self.weekendTextColor = weekendTextColor
        self.weekdayHeaderColor = weekdayHeaderColor
        self.monthHeaderColor = monthHeaderColor
        self.dayFontSize = dayFontSize
    }
}

final class MonthCalendarView: UIView {
    
    // MARK: - Приватные свойства

    private var configuration: CalendarConfiguration

    private var currentMonthOffset = 0

    private lazy var dateComponents: DateComponents = {
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: .now)
        dateComponents.month = Calendar.current.component(.month, from: .now)
        dateComponents.day = 1
        return dateComponents
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
        return label
    }()

    lazy var leftButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.arrowshapeLeft.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal), for: .normal)
        button.tag = -1
        button.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .touchUpInside)
        return button
    }()
    lazy var rightButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.arrowshapeRight.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal), for: .normal)
        button.tag = 1
        button.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .touchUpInside)
        return button
    }()

    private var dayLabels: [UILabel] = []
    private let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    
    // MARK: - Инициализация

    init(with configuration: CalendarConfiguration = .init()) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = CalendarConfiguration()
        super.init(coder: coder)
        setupView()
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

    // MARK: - Настройка
    private func setupView() {
        self.backgroundColor = configuration.backgroundColor
            .withAlphaComponent(configuration.backgroundAlpha)
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        self.clipsToBounds = true

        addSubviews(mainStackView)
        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
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
        let headerContainer = UIStackView(arrangedSubviews: [leftButton, monthHeaderLabel, rightButton])
        headerContainer.distribution = .fill
        headerContainer.alignment = .top

        monthHeaderLabel.textColor = configuration.monthHeaderColor
        monthHeaderLabel.font = .systemFont(ofSize: round(configuration.dayFontSize * 1.25), weight: .medium)
        headerContainer.snp.makeConstraints {
            $0.height.equalTo(32)
        }
        leftButton.snp.makeConstraints {
            $0.width.equalTo(44)
        }
        rightButton.snp.makeConstraints {
            $0.width.equalTo(44)
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
        
        for weekday in weekdays {
            let label = UILabel()
            label.text = weekday
            label.textAlignment = .center
            label.font = .systemFont(ofSize: configuration.dayFontSize - 1, weight: .semibold)
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
            label.font = .systemFont(ofSize: configuration.dayFontSize)
            label.textColor = configuration.dayTextColor
            stack.addArrangedSubview(label)
            dayLabels.append(label)
        }
        
        return stack
    }
    
    // MARK: - Обновление календаря
    
    private func updateCalendar() {
        // Обновляем заголовок
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
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

    @objc
    private func stepperValueChanged(_ sender: UIButton) {
        let newValue = currentMonthOffset + sender.tag
        if newValue > -3 && newValue < 13 {
            changeMonth(increase: sender.tag > 0)
            currentMonthOffset += sender.tag
        }
    }
}
