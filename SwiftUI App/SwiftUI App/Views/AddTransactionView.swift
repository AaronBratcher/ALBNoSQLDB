//
//  AddTransactionView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher  on 5/27/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import SwiftUI

struct AddTransactionView: View {
	@ObservedObject var transactionVM: TransactionViewModel
	@Environment(\.presentationMode) var presentationMode

	var body: some View {
		NavigationView {
			TransactionView(transactionVM: transactionVM)
				.navigationBarTitle("New Transaction")
				.navigationBarItems(trailing: Button("Save") {
					self.transactionVM.save()
					self.presentationMode.wrappedValue.dismiss()
				}.disabled(!transactionVM.isValidAmount)
				)
		}
	}
}

#if DEBUG
	struct AddTransactionView_Previews: PreviewProvider {
		static var previews: some View {
			AddTransactionView(transactionVM: TransactionViewModel())
		}
	}
#endif
