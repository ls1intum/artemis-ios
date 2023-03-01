//
//  File.swift
//
//
//  Created by Sven Andabaka on 12.01.23.
//

import Foundation

public extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}

public extension Formatter {
    static let iso8601 = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

public extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }

    var mediumDateShortTime: String {
        return DateFormatter.dateAndTime.string(from: self)
    }

    var shortDateAndTime: String {
        return DateFormatter.shortDateAndTime.string(from: self)
    }

    var superShortDateAndTime: String {
        return DateFormatter.superShortDateAndTime.string(from: self)
    }

    var dayAndDate: String {
        return DateFormatter.dayAndDate.string(from: self)
    }

    var timeOnly: String {
        return DateFormatter.timeOnly.string(from: self)
    }
}

public extension DateFormatter {
    fileprivate convenience init(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) {
        self.init()
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
        locale = .current
    }
    fileprivate convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
        locale = .current
    }

    // DE: "DD/MM/YYYY, HH:MM"
    // US: "Mon DD, YYYY at HH:MM AM"

    static var dateAndTime: DateFormatter {
        let dateFormatter = DateFormatter(dateStyle: .medium, timeStyle: .short)
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }

    static var shortDateAndTime: DateFormatter {
        let dateFormatter = DateFormatter(dateFormat: "d MMM, HH:mm")
        return dateFormatter
    }

    static var superShortDateAndTime: DateFormatter {
        let dateFormatter = DateFormatter(dateStyle: .short, timeStyle: .short)
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }

    static let dayAndDate = DateFormatter(dateFormat: "EEEE, dd.MM")

    static let timeOnly = DateFormatter(dateStyle: .none, timeStyle: .short)
}

public extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
