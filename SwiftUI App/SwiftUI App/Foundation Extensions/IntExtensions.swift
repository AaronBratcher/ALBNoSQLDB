//
//  IntExtensions.swift
//  Money Trak
//
//  Created by Bratcher, Aaron on 5/15/17.
//  Copyright © 2017 Aaron L. Bratcher. All rights reserved.
//

import Foundation

extension Int {
	func formatted(useThousandsSeparator: Bool = true, keepDecimal: Bool = true) -> String {
		let amount = self
		let decimalSeparator = NSLocale.current.decimalSeparator!
		let groupingSeparator = NSLocale.current.groupingSeparator!

		var amountString = "\(abs(amount))"

		var length = amountString.count
		if length == 1 {
			amountString = "0" + amountString
			length = 2
		}
		var range = NSMakeRange(length - 2, 2)
		var formattedValue = ""
		if keepDecimal {
			formattedValue = decimalSeparator + (amountString as NSString).substring(with: range)
		}

		if length > 2 {
			if !useThousandsSeparator {
				formattedValue = (amountString as NSString).substring(to: length - 2) + formattedValue
			} else {
				amountString = (amountString as NSString).substring(to: length - 2)
				length = amountString.count
				while length > 0 {
					if length > 3 {
						range = NSMakeRange(length - 3, 3)
						formattedValue = groupingSeparator + (amountString as NSString).substring(with: range) + formattedValue
						amountString = (amountString as NSString).substring(to: length - 3)
					} else {
						formattedValue = amountString + formattedValue
						amountString = ""
					}

					length = amountString.count
				}
			}
		} else {
			formattedValue = "0" + formattedValue
		}

		if amount < 0 && formattedValue != "0" {
			formattedValue = "–" + formattedValue
		}

		return formattedValue
	}
}
