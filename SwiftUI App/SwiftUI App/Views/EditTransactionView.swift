//
//  TransactionView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher on 5/16/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import SwiftUI
import Combine

struct EditTransactionView: View {
	@ObservedObject var transactionVM: TransactionViewModel
	@Environment(\.presentationMode) var presentationMode

	var body: some View {
		TransactionView(transactionVM: transactionVM)
			.navigationBarTitle("Edit Transaction")
			.navigationBarItems(trailing: Button("Save") {
				self.transactionVM.save()
				self.presentationMode.wrappedValue.dismiss()
			}.disabled(!transactionVM.isValidAmount)
			)
	}
}

#if DEBUG
	struct EditTransactionView_Previews: PreviewProvider {
		static var previews: some View {
			EditTransactionView(transactionVM: TransactionViewModel())
		}
	}
#endif
