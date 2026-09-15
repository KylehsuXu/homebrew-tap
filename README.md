# KylehsuXu/homebrew-tap

```sh
brew install --cask KylehsuXu/tap/noswoosh-pro
```

`noswoosh-pro` is a fork of [mmathys/noswoosh](https://github.com/mmathys/noswoosh) that
also makes **switching to an app on another space** (Cmd+Tab, a Dock icon click, any
`open -b` hotkey) instant, instead of playing the space-slide animation.

Source: <https://github.com/KylehsuXu/noswoosh> · Releases:
<https://github.com/KylehsuXu/noswoosh/releases/latest>

> Don't run this alongside the upstream `noswoosh` cask: both daemons answer the same app
> activation and would each post a switch, which shows up as an overshoot (and the macOS
> blank-screen edge case). Uninstall one before installing the other.
