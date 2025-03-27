# Tips

## The Modal Host

Modal presentations are hoisted to a *modal host* view controller, which is typically near the root of your application. To find the modal host, the presenting view controller must be in the same view controller hierarchy as the modal host.

If you encounter an error like one of the following:

> The parent view controller hierarchy did not contain a modal host.
>
> Found a presentingViewController (\<view controller>) when attempting to find the modal host.
>
> \<view controller> has no parent view controller, which means we cannot find a modal host.

It means that you've attempted a modal presentation from a view controller that can't reach a modal host in its ancestry.

This might happen if:

1. Your view controller has been presented in a UIKit modal presentation by some ancestor view controller. UIKit modal presentations create a new view controller hierarchy, which prevents the Modals framework from finding the modal host.

2. Your view controller has been presented in a new window.

3. You don't have a modal host set up.

To fix this (1), find the ancestor that is presenting a modal with UIKit. If possible, convert that presentation to use the Modals framework, by replacing calls to `present()` with `modalPresenter.present(viewController:style:)`.

In cases 2 or 3, you'll need to install a modal host in the view controller hierarchy. You can follow the usage guides for [UIKit](uikit-usage.md) or [Workflow](workflow-usage.md).

Additionally, this could sometimes mean that your view controller’s parent/child hierarchy is not set up correctly. Your view controller’s *view* may be in the hierarchy, but its parent relationship is not set up. In these cases, please inspect custom container view controllers to ensure they follow [Apple's guidelines for view controller containment](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html).

## Modal Styles

To create modal styles, implement a type that conforms to `ModalPresentationStyle`. This allows you to define many aspects of modal behavior, positioning, enter and exit transitions, etc. See the examples in the `Samples` directory for more information and common use cases.

The modal presentation APIs expect a `ModalPresentationStyleProvider`, which allow you to define styles in the form of `(ViewEnvironment) -> ModalPresentationStyle`, in order to derive concrete styles based on environmental traits or stylesheets. But you can also just wrap a simple `ModalPresentationStyle`.

## Modal Lifetime

If your modal is being dismissed before you expect it to be, it’s quite possible that your `ModalLifetime` is being deallocated. Set a breakpoint in `LifetimeToken.deinit` in order to debug this. You must retain your `ModalLifetime` for as long as you would like the modal to be displayed.

## UIKit & Objective-C

The `modalPresenter` view controller property is only supported from Swift. If you need to present a modal via UIKit in ObjC, you will need to add an `@objc`-exposed Swift extension in your module that calls `modalPresenter.present` with the correct style (and the style’s associated configuration options), which you can then call from Objective-C, using the returned `MDLModalLifetime` to dismiss your modal. Note that since `ModalLifetime` is a protocol, you must use an `id<MDLModalLifetime>` as your property type.


```swift
extension UIViewController {

    // Reminder: All Objective-C extensions exist in a single global namespace
    // on the type. Replace `xyz_` with your type prefix of choice for your
    // module to avoid conflicting with extensions of the same name in other
    // modules.

    @objc func xyz_presentFullScreenModal(
        _ modal : UIViewController,
        completion : (() -> ())?
    ) -> ModalLifetime {
        self.modalPresenter.present(
            modal,
            style: .myFullModalStyle,
            completion: completion
        )
    }
}
```

## Avoid destructive renders in Workflow

When you wish to conditionally render modals or toasts in a workflow, you should always render a `ModalContainer` or `ToastContainer`, and conditionally include the modals and toasts within it, rather than conditionally rendering the container itself.

Conditionally rendering the container (and in general, conditionally changing the screen hierarchy) will cause the view controller hierarchy to change, and cause Workflow to tear down and recreate the backing view controller of the container and the base screen.

This will result in you losing transitory view state like scroll position, and also can cause performance issues during view controller reallocation.

```swift
// ✅ Good
func render(state: State, context: RenderContext<Self>) -> Rendering {
	baseScreen.presentingModals {
		if state.isShowingModal {
			Modal(...)
		}
	}
}

// ❌ Avoid
func render(state: State, context: RenderContext<Self>) -> Rendering {
	if state.isShowingModal {
		return baseScreen.asAnyScreen()
	} else {
		return baseScreen.presentingModals {
			Modal(...)
		}
		.asAnyScreen()
	}
}
```

## Self-sizing Modals

Many modal styles are “self-sizing”, meaning they rely on the size of their content to set their frame and position on screen. Modals uses the [`preferredContentSize`](https://developer.apple.com/documentation/uikit/uiviewcontroller/preferredcontentsize) property on presented view controllers to determine sizing. You'll need to set this value yourself on any custom view controllers you want to present.

`preferredContentSize` is how `UIViewController`s indicate what size they would like to be drawn at to both standard system modals, and to the Modals framework. This is a “push”-based API, where the inner-most view controller(s) in the view controller hierarchy set their `preferredContentSize`, and then it flows upwards towards the outermost view controller.

This flowing happens via the [`preferredContentSizeDidChange`](https://developer.apple.com/documentation/uikit/uicontentcontainer/preferredcontentsizedidchange(forchildcontentcontainer:)) API. All view controllers in the hierarchy from the innermost view controller out to the outermost view controller must implement this method to ensure that the `preferredContentSize` flows up to the outermost view controller. It is usually implemented somewhat like this:

```swift
public override func preferredContentSizeDidChange(
	forChildContentContainer container: UIContentContainer
) {
	super.preferredContentSizeDidChange(forChildContentContainer: container)

	/// Ensure this is the child view controller you care about.
	guard container === someChild else { return }

	let newSize = someChild.preferredContentSize
		
	if preferredContentSize != newSize {
		preferredContentSize = newPreferredContentSize
	}
}
```

If you’re finding that your screen or view controller is not properly self-sizing, it’s usually because a view controller in your hierarchy is not respecting the `preferredContentSize` of one of its children. Inspect the view controller hierarchy’s code, or by printing the `preferredContentSize` down the tree to determine where the missing link in the chain is.

For performance reasons, Modals avoids using preferred content size when possible. When implementing a modal style that needs access to the preferred content size, you must opt-in to receive the size within your style’s behavior preferences:

```swift
public func behaviorPreferences(
  for context: ModalBehaviorContext
) -> ModalBehaviorPreferences {
    .init(
        **usesPreferredContentSize: true,**
        ...
    )
}
```

Once this is done, you can access the `preferredContentSize` of your modal (if it’s available) from `ModalPresentationContext`. It’s important to note that the `preferredContentSize` may not always be known, so you should always have a fallback prepared in case it is unknown.

## Migration Strategies

In most cases, you can convert UIKit- and Workflow-based modal presentations directly to `Modals` and `WorkflowModals` presentations.

### From Workflow

If you're using a modal container screen based on [Workflow's sample modal container](https://github.com/square/workflow-swift/blob/main/Samples/ModalContainer/Sources/ModalContainerScreen.swift), you can convert it like this:

```swift
// Old:
ModalContainerScreen(
    baseScreen: baseScreen,
    modals: [
        ModalContainerScreen.Modal(
            screen: modalScreen,
            style: .fullScreen(),
            key: "my-modal"
        )
    ]
)

// New:
ModalContainer(
    base: baseScreen,
    modals: [
        Modal(
            key: "my-modal",
            style: .full(),
            content: modalScreen
        )
    ]
)

// Which is the same as:
baseScreen.presentingModals {
    Modal(
       key: "my-modal",
       style: .full(),
       content: modalScreen
    )
}
```

### From UIKit

```swift
// Old:
present(viewController, animated: true)

// New:
self.modalLifetime = self.modalPresenter.present(
    viewController,
    style: .full()
)
```

## Transitional migration options

When presenting with `Modals`, you may encounter problems if there is an ancestor modal presentation that has not been migrated (see [the section above on the modal host](#the-modal-host) for symptoms of this).

The preferred way to fix this is to find the ancestor that is presenting a modal with UIKit, and convert that presentation to use the Modals framework.

If it is not practical to convert the ancestor to the new framework, you can create a transitional shim to wrap your the view controllers you want to present in a modal host, and present that instead. This will ensuring that there is a modal host in the presented view controller hierarchy.

## Presenting system view controllers

Some Apple-vended view controllers have content that is rendered out-of-process, or have other special behavior, and must be presented using the standard UIKit `present` method. These include:

- `UIActivityViewController`
- `UIAlertController`
- `QLPreviewController`
- `PKAddPaymentPassViewController`
- and subclasses of these

## Presenting Workflow Modals from UIKit

If you have a Workflow that renders Modals without a base screen which need to be presented directly from UIKit, you can do so with the `modalListObserver` on `UIViewController`.

Generally, such modal presentations must meet two or more of the following conditions to make a `modalListObserver` a desirable approach:

1. The modals have no base screen from which they can otherwise be presented.
2. The potential modals that may be presented contain multiple root modals of different presentation styles.
3. Modals are optionally presented, and there are cases where no modals are presented.

Otherwise, you should prefer to present modals using the standard methods described in the usage docs.

### Example

```swift
let workflow = MyWorkflow().mapRendering { rendering in
    ModalsRendering(
        modals: rendering.modals,
        toasts: rendering.toasts,
    )
}

// Note: `modalListObserver` is provided by the Modals framework on `UIViewController`.
self.observationLifetime = self.modalListObserver.observe(workflow) { [weak self] output in
    guard let self else { return }
    switch output {
    case .done:
       self.observationLifetime.stopObserving()
       self.observationLifetime = nil    
    }
}
```

This works by spinning up a `WorkflowHost` internally, rendering the workflow, and converting the rendered modal screens to view controllers using the same mechanism that the standard `ModalContainer` uses. The modals will be inserted into the list of modals presented by the view controller that owns the `modalListObserver`, and will automatically be presented and dismissed dynamically as the workflow’s rendering changes.

You must retain the lifetime token returned by the `observe` method. When the token is released, the observation of the workflow stops, all its presented modals are dismissed, and the `WorkflowHost` is torn down.
