//
//  TimestampConvertable.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Foundation

struct TimestampConvertable {
    static func toTimestamp(_ date: Date) -> Int {
        Int(date.timeIntervalSince1970)
    }
    static func toDate(_ timestamp: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
