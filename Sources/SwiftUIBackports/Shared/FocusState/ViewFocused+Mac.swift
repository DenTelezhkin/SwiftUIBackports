//
//  ViewFocused+Mac.swift
//  
//
//  Created by Denys Telezhkin on 06.03.2024.
//

import Foundation
import SwiftUI

#if canImport(AppKit)
import AppKit
public extension Backport where Wrapped: View {
    func focused<Value>(_ binding: Binding<Value?>, equals value: Value) -> some View where Value: Hashable {
        wrapped.modifier(FocusModifier(focused: binding, value: value))
    }
}

private struct FocusModifier<Value: Hashable>: ViewModifier {
    @Backport.StateObject private var coordinator = Coordinator()
    @Binding var focused: Value?
    var value: Value

    func body(content: Content) -> some View {
        content
            // this ensures when the field goes out of view, it doesn't retain focus
            .onDisappear { focused = nil }
            .sibling(forType: NSTextField.self) { proxy in
                let view = proxy.instance
                coordinator.observe(field: view)

                coordinator.onBegin = {
                    focused = value
                }

                coordinator.onEnd = {
                    guard focused == value else { return }
                    focused = nil
                }

                if focused == value, view.isEditable, view.isEnabled {
                    view.becomeFirstResponder()
                }
            }
            .backport.onChange(of: focused) { newValue in
                if newValue == nil {
                    coordinator.field?.resignFirstResponder()
                }
            }
    }
}

private final class Coordinator: NSObject, ObservableObject, NSTextFieldDelegate {
    private(set) weak var field: NSTextField?
    weak var _delegate: NSControlTextEditingDelegate?
    var onBegin: () -> Void = { }
    var onEnd: () -> Void = { }

    override init() { }

    func observe(field: NSTextField) {
        self.field = field
        
        if field.delegate !== self && _delegate == nil {
            _delegate = field.delegate
            field.delegate = self
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        _delegate?.controlTextDidEndEditing?(obj)
        onEnd()
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        _delegate?.controlTextDidBeginEditing?(obj)
        onBegin()
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        if _delegate?.responds(to: aSelector) ?? false { return true }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) { return self }
        return _delegate
    }
}
#endif
