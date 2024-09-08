//
//  AddIncomeView.swift
//  BudgetTracker
//
//  Created by Jerico Villaraza on 9/7/24.
//

import StoreKit
import SwiftUI

/*
 TODO:
 - DatePicker doesn't change the time when save
 */

struct AddIncomeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("isIncomesEmpty") var isIncomesEmpty = true
    
    @State var title: String = ""
    @State var note: String = ""
    @State var amount: Decimal? = nil
    @State var date: Date = .now
    
    @State private var isTimeEnabled: Bool = false
    
    @FocusState private var isFocus: Bool
    
    var currencySymbol = Locale.current.currencySymbol ?? ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    CurrencyField("eg. \(currencySymbol)10.00", value: $amount)
                        .focused($isFocus)
                }
                
                DatePicker(
                    "Date",
                    selection: $date,
                    displayedComponents: isTimeEnabled ? [.date, .hourAndMinute] : .date
                )

                Toggle(isOn: $isTimeEnabled) {
                    Text("Time")
                }
                
                Section {
                    TextField("Title", text: $title)
                    TextEditor(text: $note)
                        .placeHolder("Note", text: $note)
                        .frame(height: 150)
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle("New Income")
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addEntry).disabled(isConfirmDisabled())
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocus = true
                }
            }
        }
    }
    
    func isConfirmDisabled() -> Bool {
        title.isEmpty || amount == nil || amount! <= 0
    }
    
    func addEntry() {
        let newIncome = Income(title: title, note: note, amount: amount!,date: date, createdDate: .now, updateDate: .now, isTimeEnabled: isTimeEnabled)
        
        modelContext.insert(newIncome)
        isIncomesEmpty = false
        dismiss()
    }
}

#Preview {
    return AddIncomeView()
}
