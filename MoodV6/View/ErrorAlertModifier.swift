import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                actions: {
                    Button("OK") { action() }
                },
                message: {
                    if let error = error {
                        Text(error.localizedDescription)
                    }
                }
            )
    }
}

extension View {
    func withErrorAlert(error: Binding<Error?>, action: @escaping () -> Void = {}) -> some View {
        self.modifier(ErrorAlertModifier(error: error, action: action))
    }
}
