//
//  KeyboardDismissal.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/17/25.
//


import SwiftUI
import UIKit

// MARK: - SwiftUI Solution

struct KeyboardDismissalViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissalViewModifier())
    }
}

// MARK: - UIKit Solution

extension UIViewController {
    func setupKeyboardDismissalOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
