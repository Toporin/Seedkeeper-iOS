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
            VStack {
                List(pickerOptions.items, id: \.self) { item in
                    Button(action: {
                        pickerOptions.selectedOption = item
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(item.humanReadableName().showWithFirstLetterAsCapital())
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
            .background(Color.clear)
        }
        .background(Color.clear)
    }
}

extension View {
    func blurredSheet<Content: View>(_ style: AnyShapeStyle, show: Binding<Bool>, onDismiss: @escaping ()->(), @ViewBuilder content: @escaping ()->Content) -> some View {
        self
            .sheet(isPresented: show, onDismiss: onDismiss) {
                content()
                    .background(RemoveBackgroundColor())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        Rectangle()
                            .fill(style)
                            .ignoresSafeArea(.container, edges: .all)
                    }
            }
    }
}

fileprivate struct RemoveBackgroundColor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
    /*func makeUIView(context: Context) -> some UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.async {
            uiView.superview?.superview?.backgroundColor = .clear
        }
    }*/
}
