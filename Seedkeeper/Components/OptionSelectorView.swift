//
//  OptionSelectorView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation
import SwiftUI

protocol HumanReadable {
    func humanReadableName() -> String
}

struct PickerOptions<T: CaseIterable & Hashable & HumanReadable> {
    let placeHolder: String
    let items: [T]
    var selectedOption: T?
    
    var isItemSelected: Bool {
        return selectedOption != nil
    }
    
    init(placeHolder: String, items: T.Type, selectedOption: T? = nil) {
        self.placeHolder = placeHolder
        self.items = Array(items.allCases)
        self.selectedOption = selectedOption
    }
}

struct OptionSelectorView<T: CaseIterable & Hashable & HumanReadable>: View {
    @Binding var pickerOptions: PickerOptions<T>
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Colors.purpleBtn.edgesIgnoringSafeArea(.all)
            
            VStack {
                List(pickerOptions.items, id: \.self) { item in
                    Button(action: {
                        pickerOptions.selectedOption = item
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(item.humanReadableName())
                            .font(.headline)
                            .foregroundColor(.white)
                            .background(Color.clear)
                    }
                    .listRowBackground(Color.clear)
                }
                .padding(20)
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
    }
}
