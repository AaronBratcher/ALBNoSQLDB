//
//  TransactionView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher  on 5/27/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import SwiftUI

struct TransactionView: View {
    @ObservedObject var transactionVM: TransactionViewModel

    var body: some View {
        Form {
            DatePicker(selection: $transactionVM.date, displayedComponents: .date) {
                Text("Date")
            }
            TextField("Description", text: $transactionVM.description)
            TextField("Amount", text: $transactionVM.amount)
        }
    }
}

#if DEBUG
struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView(transactionVM: TransactionViewModel())
    }
}
#endif
