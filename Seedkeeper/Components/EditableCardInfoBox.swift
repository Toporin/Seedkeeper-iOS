//
//  EditableCardInfoBox.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import SwiftUI
import CoreData

enum EditableCardInfoBoxContentMode  {
    case text(String)
    case pin  // TODO: remove
    case fixedText(String)  //TODO: remove
}

enum SelectableCardInfoBoxContentMode<T: CaseIterable & Hashable & HumanReadable> {
    case dropdown(PickerOptions<T>)
}

struct SelectableCardInfoBox<T: CaseIterable & Hashable & HumanReadable>: View {
    
    @State private var editableText: String
    
    let mode: SelectableCardInfoBoxContentMode<T>
    let backgroundColor: Color
    var backgroundColorOpacity: Double?
    var width: CGFloat?
    var height: CGFloat?
    var action: (SelectableCardInfoBoxContentMode<T>) -> Void
    
    init(mode: SelectableCardInfoBoxContentMode<T>, backgroundColor: Color, width: CGFloat? = nil, height: CGFloat? = nil, backgroundColorOpacity: Double? = nil, action: @escaping (SelectableCardInfoBoxContentMode<T>) -> Void) {
        self.mode = mode
        self.backgroundColor = backgroundColor
        self.width = width
        self.action = action
        self.height = height
        self.backgroundColorOpacity = backgroundColorOpacity
        
        switch mode {
        case .dropdown(let options):
            if let placeholder = options.selectedOption?.humanReadableName() {
//                editableText = placeholder
                _editableText = State(initialValue: placeholder)
            } else {
                _editableText = State(initialValue: options.placeHolder)
            }
        }
    }
    
    var body: some View {
        HStack {
            Group {
                if case .dropdown(let pickerOptions) = mode, let text = pickerOptions.selectedOption?.humanReadableName() {
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .padding(.leading, 16)
                } else {
                    Text(editableText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                        .fontWeight(.light)
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.leading, 16)
                }
            }
            .onTapGesture {
                if case .dropdown = mode {
                    action(mode)
                }
            }
            
            Spacer()
            
            Button(action: {
                if case .dropdown = mode {
                    action(mode)
                }
            }) {
                Image("ic_arrowdown")
            }
            .padding(.trailing, 12)
        }
        .frame(width: width, height: height ?? 55)
        .background(backgroundColor.opacity(backgroundColorOpacity ?? 1.0))
        .cornerRadius(20)
        .foregroundColor(.white)
    }
}

struct EditableCardInfoBox: View {
    @State private var isEditing = false // TODO: not used, remove?
    @State private var editableText: String
    @FocusState private var isFocused: Bool
    
    // Fetching the logins from SwiftData
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var savedLoginEntries: FetchedResults<UsedLogin>
    
    @State private var filteredLogins: [String] = []
    
    let mode: EditableCardInfoBoxContentMode
    let backgroundColor: Color
    var backgroundColorOpacity: Double?
    var width: CGFloat?
    var height: CGFloat?
    var shouldDisplaySuggestions: Bool
    var action: (EditableCardInfoBoxContentMode) -> Void
    var focusAction: (() -> Void)?
    
    init(mode: EditableCardInfoBoxContentMode, backgroundColor: Color, width: CGFloat? = nil, height: CGFloat? = nil, backgroundColorOpacity: Double? = nil, shouldDisplaySuggestions: Bool = false, action: @escaping (EditableCardInfoBoxContentMode) -> Void, focusAction: (() -> Void)? = nil) {
        self.mode = mode
        self.backgroundColor = backgroundColor
        self.width = width
        self.action = action
        self.height = height
        self.backgroundColorOpacity = backgroundColorOpacity
        self.shouldDisplaySuggestions = shouldDisplaySuggestions
        self.focusAction = focusAction
        
        switch mode {
        case .text(let initialText):
            _editableText = State(initialValue: "")
        case .pin:
            _editableText = State(initialValue: "Update PIN code")
        case .fixedText(let initialText):
            _editableText = State(initialValue: initialText)
        }
    }
    
    private func filterSuggestions() {
        guard !editableText.isEmpty else {
            filteredLogins = savedLoginEntries.map { $0.login ?? "" }
            return
        }
        
        filteredLogins = savedLoginEntries
            .map { $0.login ?? "" }
            .filter { $0.lowercased().contains(editableText.lowercased()) }
    }
    
    private func deleteSuggestion(_ suggestion: String) {
        if let loginEntry = savedLoginEntries.first(where: { $0.login == suggestion }) {
            if let context = loginEntry.managedObjectContext {
                context.delete(loginEntry)
                do {
                    try context.save()
                    filterSuggestions()
                } catch {
                    print("Failed to save context after deletion: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Group {
                    if case .text(let initialText) = mode {
                        ZStack(alignment: .leading) {
                            if editableText.isEmpty {
                                Text(initialText)
                                    .padding(.leading, 16)
                                    .fontWeight(.light)
                                    .foregroundColor(Color.white.opacity(0.8))
                            }
                            TextField("", text: $editableText, onEditingChanged: { editingChanged in
                                if editingChanged {
                                    filterSuggestions()
                                    self.focusAction?()
//                                    print("TextField focus:  \(editableText)") // TODO: debug
                                } else {
//                                    print("TextField focus removed: \(editableText)") // TODO: debug
                                    action(.text(editableText))
                                    isEditing = false
                                }
                            })
                            .focused($isFocused)
                            .onChange(of: editableText) { _ in
                                self.filterSuggestions()
                                action(.text(editableText)) // update textfield as soon as changed
//                                print("TextField onChange:  \(editableText)") // TODO: debug
                            }
                            .disableAutocorrection(true)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.leading, 16)
                        }
                    } else {
                        Text(editableText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(1)
                            .fontWeight(.light)
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding(.leading, 16)
                    }
                }
                .onTapGesture {
                    if case .text = mode {
                        isEditing = true
                    } else if case .pin = mode {
                        action(.pin)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    print("DEBUG Clicked on TextField button!") //TODO: remove
                    if case .text = mode {
                        isEditing = true
                    } else if case .pin = mode {
                        action(.pin)
                    }
                }) {
                    if case .fixedText = mode {
                        // nothing
                    }
                    else {
                        Image(systemName: "pencil")
                    }
                }
                .padding(.trailing, 12)
            }
            .frame(width: width, height: height ?? 55)
            .background(backgroundColor.opacity(backgroundColorOpacity ?? 1.0))
            .cornerRadius(20)
            .foregroundColor(.white)
            
            if shouldDisplaySuggestions && isFocused && !filteredLogins.isEmpty {
                VStack {
                    List(self.filteredLogins, id: \.self) { suggestion in
                        HStack {
                            Text(suggestion)
                                .foregroundColor(.gray)
                                .onTapGesture {
                                    isFocused = false
                                    editableText = suggestion
                                }
                            Spacer()
                            Button(action: {
                                deleteSuggestion(suggestion)
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .listRowSeparator(.hidden)
                    .background(Color.clear)
                    .frame(height: 150)
                }
                .background(Color.white)
                .cornerRadius(8)
            }
        }
    }
}
