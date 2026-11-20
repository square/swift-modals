# Keep modal content out of part of its presentation

A full-screen presentation can keep its frame, overlay, and transition geometry while placing its content inside part of that frame, for example to keep the content out of an area covered by system UI. These display values are optional. With zero content insets, existing presentation layout and view hierarchies are unchanged.

## Content insets and fill

Set the insets and an optional fill color in the style's display values:

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

## Layout changes at runtime

Modal presentation controllers lay out again when the left or right safe area changes, including changes in an ancestor presentation view. Any style can read `containerSafeAreaInsets`, and a vertical system bar can move from one side to the other without changing the presentation's size. A view whose left and right insets stay at zero never lays out again because of the safe area. Changes to top and bottom insets alone lay out again only when the size changes, as before.

A modal update lays out each presentation that is already showing with its newly resolved style on the next layout pass, even when the size doesn't change. A style resolved for the environment, such as one that returns colors resolved for the current appearance, applies its new display values once the screen renders again. A presentation that is being dismissed interactively waits until it settles back, and one that is exiting keeps its exit animation.

Which modals to inset, by how much, and with what fill color are decisions for the app's styles. Modals supplies the layout without imposing those choices.
