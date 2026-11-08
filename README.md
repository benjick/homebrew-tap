# benjick/homebrew-tap

Homebrew casks for my macOS apps.

```sh
brew install --cask benjick/tap/pullrequests
```

| Cask | App |
|---|---|
| `pullrequests` | [PullRequests](https://github.com/benjick/pullrequests): menu bar app for monitoring GitHub pull requests |
| `chime` | [Chime](https://github.com/benjick/chime): soft creature voices for Claude Code |

The apps are ad-hoc signed, not notarised. Each cask removes the quarantine
flag after install so macOS doesn't block the first launch. Downloading a zip
from a release page directly will hit the usual Gatekeeper warning; install
through Homebrew instead.

## Releasing

Each app repo has a small workflow that calls
[`release-macos-app.yml`](.github/workflows/release-macos-app.yml) here. Pushing
a `v*` tag in the app repo builds the app, ad-hoc signs it, publishes a GitHub
release with the zip, and commits the new version and checksum to the cask.

```sh
git tag v1.2.0 && git push origin v1.2.0
```

Caller workflow (`.github/workflows/release.yml` in the app repo):

```yaml
name: Release
on:
  push:
    tags: ["v*"]
permissions:
  contents: write
jobs:
  release:
    uses: benjick/homebrew-tap/.github/workflows/release-macos-app.yml@main
    with:
      app-name: PullRequests
      cask: pullrequests
    secrets:
      TAP_TOKEN: ${{ secrets.TAP_TOKEN }}
```

`TAP_TOKEN` is a fine-grained personal access token with **Contents: Read and
write** on this repository only, stored as an Actions secret in each app repo.

### Adding an app

See [ADDING-AN-APP.md](ADDING-AN-APP.md) for the full checklist. It's written so
a coding agent in the app's repo can follow it.
