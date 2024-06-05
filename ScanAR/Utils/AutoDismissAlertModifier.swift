//
//  AutoDismissAlertModifier.swift
//  ScanAR
//
//  Created by Chaman on 31/05/24.
//

import SwiftUI

struct AutoDismissAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let dismissAfter: Double

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                Alert(title: Text(title), message: Text(message))
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
                        isPresented = false
                    }
                }
            }
    }
}

extension View {
    func autoDismissAlert(isPresented: Binding<Bool>, title: String, message: String, dismissAfter: Double) -> some View {
        self.modifier(AutoDismissAlertModifier(isPresented: isPresented, title: title, message: message, dismissAfter: dismissAfter))
    }
}
