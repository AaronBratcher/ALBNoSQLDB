//
//  TransactionView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher on 5/16/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import SwiftUI
import Combine

struct TransactionView: View {
	@ObservedObject var transactionVM: TransactionViewModel
	@Environment(\.presentationMode) var presentationMode

	private var isValidAmount: Bool {
		return transactionVM.amount.count > 0 && transactionVM.amount.isCurrencyString
	}

	var formatter: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = .currency
		numberFormatter.maximumFractionDigits = 2
		return numberFormatter
	}()

	var body: some View {
		NavigationView() {
			Form {
				DatePicker(selection: $transactionVM.date, displayedComponents: .date) {
					Text("Date")
				}
				TextField("Description", text: $transactionVM.description)
				TextField("Amount", text: $transactionVM.amount)
			}
				.navigationBarTitle(transactionVM.transaction == nil ? "New Transaction" : "Edit Transaction")
				.navigationBarItems(trailing: Button("Save") {
					self.transactionVM.save()
					self.presentationMode.wrappedValue.dismiss()
				})
		}
	}
}

struct TransactionView_Previews: PreviewProvider {
	static var previews: some View {
		TransactionView(transactionVM: TransactionViewModel())
	}
}
