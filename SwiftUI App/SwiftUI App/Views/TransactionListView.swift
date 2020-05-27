//
//  ContentView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher on 5/13/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import SwiftUI
import ALBNoSQLDB

struct TransactionListView: View {
	@ObservedObject var transactionListVM = TransactionListViewModel()
	@State private var addNewTransaction = false

	var body: some View {
		NavigationView {
			List() {
				Section() {
					TextField("Search", text: $transactionListVM.searchText)
				}
				ForEach(transactionListVM.transactions, id: \.self) { transaction in
					NavigationLink(destination: TransactionView(transactionVM: TransactionViewModel(transaction: transaction))) {
						CellView(transaction: transaction!)
					}
				}.onDelete(perform: transactionListVM.remove(at:))
			}
				.listStyle(GroupedListStyle())
				.navigationBarTitle("Transactions")
				.navigationBarItems(leading: EditButton(), trailing: AddButton(addNewTransaction: $addNewTransaction))
		}.sheet(isPresented: $addNewTransaction) {
			TransactionView(transactionVM: TransactionViewModel())
		}
	}
}

private struct AddButton: View {
	@Binding var addNewTransaction: Bool

	var body: some View {
		Button(action: {
			self.addNewTransaction.toggle()
		}) {
			Image(systemName: "plus.circle")
		}
	}
}

private struct CellView: View {
	var transaction: Transaction

	var body: some View {
		HStack {
			DateView(transaction: transaction)
				.padding(.trailing, 25.0)
			AmountLocationView(transaction: transaction)
		}
	}
}

private struct DateView: View {
	var transaction: Transaction

	var body: some View {
		VStack(alignment: .leading) {
			Text(dayFormatter.string(from: transaction.date))
				.font(.headline)
			Text(yearFormatter.string(from: transaction.date))
				.font(.footnote)
		}
	}
}

private struct AmountLocationView: View {
	var transaction: Transaction

	var body: some View {
		HStack() {
			Text(transaction.description)
				.font(.headline)
			Spacer()
			Text(transaction.amount.formatted())
				.font(.headline)
		}
	}
}

#if DEBUG
	struct ContentView_Previews: PreviewProvider {
		static var previews: some View {
			TransactionListView()
		}
	}
#endif
