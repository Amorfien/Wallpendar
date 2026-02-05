//
//  MonthCalendarView.swift
//  WallpaperCalendar
//
//  Created by Pavel Grigorev on 05.02.2026.
//


import UIKit
import SnapKit

struct CalendarConfiguration {
    let month: Int
    let year: Int
    let backgroundColor: UIColor
    let backgroundAlpha: CGFloat
    let dayTextColor: UIColor
    let weekendTextColor: UIColor
    let weekdayHeaderColor: UIColor
    let monthHeaderColor: UIColor
    let dayFontSize: CGFloat

    static let initial = Self.init(
        month: 2,//Calendar.current.component(.month, from: .now).advanced(by: 1),
        year: 2027,//Calendar.current.component(.year, from: .now),
        backgroundColor: .black,
        backgroundAlpha: 0.5,
        dayTextColor: .white,
        weekendTextColor: .systemRed,
        weekdayHeaderColor: .lightGray,
        monthHeaderColor: .white,
        dayFontSize: 16
    )
}

class MonthCalendarView: UIView {
    
    // MARK: - Приватные свойства

    private var configuration: CalendarConfiguration

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let monthHeaderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    private var dayLabels: [UILabel] = []
    private let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    
    // MARK: - Инициализация

    init(with configuration: CalendarConfiguration = .initial) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = .initial
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Настройка
    
    private func setupView() {
        self.backgroundColor = configuration.backgroundColor
            .withAlphaComponent(configuration.backgroundAlpha)
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.clipsToBounds = true

        addSubview(mainStackView)
            mainStackView.layer.borderWidth = 1
            mainStackView.layer.borderColor = UIColor.yellow.cgColor
        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        // Добавляем заголовок месяца
        let headerContainer = UIView()
        headerContainer.addSubview(monthHeaderLabel)
        monthHeaderLabel.textColor = configuration.monthHeaderColor
        monthHeaderLabel.font = .systemFont(ofSize: round(configuration.dayFontSize * 1.25), weight: .medium)

        monthHeaderLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        mainStackView.addArrangedSubview(headerContainer)
        
        // Добавляем строку с днями недели
        let weekdaysStack = createWeekdaysRow()
        mainStackView.addArrangedSubview(weekdaysStack)
        
        // Добавляем 6 строк для чисел (6 недель максимум)
        for _ in 0..<6 {
            let weekStack = createWeekRow()
            mainStackView.addArrangedSubview(weekStack)
        }
        
        updateCalendar()
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
            label.font = .systemFont(ofSize: 14, weight: .medium)
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
        
        var dateComponents = DateComponents()
        dateComponents.year = configuration.year
        dateComponents.month = configuration.month
        dateComponents.day = 1
        
        if let date = Calendar.current.date(from: dateComponents) {
            monthHeaderLabel.text = dateFormatter.string(from: date).capitalized
        }
        
        // Очищаем все labels
        dayLabels.forEach { $0.text = "" }
        
        // Получаем информацию о месяце
        guard let firstDayOfMonth = getFirstDayOfMonth(),
              let numberOfDays = getNumberOfDaysInMonth() else {
            return
        }
        
        // Определяем день недели для 1-го числа месяца (1 = понедельник, 7 = воскресенье)
        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        // Конвертируем: 1=воскр -> 7, 2=пн -> 1, 3=вт -> 2, ... 7=суб -> 6
        let startOffset: Int
        if firstWeekday == 1 { // воскресенье
            startOffset = 6
        } else {
            startOffset = firstWeekday - 2
        }
        
        // Заполняем числами
        for day in 1...numberOfDays {
            let position = startOffset + (day - 1)
            if position < dayLabels.count {
                dayLabels[position].text = "\(day)"
            }
        }
        
        // Обновляем цвета для выходных
        updateDayColors()
    }
    
    private func getFirstDayOfMonth() -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = configuration.year
        dateComponents.month = configuration.month
        dateComponents.day = 1
        return Calendar.current.date(from: dateComponents)
    }
    
    private func getNumberOfDaysInMonth() -> Int? {
        guard let date = getFirstDayOfMonth() else { return nil }
        return Calendar.current.range(of: .day, in: .month, for: date)?.count
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
}
