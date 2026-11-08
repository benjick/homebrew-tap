cask "pullrequests" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/benjick/pullrequests/releases/download/v#{version}/PullRequests-#{version}.zip"
  name "PullRequests"
  desc "Menu bar app for monitoring GitHub pull requests"
  homepage "https://github.com/benjick/pullrequests"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "PullRequests.app"

  # The app is ad-hoc signed, not notarised. Drop the quarantine flag so
  # Gatekeeper doesn't block it on first launch.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/PullRequests.app"]
  end

  uninstall quit: "com.pullrequests.app"

  zap trash: [
    "~/.config/pullrequests",
    "~/Library/Preferences/com.pullrequests.app.plist",
  ]

  caveats <<~EOS
    Launch PullRequests, then add a GitHub token and repositories in Settings.
  EOS
end
