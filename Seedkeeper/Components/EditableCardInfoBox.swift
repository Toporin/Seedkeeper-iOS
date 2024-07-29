//
//  EditableCardInfoBox.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import SwiftUI

enum EditableCardInfoBoxContentMode  {
    case text(String)
    case pin
    case fixedText(String)
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
                editableText = placeholder
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
    @State private var isEditing = false
    @State private var editableText: String
    
    let mode: EditableCardInfoBoxContentMode
    let backgroundColor: Color
    var backgroundColorOpacity: Double?
    var width: CGFloat?
    var height: CGFloat?
    var action: (EditableCardInfoBoxContentMode) -> Void
    
    init(mode: EditableCardInfoBoxContentMode, backgroundColor: Color, width: CGFloat? = nil, height: CGFloat? = nil, backgroundColorOpacity: Double? = nil, action: @escaping (EditableCardInfoBoxContentMode) -> Void) {
        self.mode = mode
        self.backgroundColor = backgroundColor
        self.width = width
        self.action = action
        self.height = height
        self.backgroundColorOpacity = backgroundColorOpacity
        
        switch mode {
        case .text(let initialText):
            _editableText = State(initialValue: "")
        case .pin:
            _editableText = State(initialValue: "Update PIN code")
        case .fixedText(let initialText):
            _editableText = State(initialValue: initialText)
        }
    }
    
    var body: some View {
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
                        TextField("", text: $editableText, onEditingChanged: {(editingChanged) in
                            if editingChanged {
                                print("TextField focused")
                            } else {
                                print("TextField focus removed")
                                action(.text(editableText))
                                isEditing = false
                            }
                        })
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
                if case .text = mode {
                    isEditing.toggle()
                    if !isEditing {
                        action(.text(editableText))
                    }
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
    }
}
