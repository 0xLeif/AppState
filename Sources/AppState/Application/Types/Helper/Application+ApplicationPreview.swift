#if canImport(SwiftUI)
import SwiftUI

extension Application {
    struct ApplicationPreview<Content: View>: View {
        let dependencyOverrides: [DependencyOverride]
        let content: () -> Content

        init(
            dependencyOverrides: [DependencyOverride],
            content: @escaping () -> Content
        ) {
            self.dependencyOverrides = dependencyOverrides
            self.content = content
        }

        var body: some View {
            content()
        }
    }
}
#endif
