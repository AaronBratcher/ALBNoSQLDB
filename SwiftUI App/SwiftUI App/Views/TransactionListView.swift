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
					NavigationLink(destination: EditTransactionView(transactionVM: TransactionViewModel(transaction: transaction))) {
						CellView(transaction: transaction!)
					}
				}.onDelete(perform: transactionListVM.remove(at:))
			}
				.listStyle(GroupedListStyle())
				.navigationBarTitle("Transactions")
				.navigationBarItems(leading: EditButton(), trailing: AddButton(addNewTransaction: $addNewTransaction))
		}.sheet(isPresented: $addNewTransaction) {
			AddTransactionView(transactionVM: TransactionViewModel())
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

#if DEBUG
	struct ContentView_Previews: PreviewProvider {
		static var previews: some View {
			TransactionListView()
		}
	}
#endif
