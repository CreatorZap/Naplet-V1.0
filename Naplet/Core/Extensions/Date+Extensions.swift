import Foundation

// MARK: - Date Extensions
extension Date {

    // MARK: - Formatting

    /// Formata a data como "8:30 AM"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    /// Formata a data como "08:30"
    var time24String: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// Formata a data como "Jan 15"
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Formata a data como "January 15, 2024"
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    /// Formata como "Today", "Yesterday" ou data
    var relativeString: String {
        if Calendar.current.isDateInToday(self) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return shortDateString
        }
    }

    /// Formata a data como "Mon, Jan 15"
    var dayAndDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: self)
    }

    // MARK: - Date Components

    /// Retorna o início do dia
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Retorna o fim do dia
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Retorna o início da semana
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Retorna o início do mês
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    // MARK: - Time Calculations

    /// Calcula a duração entre duas datas formatada como "2h 30m"
    func duration(to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(self)
        return interval.formattedDuration
    }

    /// Calcula a duração em minutos
    func durationInMinutes(to endDate: Date) -> Int {
        let interval = endDate.timeIntervalSince(self)
        return Int(interval / 60)
    }

    /// Calcula a duração em horas
    func durationInHours(to endDate: Date) -> Double {
        let interval = endDate.timeIntervalSince(self)
        return interval / 3600
    }

    // MARK: - Date Manipulation

    /// Adiciona dias à data
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Adiciona horas à data
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Adiciona minutos à data
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    // MARK: - Comparisons

    /// Verifica se a data é hoje
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Verifica se a data é ontem
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Verifica se a data é nesta semana
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Verifica se a data é neste mês
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Age Calculations (útil para bebês)

    /// Calcula a idade em meses
    func ageInMonths(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: self)
        return components.month ?? 0
    }

    /// Calcula a idade formatada como "3 months" ou "1 year 2 months"
    func ageString(from birthDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: birthDate, to: self)

        let years = components.year ?? 0
        let months = components.month ?? 0

        if years == 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if months == 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else {
            let yearStr = years == 1 ? "1 year" : "\(years) years"
            let monthStr = months == 1 ? "1 month" : "\(months) months"
            return "\(yearStr) \(monthStr)"
        }
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {

    /// Formata o intervalo como "2h 30min"
    var formatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    /// Formata o intervalo como "2:30" ou "30m"
    var shortFormatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes)m"
        }
    }

    /// Formata o intervalo como "2h 30m" (alias para formatted)
    var formattedDuration: String {
        formatted
    }

    /// Formata o intervalo como "02:30:00" (para timer)
    var timerFormat: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
