cask "chime" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/benjick/chime/releases/download/v#{version}/Chime-#{version}.zip"
  name "Chime"
  desc "Soft creature voices for Claude Code"
  homepage "https://github.com/benjick/chime"

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Chime.app"

  # The app is ad-hoc signed, not notarised. Drop the quarantine flag so
  # Gatekeeper doesn't block it on first launch.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Chime.app"]
  end

  uninstall quit: "me.malm.chime"

  zap trash: [
    "~/Library/Application Support/Chime",
    "~/Library/Preferences/me.malm.chime.plist",
  ]

  caveats <<~EOS
    Launch Chime and click "Install hook" to add its sounds to Claude Code.

    Before uninstalling, choose "Uninstall Chime…" from its menu-bar menu.
    That removes its hooks from ~/.claude/settings.json, which brew can't do.
  EOS
end
