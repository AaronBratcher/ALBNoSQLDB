//
//  NSDateExtensions.swift
//  Money Trak
//
//  Created by Aaron Bratcher on 3/26/16.
//  Copyright © 2016 Aaron L. Bratcher. All rights reserved.
//

import Foundation

var dateFormatter: DateFormatter = {
	let format = DateFormatter.dateFormat(fromTemplate: "MMM d yyyy", options: 0, locale: NSLocale.current)
	let formatter = DateFormatter()
	formatter.dateFormat = format

	return formatter
}()

let dayFormatter: DateFormatter = {
	let format = DateFormatter.dateFormat(fromTemplate: "MMM d", options: 0, locale: NSLocale.current)
	let formatter = DateFormatter()
	formatter.dateFormat = format

	return formatter
}()

let monthFormatter: DateFormatter = {
	let format = DateFormatter.dateFormat(fromTemplate: "MMM yyyy", options: 0, locale: NSLocale.current)
	let formatter = DateFormatter()
	formatter.dateFormat = format

	return formatter
}()

let yearFormatter: DateFormatter = {
	let format = DateFormatter.dateFormat(fromTemplate: "yyyy", options: 0, locale: NSLocale.current)
	let formatter = DateFormatter()
	formatter.dateFormat = format

	return formatter
}()

let mediumDateFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateStyle = DateFormatter.Style.medium

	return formatter

}()

let fullDateFormatter: DateFormatter = {
	let _dateFormatter = DateFormatter()
	_dateFormatter.calendar = Calendar(identifier: .gregorian)
	_dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.'SSSZZZZZ"
	return _dateFormatter
}()

func gregorianMonthForDate(_ monthDate: Date) -> (start: Date, end: Date) {
	let calendar = Calendar.current
	let year = calendar.component(.year, from: monthDate)
	let month = calendar.component(.month, from: monthDate)

	var components = DateComponents()
	components.year = year
	components.month = month
	components.day = 1

	let start = calendar.date(from: components)!
	let days = calendar.range(of: Calendar.Component.day, in: Calendar.Component.month, for: start)!

	var end = calendar.date(byAdding: DateComponents(day: days.count), to: start)!
	end = calendar.date(byAdding: DateComponents(second: -1), to: end)!

	return (start, end)
}

extension Date {
	func stringValue() -> String {
		let strDate = fullDateFormatter.string(from: self)
		return strDate
	}

	func mediumDateString() -> String {
		mediumDateFormatter.doesRelativeDateFormatting = false
		let strDate = mediumDateFormatter.string(from: self)
		return strDate
	}

	func relativeDateString() -> String {
		mediumDateFormatter.doesRelativeDateFormatting = true
		let strDate = mediumDateFormatter.string(from: self)
		return strDate
	}

	func relativeTimeFrom(_ date: Date) -> String {
		let interval = abs(self.timeIntervalSince(date))
		if interval < 60 {
			return "less than a minute ago"
		}

		if interval < 3600 {
			return "\(floor(interval / 60)) minutes ago"
		}

		return "\(floor(interval / 60 / 60)) hours ago"
	}

	func addDate(years: Int, months: Int, weeks: Int, days: Int) -> Date {
		let calendar = Calendar.current
		var components = DateComponents()
		components.year = years
		components.month = months
		components.weekOfYear = weeks
		components.day = days

		let nextDate = calendar.date(byAdding: components, to: self)
		return nextDate!
	}

	func addTime(hours: Int, minutes: Int, seconds: Int) -> Date {
		let calendar = Calendar.current
		var components = DateComponents()
		components.hour = hours
		components.minute = minutes
		components.second = seconds

		let nextDate = calendar.date(byAdding: components, to: self)
		return nextDate!
	}

	func midnight() -> Date {
		let calendar = Calendar.current
		let year = calendar.component(.year, from: self)
		let month = calendar.component(.month, from: self)
		let day = calendar.component(.day, from: self)

		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day

		let midnight = calendar.date(from: components)!

		return midnight
	}

	func calendarYear() -> Int {
		let calendar = Calendar.current
		let year = calendar.component(.year, from: self)

		return year
	}

	func monthKey() -> String {
		let calendar = NSCalendar.current
		let year = calendar.component(.year, from: self)
		let month = calendar.component(.month, from: self)
		let monthKey = "\(year)_\(month)"

		return monthKey
	}
}
