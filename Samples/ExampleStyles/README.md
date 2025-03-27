# Example Styles

These styles demonstrate some common use cases and features.

## Full Modal

This is a simple full screen modal.

## Card Modal

This modal is sized to fit its content, and centered in its container.

## Popover Modal

This style demonstrates how to "anchor" a modal relative to some content. The `UICoordinateSpace` is passed into the style, and used to resolve a frame relative to the container. You can tap on the overlay outside the popover's bounds to dismiss it.

## Sheet Modal

This style supports interactive dismissal by swiping, using the `reverseTransitionValues` API. You can also tap on the overlay to dismiss.

## Styling

Each of these modals uses style values from a `ModalStylesheet`. You don't pass it in explicitly; the stylesheet lives on the `ViewEnvironment`, and is resolved at presentation time. Look at `ModalPresentationStyleProvider+Examples.swift` to see how static factory methods are created for each of these preset modal styles.
