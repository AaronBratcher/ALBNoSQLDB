//
//  StringExtensions.swift
//  Money Trak
//
//  Created by Aaron Bratcher on 3/26/16.
//  Copyright © 2016 Aaron L. Bratcher. All rights reserved.
//

import Foundation

extension String {
	func intValue(isCurrency: Bool = true) -> Int {
		guard let decimalSeparator = NSLocale.current.decimalSeparator
			, let groupingSeparator = NSLocale.current.groupingSeparator
			else { return 0 }

		var inputString = self
		var negative = false

		// remove groupingSeparator from inputString
		let groupingInput = CharacterSet(charactersIn: groupingSeparator)
		var commaRange = inputString.rangeOfCharacter(from: groupingInput)

		while commaRange != nil {
			inputString = inputString.replacingCharacters(in: commaRange!, with: "")
			commaRange = inputString.rangeOfCharacter(from: groupingInput)
		}

		let invalidCharacters = CharacterSet(charactersIn: "0123456789\(decimalSeparator)-").inverted

		if inputString.rangeOfCharacter(from: invalidCharacters) != nil {
			return 0
		}

		let amountParts = inputString.components(separatedBy: decimalSeparator)
		var value = (amountParts[0] as NSString).integerValue
		if value < 0 {
			value *= -1
			negative = true
		}

		if isCurrency {
			value *= 100
			if amountParts.count > 1 {
				var decimal = amountParts[1]
				if decimal.count > 2 {
					decimal = (decimal as NSString).substring(to: 2)
				}
				if decimal.count == 1 {
					decimal += "0"
				}

				value += (decimal as NSString).integerValue
			}
		}

		if negative {
			value *= -1
		}

		return value
	}

	var isCurrencyString: Bool {
		return currencyString == self
	}

	var currencyString: String {
		let input = self as NSString

		guard var decimalSeparator = NSLocale.current.decimalSeparator,
			var groupingSeparator = NSLocale.current.groupingSeparator
			else { return "" }
		if groupingSeparator == "." { groupingSeparator = #"\."# }
		if decimalSeparator == "." { decimalSeparator = #"\."# }

		let testPattern = "^-?([0-9]{1,3}(\(groupingSeparator)?[0-9]{3})*)(\(decimalSeparator)?[0-9]{0,2})$"

		guard let expression = try? NSRegularExpression(pattern: testPattern) else { return "" }

		let matches = expression.matches(in: self, options: [], range: NSMakeRange(0, input.length)).map {
			input.substring(with: $0.range)
		}

		return matches.joined()
	}
}
