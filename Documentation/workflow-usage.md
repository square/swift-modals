# Workflow Usage

## 1. Install a modal host

_**Note**: If you're using `Modals` and set up a `ModalHostContainerViewController` at the root of your app, you do not need to set up a `ModalHostContainer`._

`WorkflowModals` uses a container screen to host presented modals. In order to present modals within your application, you must install a `ModalHostContainer` at the root of your workflow hierarchy. For example, in your scene delegate you could map your workflow's rendering:

```swift
func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)

    // Set up the modal host
    let rootWorkflow = MyRootWorkflow()
        .ignoringOutput()
        .mapRendering(ModalHostContainer.init)

    window.rootViewController = WorkflowHostingController(workflow: rootWorkflow)

    self.window = window
    window.makeKeyAndVisible()
}
```

## 2. Define a modal presentation style

`WorkflowModals` uses the same presentation style types as `Modals` - for an example style, see the [vanilla UIKit usage guidelines](uikit-usage.md#2-define-a-modal-presentation-style).

## 3. Render a modal

Now that we have a host and a modal style, render a modal in our workflow. The framework provides a `ModalContainer` screen, which allows you to render a "base" screen and an array of modals to present over that screen. `ModalContainer` is generic over two parameters: the base screen type, and the screen type for the modal (which can be `AnyScreen` if modals of different screen types are being rendered). Each modal can have its own presentation style, which is not tied to the rendering type in any way - instead, create a `Modal` with your screen, presentation style, and identifying key, and pass those modals into the `ModalContainer`:

```swift
struct ModalWorkflow: Workflow {
    typealias Rendering = ModalContainer<ModalScreen, ModalScreen>

    struct State {
        var showModal: Bool
    }

    enum Action: WorkflowAction {
        typealias WorkflowType = ModalWorkflow

        case showModal
        case dismissModal

        func apply(toState state: inout ModalWorkflow.State) -> ModalWorkflow.Output? {
            switch self {
            case .showModal:
                state.showModal = true
            case .dismissModal:
                state.showModal = false
            }
            return nil
        }
    }

    func makeInitialState() -> State {
        State(showModal: false)
    }

    func render(state: State, context: RenderContext<Self>) -> Rendering {
        let sink = context.makeSink(of: Action.self)

        let baseScreen = ModalScreen(buttonText: "Present Modal") {
            sink.send(.showModal)
        }

        return baseScreen.presenting {
            if state.showingModal {
                ModalScreen(buttonText: "Dismiss Modal") {
                    sink.send(.dismissModal)
                }.modal(key: "modal", style: MyModalStyle())
            }
        }
    }
}

struct ModalScreen: Screen {
    var buttonText: String
    var onTap: () -> Void

    // screen implementation here
}
```

![card-modal](card-modal.gif)
