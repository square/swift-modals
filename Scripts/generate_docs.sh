#!/usr/bin/env bash

BUILD_PATH=docs_build
MERGED_PATH=generated_docs

xcodebuild docbuild \
    -scheme Documentation \
    -derivedDataPath "$BUILD_PATH" \
    -workspace Samples/ModalsDevelopment.xcworkspace \
    -destination generic/platform=iOS \
    DOCC_HOSTING_BASE_PATH='swift-modals' \
    | xcpretty

find_archive() {
    find "$BUILD_PATH" -type d -name "$1.doccarchive" -print -quit
}

xcrun docc merge \
    $(find_archive Modals) \
    $(find_archive WorkflowModals) \
    --output-path "$MERGED_PATH" \
    --synthesized-landing-page-name "swift-modals"
