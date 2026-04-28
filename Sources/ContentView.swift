import SwiftUI

struct ContentView: View {
    @State private var showWelcome = true

    var body: some View {
        if showWelcome {
            WelcomeView {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showWelcome = false
                }
            }
        } else {
            HomeView()
        }
    }
}
