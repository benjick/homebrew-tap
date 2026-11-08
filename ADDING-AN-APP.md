# Adding an app to this tap

Instructions for adding a macOS app to `benjick/homebrew-tap` so it can be
installed with `brew install --cask benjick/tap/<cask>` and released by pushing
a git tag. Written to be followed by a person or a coding agent working in the
app's repository.

## How it works

- This tap holds only cask files (`Casks/<cask>.rb`) and one shared workflow,
  [`release-macos-app.yml`](.github/workflows/release-macos-app.yml). No
  binaries are committed here.
- Each app repo has a small `release.yml` that calls the shared workflow when a
  `v*` tag is pushed. The shared workflow builds the app on a GitHub macOS
  runner, writes the version from the tag into `Info.plist`, ad-hoc signs it,
  zips it, creates a GitHub release in the app repo with the zip attached, and
  commits the new `version` and `sha256` to the app's cask in this tap.
- The apps are ad-hoc signed, not notarised. Each cask removes the quarantine
  flag after install so Gatekeeper doesn't block the first launch.

## Readiness checklist

Go through this before the first release. Items marked **(required)** break
the build or the install if missed; the rest are about shipping something
people can actually use.

### Repository

- [ ] **(required)** The repo is public. Homebrew downloads the release zip
      without authentication.
- [ ] `LICENSE` file at the root (MIT unless the owner says otherwise), and
      the license named in the README.
- [ ] The git history contains nothing that shouldn't be public: tokens, keys,
      personal data, large binaries, abandoned prototypes. Pushing publishes
      every commit, not just the current tree. Check with
      `git log --diff-filter=D --name-only` and `git log -p | grep -iE "token|secret|password|api.?key"`.
      If in doubt, ask the owner whether to squash before the first push.
- [ ] `.gitignore` covers `.build/`, `build/`, `.swiftpm/`, `.DS_Store` and
      `DerivedData/`.
- [ ] **(required)** `CHANGELOG.md` at the root with a `## <version>` section
      for the version being released (`## 1.2.3 - 2026-11-08` works). The
      workflow uses that section as the GitHub release notes and fails before
      building if it's missing. Path can be changed with the `changelog` input.

### README

- [ ] One or two sentences on what the app does, and a screenshot.
- [ ] Install instructions using brew, as the first install option:
      `brew install --cask benjick/tap/<cask>`.
- [ ] A note that it's ad-hoc signed, so downloading the zip from the release
      page directly gets a Gatekeeper warning; install via brew instead.
- [ ] Minimum macOS version and Apple Silicon only.
- [ ] First-run setup (tokens, permissions, settings to configure).
- [ ] How to uninstall, including anything the app set up outside its bundle.
- [ ] Building from source.

### Store listing (malm.me/apps)

