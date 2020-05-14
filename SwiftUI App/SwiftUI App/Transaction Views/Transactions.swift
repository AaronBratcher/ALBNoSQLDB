//
//  ContentView.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher on 5/13/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import SwiftUI
import ALBNoSQLDB

struct Transactions: View {
    @ObservedObject var transactionManager = TransactionListManager()

    var body: some View {
        Text("Hello, World!")
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Transactions()
    }
}
#endif
