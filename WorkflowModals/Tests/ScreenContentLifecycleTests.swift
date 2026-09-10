import Testing
import UIKit
import WorkflowUI
@_spi(WorkflowModalsImplementation) @testable import WorkflowModals

@MainActor
struct ScreenContentLifecycleTests {
    @Test(arguments: [false, true])
    func `Base replacement is prepared before view loading in a retained presentation wrapper`(loadView: Bool) throws {
        let screen = AnyModalToastContainer(base: TaggedScreen<Int>().asAnyScreen())
        let controller = try #require(screen.buildViewController(in: .empty) as? AnyModalToastContainerViewController)
        let lifecycle = controller.screenContent
        let initial = lifecycle.viewController
        var events: [String] = []
        let observation = lifecycle.observe { child in
            #expect(!child.isViewLoaded)
            events.append("prepare")
            return { events.append("retire") }
        }
        if loadView { controller.loadViewIfNeeded() }
        screen.viewControllerDescription(environment: .empty).update(viewController: controller)
        #expect(lifecycle.viewController === initial)
        #expect(events == ["prepare"])

        AnyModalToastContainer(base: TaggedScreen<String>().asAnyScreen())
            .viewControllerDescription(environment: .empty).update(viewController: controller)
        #expect(controller.screenContent === lifecycle)
        #expect(lifecycle.viewController === controller.baseViewController)
        #expect(lifecycle.viewController !== initial)
        #expect(events == ["prepare", "retire", "prepare"])
        #expect(lifecycle.viewController.isViewLoaded == loadView)
        observation.remove()
        #expect(events == ["prepare", "retire", "prepare", "retire"])
    }
}

private struct TaggedScreen<Tag>: Screen {
    func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        ViewControllerDescription(environment: environment, build: { TaggedController<Tag>() }, update: { _ in })
    }
}

private final class TaggedController<Tag>: UIViewController {}
