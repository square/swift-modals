# Releasing a new version

1. Make sure you're on the `main` branch, and `git pull` to get the latest commits.

1. Create a branch off `main`.

1. Update `CHANGELOG.md` (in the root of the repo), moving current changes under `Main` to a new section for the version you are releasing.

   The changelog uses [reference links](https://daringfireball.net/projects/markdown/syntax#link) to link each version's changes. Remember to add a link to the new version at the bottom of the file, and to update the link to `[main]`.

1. Push your branch and open a PR into `main`.

1. Once merged, go to [Releases](https://github.com/square/swift-modals/releases) and `Draft a new release`.

1. `Choose a tag` and create a tag targeting the **signed merge commit** on `main`.

1. In the release notes, copy the changes from the changelog.

1. Ensure the `Title` corresponds to the version being published.

1. Hit `Publish release`.
