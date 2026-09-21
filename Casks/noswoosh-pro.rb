cask "noswoosh-pro" do
  version "1.8.9"
  sha256 "38ef51c77640e0bd848a897604108ae53b1ea2e771b3e724962825f89ef40ac8"

  url "https://github.com/KylehsuXu/noswoosh-pro/releases/download/v#{version}/noswoosh-pro-#{version}.app.zip"
  name "noswoosh-pro"
  desc "Instant space switching with Ctrl+arrow keys and for app switches, minus the swoosh"
  homepage "https://github.com/KylehsuXu/noswoosh-pro"

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

  # Homebrew 7 wants the *_steps form. `teardown` re-enables the system Ctrl+arrow shortcuts, and
  # the plist has to go or launchd keeps pointing at a binary that is no longer there — so both
  # commands are load-bearing, not decoration. The binary path is resolved out here: inside a
  # *_steps block `self` is Homebrew's InstallSteps::DSL, where `appdir` does not exist (a
  # {{appdir}} placeholder is only substituted in the install artifacts, not in these steps).
  uninstall_binary = "#{appdir}/noswoosh-pro.app/Contents/MacOS/noswoosh-pro"
  uninstall_preflight_steps do
    run "/bin/launchctl", args: ["bootout", "gui/#{Process.uid}/xu.max.noswoosh-pro"], must_succeed: false
    run uninstall_binary, args: ["teardown"], must_succeed: false
    remove "Library/LaunchAgents/xu.max.noswoosh-pro.plist", base: :home
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

    Upgrading: "brew upgrade --cask noswoosh-pro" runs this cask's uninstall hook, which removes
    the login daemon — run `noswoosh-pro setup` again afterwards. The Accessibility / Device
    Control grants do survive: releases are signed with a stable certificate.

    Don't install this next to the upstream noswoosh cask — both daemons would answer the
    same app activation and double-post the switch.
  EOS
end
