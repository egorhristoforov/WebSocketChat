//
//  DateFormatter+Server.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import Foundation

extension DateFormatter {
    static var serverFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
}
