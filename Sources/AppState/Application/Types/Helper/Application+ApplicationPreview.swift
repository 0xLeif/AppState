#if canImport(SwiftUI)
import SwiftUI

extension Application {
    struct ApplicationPreview<Content: View>: View {
        /// Held in `@State` so the overrides last as long as the preview's identity. Releasing a
        /// `DependencyOverride` restores the dependency it replaced.
        @SwiftUI.State private var dependencyOverrides: [DependencyOverride]
        let content: () -> Content

        init(
            dependencyOverrides: [DependencyOverride],
            content: @escaping () -> Content
        ) {
            self._dependencyOverrides = SwiftUI.State(initialValue: dependencyOverrides)
            self.content = content
        }

        var body: some View {
            content()
        }
    }
}
#endif
