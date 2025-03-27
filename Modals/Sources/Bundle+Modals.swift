import Foundation

private final class MarkerClass {}

extension Bundle {

    static let modalsResources: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        let modals = Bundle(for: MarkerClass.self)

        guard let resourcePath = modals.path(forResource: "ModalsResources", ofType: "bundle"),
              let bundle = Bundle(path: resourcePath)
        else {
            fatalError("Could not load bundle ModalsResources")
        }
        return bundle
        #endif
    }()
}
