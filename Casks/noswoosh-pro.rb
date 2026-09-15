cask "noswoosh-pro" do
  version "1.8.0"
  sha256 "3c9a9c53b5706b3887cc674e24d2555cfe9f8f3cbeeee620dac0642ed841ab51"

  url "https://github.com/KylehsuXu/noswoosh/releases/download/v#{version}/noswoosh-pro-#{version}.app.zip"
  name "noswoosh-pro"
  desc "Instant space switching with Ctrl+arrow keys and for app switches, minus the swoosh"
  homepage "https://github.com/KylehsuXu/noswoosh"

  depends_on macos: :monterey

  app "noswoosh-pro.app"
  binary "#{appdir}/noswoosh-pro.app/Contents/MacOS/noswoosh-pro"

  postflight do
    exe = "#{appdir}/noswoosh-pro.app/Contents/MacOS/noswoosh-pro"
    system_command exe, args: ["setup"]

    plist = File.expand_path("~/Library/LaunchAgents/xu.max.noswoosh-pro.plist")
    File.write(plist, <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>xu.max.noswoosh-pro</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{exe}</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
          <key>ProcessType</key>
          <string>Interactive</string>
          <key>LimitLoadToSessionType</key>
          <string>Aqua</string>
          <key>StandardErrorPath</key>
          <string>#{File.expand_path("~/Library/Logs/noswoosh-pro.log")}</string>
      </dict>
      </plist>
    XML

    system_command "/bin/launchctl", args:         ["bootout", "gui/#{Process.uid}/xu.max.noswoosh-pro"],
                                     must_succeed: false
    system_command "/bin/launchctl", args:         ["bootstrap", "gui/#{Process.uid}", plist],
                                     must_succeed: false
  end

  uninstall_preflight do
    system_command "/bin/launchctl", args:         ["bootout", "gui/#{Process.uid}/xu.max.noswoosh-pro"],
                                     must_succeed: false
    system_command "#{appdir}/noswoosh-pro.app/Contents/MacOS/noswoosh-pro", args:         ["teardown"],
                                                                     must_succeed: false
    # postflight writes this, so uninstall must remove it: zap only runs with
    # --zap, and a stale plist points launchd at a binary that no longer exists.
    FileUtils.rm(File.expand_path("~/Library/LaunchAgents/xu.max.noswoosh-pro.plist"), force: true)
  end

  zap trash: [
    "~/Library/LaunchAgents/xu.max.noswoosh-pro.plist",
    "~/Library/Logs/noswoosh-pro.log",
  ]

  caveats <<~EOS
    One manual step remains: grant Accessibility permission (macOS prompts on
    first start), or add it yourself:

      System Settings > Privacy & Security > Accessibility > "+" and select
      #{appdir}/noswoosh-pro.app

    The daemon picks the grant up on its own within a second. Ctrl+Left /
    Ctrl+Right then switch spaces instantly, and so does switching to an app
    that lives on another space (Cmd+Tab, Dock icon, open -b hotkeys).

    Releases here are ad-hoc signed (no Developer ID yet), so the Accessibility
    grant does not survive an upgrade: after each "brew upgrade --cask
    noswoosh-pro" you have to tick it again.

    Don't install this next to the upstream noswoosh cask — both daemons would
    answer the same app activation and double-post the switch.
  EOS
end
