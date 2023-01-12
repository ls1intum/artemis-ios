//
//  File.swift
//  
//
//  Created by Sven Andabaka on 12.01.23.
//

import Foundation

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}

extension Formatter {
    static let iso8601 = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
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
