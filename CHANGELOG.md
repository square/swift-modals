# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Main]

### Fixed

### Added

### Removed

### Changed

### Deprecated

### Security

### Documentation

### Misc

### Internal

## [2.0.1] - 2026-04-08

### Fixed

- Restore `accessibilityViewIsModal` after nested modal dismiss.

### Internal

- Pass `GITHUB_TOKEN` to mise-action to fix CI failures.

## [2.0.0] - 2026-02-26

### Changed

- **Breaking:** Use the [KeyboardObserver](https://github.com/nicklama/KeyboardObserver) package for keyboard observation.

## [1.1.0] - 2025-06-30

### Added

- Structured logging support.
- Updated Workflow dependency to 4.0.

### Fixed

- Coalesce VoiceOver screen changed notifications when presenting or dismissing multiple modals at once.

### Documentation

- Generate API docs.
- Miscellaneous documentation gardening.

## [1.0.0] - 2025-03-27

- Initial release.

[main]: https://github.com/square/swift-modals/compare/2.0.1...HEAD
[2.0.1]: https://github.com/square/swift-modals/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/square/swift-modals/compare/1.1.0...2.0.0
[1.1.0]: https://github.com/square/swift-modals/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/square/swift-modals/releases/tag/1.0.0
