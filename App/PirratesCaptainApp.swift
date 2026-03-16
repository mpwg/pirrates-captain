import SwiftUI

@main
struct PirratesCaptainApp: App {
    @State private var root = CompositionRoot.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootShellView(root: root)
                .preferredColorScheme(.dark)
        }
    }
}
