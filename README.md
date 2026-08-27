# haanasewing.com

The HaanaSewing site. Static, no build step, no dependencies — GitHub Pages
serves this repo as-is.

| | |
|---|---|
| **Live** | https://haanasewing.com |
| **Host** | GitHub Pages, `main` branch, root |
| **Domain** | Registered + DNS at Cloudflare |
| **Editing source** | `~/sadeeq-vault/haanasewing/` (see below) |

## Layout

```
index.html              the site
404.html                branded not-found page
assets/photos/*.jpg     the 10 portfolio photographs
assets/video/*.mp4      the 4 hero reel clips
assets/og-card.jpg      1200x630 link-preview card
favicon.ico / -32 / -512 / apple-touch-icon.png
CNAME                   haanasewing.com  — do not delete, Pages needs it
.nojekyll               skip Jekyll processing
robots.txt · sitemap.xml
```

## ⛔ This is NOT the same file as the artifact

The artifact version (`~/sadeeq-vault/haanasewing/index.html`, 8.5 MB) has every
photo and video inlined as base64, because the artifact CSP blocks external
hosts. **This repo's `index.html` is 50 KB** — the same 14 assets, pulled out to
real files. The assets are byte-identical; only the `src` attributes differ.

Anything else you change has to be changed in **both** places, or they drift —
which is exactly what happened to the old vault standalone copy. To re-derive
this repo from the artifact version after an edit there, the extraction is:
match each `data:` URI's md5 against `_photos/` and `_video/`, replace with the
relative path, then assert `base64,` no longer appears.

## Differences from the artifact version, on purpose

- Assets are external files (above). The page went from 8.5 MB to 50 KB, so it
  paints immediately instead of after the whole blob downloads.
- `<head>` is closed and `<body>` opened — the artifact wrapper used to supply
  those, so the standalone file had neither.
- Gallery images carry `loading="lazy"`.
  ⚠️ **Do not add `decoding="async"`** — it defers the decode and the gallery
  paints blank in headless screenshots. Verified 2026-08-26.
- Added: canonical URL, Open Graph + Twitter card, favicons, `theme-color`,
  and `ClothingStore` JSON-LD. All absolute URLs in those point at
  `https://haanasewing.com/` — **update them if the domain ever changes.**

## Traps carried over from the vault README

1. **`.draft` and `.buildnote` are `display:none`.** The amber "Draft" banner and
   the whole "Note for Haana" section are in the HTML but never render.
2. **Changing the palette means editing `:root` twice.** The couture block near
   the bottom of the stylesheet redefines `:root` and hardcodes ~14 more
   literals. Recolour from the olive original in `~/sadeeq-vault/haanasewing/_source/`
   as a whole-file literal map, then grep for the old hex set — zero hits.
3. **The hero reel is fragile.** `muted` + `playsinline` are load-bearing, and
   the 3900 ms start delay is hand-matched to the intro curtain with nothing
   enforcing the pairing.

## Launch gates

- ✅ **Photo rights — cleared 2026-08-26.** All ten portfolio photos and the four
  hero clips are cleared for use.
- ✅ **Service area — Tampa, Florida, set 2026-08-26.** In the hero eyebrow, the
  three meta descriptions, the footer, the social card, the FAQ, and — the part
  that actually matters for local search — the JSON-LD, as a `PostalAddress`
  with `addressLocality: Tampa` / `addressRegion: FL` plus `areaServed` of
  Tampa and Tampa Bay Area. No street address or geo coordinates: still unknown,
  deliberately not guessed at.
- ❌ **Prices — still open, and publicly quoted right now.** Every figure in the
  services section is a market benchmark standing in for Haana's real numbers.
- ⚠️ **Does she travel to a bride?** Unanswered, so the FAQ question was narrowed
  to "Where are you based?" and commits only to Tampa and by-appointment
  fittings. Don't invent a travel policy — it's in the build note as an open
  question.
