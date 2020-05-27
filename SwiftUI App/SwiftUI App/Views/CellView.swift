//
//  CellView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher  on 5/27/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import SwiftUI

struct CellView: View {
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
struct CellView_Previews: PreviewProvider {
    static var previews: some View {
        CellView(transaction: sampleTransactions[0])
    }
}
#endif
