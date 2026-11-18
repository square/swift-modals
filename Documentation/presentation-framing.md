# Adjust presentation layout across an app

An app can adapt modal styles in one place. These APIs are optional. With no hooks installed and zero content insets, existing presentation layout and view hierarchies are unchanged. The hooks apply to modals only; toasts keep their existing layout.

## Style transform

Install the transform on the main actor before the first presentation:

```swift
ModalPresentationViewController.presentationStyleTransform = { style in
    AppModalStyle(wrapping: style)
}
```

The transform receives the original style resolved for the modal's environment, on presentation and on each modal update. The returned style controls presentation behavior, display values, decorations, and transitions. Updates do not pass an already transformed style back through the transform. Environment customization takes place before this hook, through the original style.

Changing the transform does not update existing presentations immediately. Call `setNeedsModalUpdate()` on the modal host to update modal styles.

## Content insets and fill

A full-screen presentation can keep its frame, overlay, and transition geometry while placing its content inside part of that frame:

```swift
var values = base.displayValues(for: context)
values.contentInsets = UIEdgeInsets(
    top: 0,
    left: context.containerSafeAreaInsets.left,
    bottom: 0,
    right: context.containerSafeAreaInsets.right
)
values.contentInsetsFillColor = appBackgroundColor
return values
```

Content insets move the content's view itself, not just its safe area. The modal's view is laid out inside the inset frame, and everything in it moves with it: navigation stacks, child view controllers, and hosted SwiftUI views. Content that ignores its safe area, or pins its subviews to its own edges, still stays out of the inset area. UIKit derives the content's safe area from the inset frame, so content that also respects its safe area does not receive the same inset twice.

Shadows, rounded corners, decorations, and the dimming overlay retain the presentation's geometry. Content insets also apply during transitions.

The presentation clips its content at the presentation's frame, not at the inset content frame, so content that draws beyond its own bounds can still appear in the inset area. The optional fill covers the area outside the content frame, including anything the content draws there. It does not receive touches or appear in the accessibility tree. A dynamic `UIColor` can supply different colors for light and dark appearances. Set the color to `nil` for a transparent inset area, which leaves anything the content draws there visible.

## Content of hosts presented by UIKit

UIKit can present a `ModalHostContainerViewController` directly. Its root content can need the same framing as a full-screen modal:

```swift
ModalHostContainerViewController.presentationRootContentFraming = { host in
    let insets = host.view.safeAreaInsets
    return .init(
        insets: UIEdgeInsets(top: 0, left: insets.left, bottom: 0, right: insets.right),
        fillColor: appBackgroundColor
    )
}
```

The callback runs only for a host with no parent that is directly presented by a UIKit view controller. A window root host and an embedded host are excluded. The app must decide whether a particular UIKit presentation needs framing; return `nil` for a partial presentation whose presentation controller already sizes its content.

As with content insets, the framing moves the root content's view itself, so content that ignores its safe area moves too, and the content's safe area no longer includes the inset. Nothing clips the root content to its inset frame, so content that draws beyond its own bounds stays visible in the inset area unless the framing has a fill color.

The callback runs on each content layout and uses the host's own safe area. Modal and toast containers retain the full host size, so a presentation above the framed root can dim the full width and use its own style. To apply a change to the callback's result, mark the host view for layout.

## Layout changes at runtime

While `presentationStyleTransform` is set, modal presentation controllers lay out again when the horizontal safe area changes, including changes in an ancestor presentation view. Without a transform, and for changes to top and bottom insets alone, presentations lay out again only when their size changes, as before.

If state read by an installed style changes without a size or safe-area change, call `setNeedsPresentationLayout()` on each affected modal presentation controller. This recomputes layout with the current transformed style; it does not resolve or transform styles again.

App-specific style classification, safe-area policy, colors, and runtime switches belong in the app's wrappers. Modals supplies the layout hooks without imposing those choices.
