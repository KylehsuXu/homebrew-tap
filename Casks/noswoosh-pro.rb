cask "noswoosh-pro" do
  version "1.8.5"
  sha256 "26c274182a5c861f241842f7a4e5e67185fff92976048e07c2491007a216362e"

  url "https://github.com/KylehsuXu/noswoosh/releases/download/v#{version}/noswoosh-pro-#{version}.app.zip"
  name "noswoosh-pro"
  desc "Instant space switching with Ctrl+arrow keys and for app switches, minus the swoosh"
  homepage "https://github.com/KylehsuXu/noswoosh"

  depends_on macos: :monterey

  app "noswoosh-pro.app"
  binary "#{appdir}/noswoosh-pro.app/Contents/MacOS/noswoosh-pro"

  # Homebrew 7 runs cask install steps inside a sandbox that kills anything touching
  # WindowServer or cfprefsd: the `setup` call that used to live here died with SIGKILL
  # (silently, behind must_succeed), leaving the system Ctrl+arrow hotkeys enabled. So the
  # cask only installs the app; the one-time system work and the login daemon are installed
  # by `noswoosh-pro setup` — see caveats. Only quarantine removal is safe here.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "{{appdir}}/noswoosh-pro.app"],
                            must_succeed: false
  end

  uninstall_preflight do
    system_command "/bin/launchctl", args:         ["bootout", "gui/#{Process.uid}/xu.max.noswoosh-pro"],
                                     must_succeed: false
    system_command "#{appdir}/noswoosh-pro.app/Contents/MacOS/noswoosh-pro", args:         ["teardown"],
                                                                     must_succeed: false
    # setup writes this, so uninstall must remove it: zap only runs with --zap, and a stale
    # plist points launchd at a binary that no longer exists.
    FileUtils.rm(File.expand_path("~/Library/LaunchAgents/xu.max.noswoosh-pro.plist"), force: true)
  end

  zap trash: [
    "~/Library/LaunchAgents/xu.max.noswoosh-pro.plist",
    "~/Library/Logs/noswoosh-pro.log",
  ]

  caveats <<~EOS
    Finish the install by running this once:

      noswoosh-pro setup

    It disables the system's animated Ctrl+arrow shortcuts and installs + starts the login
    daemon. (Homebrew sandboxes cask install steps, so the cask cannot do either itself.)

    Then grant Accessibility permission — macOS prompts on first start, or add it yourself:

      System Settings > Privacy & Security > Accessibility > "+" and select
      #{appdir}/noswoosh-pro.app

    The daemon picks the grant up on its own within a second. Ctrl+Left / Ctrl+Right then
    switch spaces instantly, and so does switching to an app that lives on another space
    (Cmd+Tab, Dock icon, open -b hotkeys).

    Releases here are ad-hoc signed (no Developer ID yet), so the Accessibility grant does
    not survive an upgrade: after each "brew upgrade --cask noswoosh-pro" tick it again.

After "brew upgrade --cask noswoosh-pro" the login daemon is gone: Homebrew's upgrade
    runs this cask's uninstall hook, which removes the LaunchAgent. Run `noswoosh-pro setup`
    again to put it back. The Accessibility / Device Control grants do survive upgrades —
    releases are signed with a stable certificate, unlike the earlier ad-hoc builds.

    Don't install this next to the upstream noswoosh cask — both daemons would answer the
    same app activation and double-post the switch.
  EOS
end