[benjick/malm.me](https://github.com/benjick/malm.me) reads these from the
app's default branch when it builds, and lists the repo in its
`content/apps.json`. Changes show up on its next deploy.

- [ ] `docs/store.md`: frontmatter with `name`, `tagline` and `cask`
      (required), plus `category`, `minimumMacOS`, `menuBar`, `bundleId`, and
      `headline` and `color` for the featured card. The markdown body is the
      store description. Copy `benjick/pullrequests`'s and adjust it.
- [ ] `docs/icon.png`: the app icon at 512 px, written by the icon generator
      next to `AppIcon.icns` so the two never drift apart.
- [ ] `docs/screenshots/*.png`: shown in filename order (prefix `01-`, `02-`
      to control it); the alt text comes from the filename.

### Icon and bundle

- [ ] An `AppIcon.icns` with all standard sizes (16 to 512@2x) is copied into
      `Contents/Resources/`, and `Info.plist` has `CFBundleIconFile` pointing
      at it. Check it in Finder and the Dock, not just the source file.
- [ ] The icon source is reproducible (a generator script or an SVG in the
      repo), so it can be tweaked later.
- [ ] If the app has a menu bar icon, it's a template image so it adapts to
      light and dark menu bars.
- [ ] `CFBundleIdentifier` is final. Changing it later loses users'
      preferences and notification permissions.
- [ ] `CFBundleName` and `CFBundleDisplayName` are the name users should see.
- [ ] `LSUIElement` is `true` for menu-bar-only apps.
- [ ] `LSMinimumSystemVersion` matches the `Package.swift` platform.
- [ ] **(required)** `Info.plist` contains `CFBundleShortVersionString` and
      `CFBundleVersion`. The workflow sets them with `PlistBuddy Set`, which
      fails if a key is missing. Their current values don't matter.

### Build

- [ ] **(required)** Builds a `.app` from the command line with no Xcode GUI
      steps. Default: `bash scripts/build-app.sh` producing
      `.build/release/<AppName>.app`. Other commands and paths can be passed
      as workflow inputs (see step 1).
- [ ] **(required)** Builds on GitHub's macOS runner. `swift build` there
      produces arm64 only, so casks declare `depends_on arch: :arm64`. Apps
      targeting macOS 26 need a runner with Xcode 26 (`runs-on` input).
- [ ] Release build has no warnings worth worrying about.

### App behaviour

These have bitten earlier apps in this tap.

- [ ] Launches cleanly at login before the network is up. Anything that
      fetches data at startup must retry on failure, not give up after the
      first error. Test: turn Wi-Fi off, launch, turn Wi-Fi on.
- [ ] Settings window tabs render properly on macOS 26. A SwiftUI `TabView`
      inside a hand-made `NSWindow` collapses into a `>>` overflow menu; use a
      toolbar-style `NSTabViewController` hosting the SwiftUI views (see
      `benjick/pullrequests`, `MenuBar/SettingsWindowController.swift`).
- [ ] Nothing depends on a stable code signature. Ad-hoc signatures change
      with every build, so Keychain items, Accessibility, Screen Recording and
      Input Monitoring grants can reset on upgrade. Prefer files in
      `~/.config/<app>` or `~/Library/Application Support/<app>` over the
      Keychain.
- [ ] Quits cleanly when asked (`osascript -e 'quit app id "<bundle-id>"'`),
      since brew quits it before upgrading.
- [ ] Errors the user can act on are shown in the UI, and the app logs through
      `os.Logger` with its bundle ID as the subsystem, so problems can be
      debugged with `log show --predicate 'subsystem == "<bundle-id>"'`.
- [ ] Shows its version somewhere (About window or Settings), so users can
      report which release they're on.
- [ ] "Launch at login" works when the app runs from `/Applications`.

## Steps

### 1. Add the caller workflow to the app repo

`.github/workflows/release.yml`:

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
      app-name: PullRequests   # bundle name without .app
      cask: pullrequests       # file name in Casks/, without .rb
    secrets:
      TAP_TOKEN: ${{ secrets.TAP_TOKEN }}
```

Optional inputs:

| Input | Default | When to change |
|---|---|---|
| `build-command` | `bash scripts/build-app.sh` | The app builds with a different script, e.g. `sh scripts/app.sh` |
| `app-path` | `.build/release/<app-name>.app` | The script puts the bundle elsewhere, e.g. `build/Chime.app` |
| `changelog` | `CHANGELOG.md` | The changelog lives elsewhere |
| `runs-on` | `macos-15` | The app needs a newer SDK, e.g. `LSMinimumSystemVersion` 26 needs a macOS 26 runner with Xcode 26 |

### 2. Add the cask to this tap

Copy `Casks/pullrequests.rb` to `Casks/<cask>.rb` and adjust it. Leave
`version "0.0.0"` and the all-zero `sha256`; the first release overwrites them.
The workflow edits those two lines with `sed`, so keep their format exactly:
two-space indent, double quotes.

Things to get right:

- `url` must match the zip the workflow uploads:
  `https://github.com/benjick/<repo>/releases/download/v#{version}/<AppName>-#{version}.zip`
- `depends_on macos:` should match the app's `LSMinimumSystemVersion`
  (`:sonoma` = 14, `:sequoia` = 15, `:tahoe` = 26).
- `postflight_steps` with the `xattr` quarantine removal. Use
  `postflight_steps`, not a legacy `postflight do` block, which `brew style`
  rejects.
- `uninstall quit:` with the app's `CFBundleIdentifier`, so upgrades quit the
  running app before replacing it.
- `zap trash:` listing the app's preferences plist
  (`~/Library/Preferences/<bundle-id>.plist`) and any config, cache or
  Application Support folders the app writes to. Look at the code to find them.
- If the bundle ships a command-line tool, expose it with
  `binary "#{appdir}/<AppName>.app/Contents/MacOS/<tool>"`.
- If uninstalling should undo something the app set up outside its bundle
  (hooks, launch agents, files in other apps' config), say so in `caveats`.
  Brew can't undo it.

Lint it:

```sh
brew style --fix Casks/<cask>.rb
```

Add a row to the table in `README.md`, then commit and push the tap.

### 3. Give the app repo the tap token

The workflow pushes to this tap with a fine-grained personal access token that
has **Contents: Read and write** on `benjick/homebrew-tap` only. The same token
is used by every app repo; personal accounts have no account-wide Actions
secrets, so each repo needs its own copy.

The repo owner has to do this in a real terminal, because `gh secret set`
prompts for the value:

```sh
gh secret set TAP_TOKEN -R benjick/<repo>
```

Agents: don't run this through a non-interactive shell. It can save an empty
secret without prompting. Ask the owner to run it.

### 4. (Optional) Test the cask locally before releasing

Homebrew only installs casks from a tap, so use a throwaway local one. Build
the zip the same way the workflow does, point a copy of the cask at it with a
`file://` URL and its real `sha256`, and install into a scratch folder:

```sh
brew tap-new --no-git benjick/test
cp <edited-cask>.rb "$(brew --repository benjick/test)/Casks/"
brew install --cask --appdir=/tmp/apps benjick/test/<cask>
xattr -l /tmp/apps/<AppName>.app      # should show no com.apple.quarantine
brew uninstall --cask benjick/test/<cask> && brew untap benjick/test
```

Note: `brew uninstall` runs the cask's `uninstall quit:`, which also quits any
running copy of the app with the same bundle ID.

### 5. Release

First add a section for the new version at the top of `CHANGELOG.md` and
commit it. Then tag. Tags must be annotated; the owner's git config refuses
lightweight tags with "no tag message?":

```sh
git tag -a v1.0.0 -m "<AppName> 1.0.0"
git push origin v1.0.0
gh run watch -R benjick/<repo>     # takes ~1 minute
```

The workflow checks out this tap first, so a missing or bad `TAP_TOKEN` fails
before anything is published. If a run fails after the release was created,
delete the release and the tag before retrying:

```sh
gh release delete v1.0.0 -R benjick/<repo> --cleanup-tag --yes
```

### 6. Install

```sh
brew install --cask benjick/tap/<cask>
```

If the app is already in `/Applications` from a local build, brew refuses to
overwrite it. Quit the app and add `--force` the first time.
