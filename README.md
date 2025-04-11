# Modals

[![Validations](https://github.com/square/swift-modals/actions/workflows/validations.yaml/badge.svg)](https://github.com/square/swift-modals/actions/workflows/validations.yaml)

A framework for presenting modal content deterministically in an iOS application.

Modals supports both true modals as well as similar content overlay presentations which are not technically modal in nature, such as toasts.

## Design

The Modals framework is designed to solve a couple of problems in large scale applications.

- Determinism. Modal lifetime is explicitly managed, and modal ordering is based on the shape of the view controller hierarchy. Unlike vanilla UIKit, there can be no surprises about what is top-most or what will be removed when calling `dismiss`.

- A declarative model. Modals works well with Workflow, to represent all currently visible modals in a declarative way, and could be adapted to other declarative interfaces as well.

Modals presents from a _modal host_ view controller installed near the root of your application. The modal host traverses the view controller hierarchy to aggregate a list of modals that need to be displayed. Each descendent view controller may present modals, and those presented modals may also present modals. When multiple modals are present at once, the shape of the view hierarchy will determine the ordering. To dismiss a modal, it should simply be removed from the presenting view controller, and the next time the host aggregates modals, it will be dismissed.

The modal host presents using view controller containment from the modal host view controller.

## Getting Started

### Swift Package Manager

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager)

If you are developing your own package, be sure that Modals is included in `dependencies`
in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/square/swift-modals", from: "1.0.0")
]
```

In Xcode 11+, add Workflow directly as a dependency to your project with
`File` > `Swift Packages` > `Add Package Dependency...`. Provide the git URL when prompted: `git@github.com:square/swift-modals.git`.

## Documentation

- Usage from [vanilla UIKit](Documentation/uikit-usage.md)
- Usage from [Workflow](Documentation/workflow-usage.md)
- [General usage tips](Documentation/tips.md)
- API docs (TODO)

Some sample code is available in the [Samples](Samples) directory. To build the sample code, use the local development instructions below.

## Local Development

This project uses [Mise](https://mise.jdx.dev/) and [Tuist](https://tuist.io/) to generate a project for local development. Follow the steps below for the recommended setup for zsh.

```sh
# install mise
brew install mise
# add mise activation line to your zshrc
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# load mise into your shell
source ~/.zshrc
# tell mise to trust this repo's config file
mise trust
# install dependencies
mise install

# only necessary for first setup or after changing dependencies
tuist install --path Samples
# generates and opens the Xcode project
tuist generate --path Samples
```

## Credits

`swift-modals` was written by [@watt](https://github.com/watt) with help from [@kylebshr](https://github.com/kylebshr), [@robmaceachern](https://github.com/robmaceachern), [@kyleve](https://github.com/kyleve), [@n8chur](https://github.com/n8chur), [@nononoah](https://github.com/nononoah), and others. Thank you to all contributors!

## License

Copyright 2025 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
