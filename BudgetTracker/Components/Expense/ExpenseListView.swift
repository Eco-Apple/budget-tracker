//
//  ExpenseListView.swift
//  BudgetTracker
//
//  Created by Jerico Villaraza on 8/27/24.
//

import StoreKit
import SwiftData
import SwiftUI

fileprivate struct ExpenseSectionListViewWrapper: View {
    
    var sortDescriptors: [SortDescriptor<Expense>]
        
    @State var filterDate: Date
    @State var limit: Int
    
    private var initialLimitValue: Int
    
    var body: some View {
        ExpenseSectionListView(of: filterDate, limit: $limit, sortDescriptors: sortDescriptors, initialLimitValue: initialLimitValue)
    }
    
    init(of filterDate: Date, sortDescriptors: [SortDescriptor<Expense>], limit: Int) {
        self.filterDate = filterDate
        self.sortDescriptors = sortDescriptors
        self.limit = limit
        self.initialLimitValue = limit
    }
}

fileprivate struct ExpenseSectionListView: View {
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("isExpensesEmpty") var isExpensesEmpty = true
    
    @Query var expenses: [Expense]
    
    @Binding private var limit: Int
    
    @State private var isAlertPresented = false
    @State private var expensesToDelete: [Expense] = []
    
    private var limitToExpand: Int = 10 // default 10; test 4
    
    var initialLimitValue: Int
    
    var filterDate: Date
    
    var body: some View {
        if expenses.isNotEmpty {
            Section(filterDate.format(.dateOnly, descriptive: true)) {
                HStack {
                    InfoTextView(label: "Total", currency: total())
                        .font(.headline)
                }
                ForEach(expenses.prefix(limit)) { expense in
                    NavigationLink(value: NavigationRoute.expense(.detail(expense))) {
                        ExpensItemView(expense: expense)
                    }
                }
                .onDelete { offsets in
                    expensesToDelete = []
                    for index in offsets {
                        let expense = expenses[index]
                        isAlertPresented = true
                        expensesToDelete.append(expense)
                    }
                }
                .alert(isPresented: $isAlertPresented){
                    Alert(
                        title: Text("Are you sure you want to delete \(expenses.getPluralSuffix(singular: "this", plural: "these")) expense\(expenses.getPluralSuffix(singular: "", plural: "s"))?"),
                        message: Text("You cannot undo this action once done."),
                        primaryButton: .destructive(Text("Delete"), action: actionDelete),
                        secondaryButton: .cancel()
                    )
                }
                if expenses.count > limit || expenses.count > initialLimitValue {
                    Button(action: {
                        if expenses.count <= limitToExpand {
                            withAnimation {
                                if limit != limitToExpand {
                                    limit = limitToExpand
                                } else if limit == limitToExpand {
                                    limit = initialLimitValue
                                }
                            }
                        } else if expenses.count > limitToExpand {
                            navigate(.expense(.seeMore(filterDate, expenses)))
                        }
                    }) {
                        Text(limit != limitToExpand ? "See More" : "See Less")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    init(of filterDate: Date, limit: Binding<Int>, sortDescriptors: [SortDescriptor<Expense>], initialLimitValue: Int) {
        self.filterDate = filterDate
        self.initialLimitValue = initialLimitValue
        self._limit = limit
        
        let normalizedDate = Calendar.current.startOfDay(for: filterDate)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: normalizedDate)!
        
        var fetchDescriptor = FetchDescriptor<Expense>(predicate: #Predicate<Expense> { expense in
            if let expenseDate = expense.date {
                return expenseDate >= normalizedDate && expenseDate < nextDay
            } else {
                return false
            }
            
        }, sortBy: sortDescriptors)
        
        fetchDescriptor.fetchLimit = limit.wrappedValue + limitToExpand
        
        _expenses = Query(fetchDescriptor)
    }
    
    func total() -> Decimal {
        var result: Decimal = 0.0
        
        for val in expenses {
            result += val.amount
        }
        
        return result
    }
    
    func actionDelete() {
        for expense in expensesToDelete {
            modelContext.delete(expense)
        }
        
        do {
            let fetchDescriptor = FetchDescriptor<Expense>()
            let fetchExpenses = try modelContext.fetch(fetchDescriptor)
            
            if fetchExpenses.isEmpty {
                isExpensesEmpty = true
            }
            
            dismiss()
        } catch {
            fatalError("Error deleting expense")
        }
    }

}

struct ExpenseListView: View {
    @AppStorage("isExpensesEmpty") var isExpensesEmpty = true
    
    var sortDescriptors: [SortDescriptor<Expense>]
    
    let sectionsDate: [Date] = [
        Calendar.current.date(byAdding: .day, value: -2, to: Date.now)!,
        Calendar.current.date(byAdding: .day, value: -3, to: Date.now)!,
        Calendar.current.date(byAdding: .day, value: -4, to: Date.now)!,
    ]
        
    var body: some View {
        if !isExpensesEmpty{
            List {
                ExpenseSectionListViewWrapper(of: Date.now, sortDescriptors: sortDescriptors, limit: 5)
                ExpenseSectionListViewWrapper(of: Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!, sortDescriptors: sortDescriptors, limit: 3)
                ForEach(sectionsDate, id: \.self) { date in
                    ExpenseSectionListViewWrapper(of: date, sortDescriptors: sortDescriptors, limit: 3)
                }
            }
        } else {
            EmptyMessageView(title: "No Expense", message: "Press '+' button on the upper right corner to add new expense.")
        }
    }
}

#Preview {
    ExpenseListView(sortDescriptors: [SortDescriptor(\Expense.title)])
}
