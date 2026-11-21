# Assets

All bitmaps are **Google Noto Emoji** artwork, downloaded on 2026-11-19 from Google's Noto Emoji
Animation CDN (the static 512 px frame of each emoji), then resized to 128 px with `sips -Z 128`.

- Source URL pattern: `https://fonts.gstatic.com/s/e/notoemoji/latest/<codepoint>/512.png`
- Project page: https://googlefonts.github.io/noto-emoji-animation/
- License: **CC BY 4.0** (Noto Animated Emoji). The same artwork in the
  [noto-emoji repo](https://github.com/googlefonts/noto-emoji) is Apache 2.0.
  Attribution: "Noto Emoji by Google, CC BY 4.0".
- ⚠️ Before the public hackathon repo goes out, re-check the license text on the project page and
  keep this attribution in the final README.

| File (`app/Sources/Wailo/Resources/`) | Emoji | Codepoint | Source URL |
|---|---|---|---|
| ghost.png | 👻 | 1f47b | https://fonts.gstatic.com/s/e/notoemoji/latest/1f47b/512.png |
| pumpkin.png | 🎃 | 1f383 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f383/512.png |
| bat.png | 🦇 | 1f987 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f987/512.png |
| spider.png | 🕷️ | 1f577 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f577/512.png |
| web.png | 🕸️ | 1f578 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f578/512.png |
| candle.png | 🕯️ | 1f56f | https://fonts.gstatic.com/s/e/notoemoji/latest/1f56f/512.png |
| crystalBall.png | 🔮 | 1f52e | https://fonts.gstatic.com/s/e/notoemoji/latest/1f52e/512.png |
| tombstone.png | 🪦 | 1faa6 | https://fonts.gstatic.com/s/e/notoemoji/latest/1faa6/512.png |
| candy.png | 🍬 | 1f36c | https://fonts.gstatic.com/s/e/notoemoji/latest/1f36c/512.png |
| lollipop.png | 🍭 | 1f36d | https://fonts.gstatic.com/s/e/notoemoji/latest/1f36d/512.png |
| leaf.png | 🍂 | 1f342 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f342/512.png |
| mapleLeaf.png | 🍁 | 1f341 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f341/512.png |
| envelope.png | ✉️ | 2709 | https://fonts.gstatic.com/s/e/notoemoji/latest/2709/512.png |
| handUp.png | 👆 | 1f446 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f446/512.png |
| pointRight.png | 👉 | 1f449 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f449/512.png |
| pointLeft.png | 👈 | 1f448 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f448/512.png |
| ear.png | 👂 | 1f442 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f442/512.png |
| book.png | 📖 | 1f4d6 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f4d6/512.png |
| sparkles.png | ✨ | 2728 | https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.png |
| zzz.png | 💤 | 1f4a4 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a4/512.png |
| warning.png | ⚠️ | 26a0 | https://fonts.gstatic.com/s/e/notoemoji/latest/26a0/512.png |
| lantern.png | 🏮 | 1f3ee | https://fonts.gstatic.com/s/e/notoemoji/latest/1f3ee/512.png |

## Drawn in code (no asset, no license needed)

Night-sky gradient, stars, moon, clouds, hills, bare trees, tombstones on the hills, cobwebs,
slime drips, fog, vignette, footprints, pumpkin ring, spider thread, candles and flames, cauldron,
planchette, frost and ice crystals, and **the ghost pet itself** (procedural, so it can blink,
yawn, giggle and puff up).

## Fallback

If any PNG is missing, `AssetLoader` renders the same **system emoji** into an `NSImage`, so nothing
is ever blank. Sounds use **macOS system sounds** (`NSSound(named:)`), are off by default, and no
audio files are bundled.
