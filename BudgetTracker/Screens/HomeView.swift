//
//  ContentView.swift
//  BudgetTracker
//
//  Created by Jerico Villaraza on 8/1/24.
//

import StoreKit
import SwiftData
import SwiftUI

struct HomeView: View {    
    
    @Environment(\.modelContext) var modelContext
    
    #if DEBUG
    @AppStorage("isExpensesEmpty") var isExpensesEmpty = true
    @AppStorage("isIncomesEmpty") var isIncomesEmpty = true
    
    @State var expenseDayCounter: Double = 0
    @State var incomeDayCounter: Double = 0
    #endif
    
    @State private var isAddViewPresented = false
    
    @State private var expenseSortDescriptors: [SortDescriptor<Expense>] = [
        SortDescriptor(\Expense.createdDate, order: .reverse),
        SortDescriptor(\Expense.title)
    ]
    
    @State private var incomesSortDescriptors: [SortDescriptor<Income>] = [
        SortDescriptor(\Income.createdDate, order: .reverse),
        SortDescriptor(\Income.title)
    ]

    
    @State private var selectedSegment: HomeViewSegments = .expense
    
    var body: some View {
        Navigation {
            VStack(alignment: .leading) {
                
                if selectedSegment == .expense {
                    ExpenseListView(sortDescriptors: expenseSortDescriptors)
                } else if selectedSegment == .income {
                    IncomeListView(sortDescriptors: incomesSortDescriptors)
                }
                
                Picker("Select a segment", selection: $selectedSegment) {
                    Text("Expenses").tag(HomeViewSegments.expense)
                    Text("Income").tag(HomeViewSegments.income)
                 }
                 .pickerStyle(SegmentedPickerStyle())
                 .frame(width: 200)
                 .padding()
            }
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                
                #if DEBUG
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("add mock data", systemImage: "flame", action: addMockData)
                    Button("delete all data", systemImage: "trash", action: deleteAlldata)
                }
                #endif
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        Picker("Sort", selection: $expenseSortDescriptors){
                            Text("Sort by time")
                                .tag([
                                    SortDescriptor(\Expense.createdDate, order: .reverse),
                                    SortDescriptor(\Expense.title)
                                ])
                            Text("Sort by name")
                                .tag([
                                    SortDescriptor(\Expense.title),
                                    SortDescriptor(\Expense.createdDate, order: .reverse)
                                ])
                        }
                    }
                    
                    Button("Add button", systemImage: "plus") {
                        isAddViewPresented = true
                    } 
                }
            }
            .sheet(isPresented: $isAddViewPresented) {
                switch selectedSegment {
                case .expense:
                    AddExpenseView()
                case .income:
                    AddIncomeView()
                }
            }
        }
    }
    
    #if DEBUG
    func addMockData() {
        
        switch selectedSegment {
        case .expense:
            let expenses: [Expense] = Bundle.main.decode("expense.mock.json")
            
            for expense in expenses {
                let date: Date = .now.addingTimeInterval(86400 * expenseDayCounter)
                expense.date = date
                modelContext.insert(expense)
            }
            
            expenseDayCounter = expenseDayCounter - 1
            isExpensesEmpty = false
        case .income:
            let incomes: [Income] = Bundle.main.decode("income.mock.json")
            
            for income in incomes {
                let date: Date = .now.addingTimeInterval(86400 * incomeDayCounter)
                income.date = date
                modelContext.insert(income)
            }
            
            incomeDayCounter = incomeDayCounter - 1
            isIncomesEmpty = false
        }
    }
    
    func deleteAlldata() {
        do {
            switch selectedSegment {
            case .expense:
                let descriptor = FetchDescriptor<Expense>()
                let toDeleteData = try modelContext.fetch(descriptor)
                
                for expense in toDeleteData {
                    modelContext.delete(expense)
                }
                
                isExpensesEmpty = true
                incomeDayCounter = 0
            case .income:
                let descriptor = FetchDescriptor<Income>()
                let toDeleteData = try modelContext.fetch(descriptor)
                
                for income in toDeleteData {
                    modelContext.delete(income)
                }
                
                isIncomesEmpty = true
                incomeDayCounter = 0
            }
        } catch {
            fatalError("Something went wrong.")
        }
    }
    #endif
}

#Preview {
    HomeView()
}

