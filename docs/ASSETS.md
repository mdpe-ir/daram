# Assets and licenses

DARAM does not load any image, icon or font from the network at runtime. Everything below is bundled inside the app.

## Typography — Vazirmatn

- **Source:** [github.com/rastikerdar/vazirmatn](https://github.com/rastikerdar/vazirmatn), release v33.003.
- **Files:** `assets/fonts/Vazirmatn-{Light,Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` (static weights, ~123 KB each).
- **License:** SIL Open Font License 1.1. Full text: `assets/fonts/OFL.txt`.
- **Usage:** the only UI font; weights map to 300/400/500/600/700/800 in `DaramTheme`. Numbers use tabular figures in amount widgets.

## Iranian bank and neobank logos

### CC0 bank logos (40)

- **Source:** [github.com/zegond/logos-per-banks](https://github.com/zegond/logos-per-banks), `SVG Assets/Bank/Color/*.svg`.
- **License:** CC0 1.0 Universal. Full text: `assets/banks/LICENSE.txt`.
- **Bundled files:**

| File | Institution |
|---|---|
| `melli.svg` | بانک ملی ایران |
| `sepah.svg` | بانک سپه |
| `maskan.svg` | بانک مسکن |
| `postbank.svg` | پست بانک ایران |
| `keshavarzi.svg` | بانک کشاورزی |
| `tosee_taavon.svg` | بانک توسعه تعاون |
| `sanat_madan.svg` | بانک صنعت و معدن |
| `tosee_saderat.svg` | بانک توسعه صادرات ایران |
| `mellat.svg` | بانک ملت |
| `saderat.svg` | بانک صادرات ایران |
| `tejarat.svg` | بانک تجارت |
| `refah.svg` | بانک رفاه کارگران |
| `parsian.svg` | بانک پارسیان |
| `pasargad.svg` | بانک پاسارگاد |
| `saman.svg` | بانک سامان |
| `ayandeh.svg` | بانک آینده |
| `eghtesad_novin.svg` | بانک اقتصاد نوین |
| `shahr.svg` | بانک شهر |
| `sina.svg` | بانک سینا |
| `dey.svg` | بانک دی |
| `resalat.svg` | بانک قرض‌الحسنه رسالت |
| `gardeshgari.svg` | بانک گردشگری |
| `khavar_mianeh.svg` | بانک خاورمیانه |
| `iran_zamin.svg` | بانک ایران زمین |
| `karafarin.svg` | بانک کارآفرین |
| `sarmayeh.svg` | بانک سرمایه |
| `mehr_iran.svg` | بانک قرض‌الحسنه مهر ایران |
| `ansar.svg` | بانک انصار |
| `ghavamin.svg` | بانک قوامین |
| `hekmat.svg` | بانک حکمت ایرانیان |
| `mehr_eghresad.svg` | بانک مهر اقتصاد |
| `iran_venezuela.svg` | بانک مشترک ایران و ونزوئلا |
| `melall.svg` | مؤسسه اعتباری ملل |
| `caspian.svg` | مؤسسه اعتباری کاسپین |
| `noor.svg` | مؤسسه اعتباری نور |
| `kosar.svg` | مؤسسه اعتباری کوثر |
| `taavon_eslami.svg` | بانک تعاون اسلامی |
| `iran_europe.svg` | بانک ایران اروپا |
| `futurebank.svg` | بانک فیوچر (بحرین) |
| `markazi.svg` | بانک مرکزی ایران |

### BluBank logo

- **File:** `blue.svg` (`Blubank_light_logo.svg`, bundled unmodified).
- **Source:** [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Blubank_light_logo.svg).
- **Author:** blubank.
- **License:** [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- **Attribution:** see [`assets/banks/ATTRIBUTION.md`](../assets/banks/ATTRIBUTION.md).
- The logo is displayed only to identify the user's BluBank account. The mark
  remains a trademark of its owner; the CC license does not grant trademark
  rights. The asset is separate from the application's source code.

### Neobank marks

The catalog has 26 digital banks. Seven have an official standalone mark
bundled — **BluBank**, **Bankino**, **Banket**, **HiBank**, **OmidBank**,
**GreenBank** and **ForBix**. The remaining 19 use their parent bank's mark in
the picker (the subtitle shows the parent), because no standalone public asset
could be verified. There are no letter placeholders.

| Digital bank | Bundled mark | Source |
|---|---|---|
| بلوبانک | `blue.svg` | Wikimedia Commons, CC BY-SA 4.0 |
| بانکینو | `bankino.png` | Official Bankino app icon (Cafe Bazaar listing) |
| بانکت | `banket.png` | banket.app |
| های‌بانک | `hibank.png` | hibank.ir |
| امیدبانک | `omid.png` | omidbank.ir (wordmark) |
| گرین بانک | `greenbank.svg` | greenbank.ir |
| فوربیکس | `forbix.png` | forbix.ir |
| ویپاد | `pasargad.svg` | Parent: بانک پاسارگاد |
| دیما | `mellat.svg` | Parent: بانک ملت |
| کیوبانک | `mehr_iran.svg` | Parent: بانک قرض‌الحسنه مهر ایران |
| توبانک | `gardeshgari.svg` | Parent: بانک گردشگری |
| باران | `keshavarzi.svg` | Parent: بانک کشاورزی |
| بام | `melli.svg` | Parent: بانک ملی ایران |
| باجت | `tejarat.svg` | Parent: بانک تجارت |
| سپینو | `saderat.svg` | Parent: بانک صادرات ایران |
| متابانک | `melall.svg` | Parent: مؤسسه اعتباری ملل |
| بانکواره | `tosee_taavon.svg` | Parent: بانک توسعه تعاون |
| فرارفاه | `refah.svg` | Parent: بانک رفاه کارگران |
| فراز بانک | `iran_zamin.svg` | Parent: بانک ایران زمین |
| ردبانک | `shahr.svg` | Parent: بانک شهر |
| پارسیان من | `parsian.svg` | Parent: بانک پارسیان |
| تیم بانک | `sanat_madan.svg` | Parent: بانک صنعت و معدن |
| سرمایه دیجیتال | `sarmayeh.svg` | Parent: بانک سرمایه |
| جهش بانک | `iran_zamin.svg` | Parent: بانک ایران زمین |
| آبانک | `melli.svg` | Parent: بانک ملی ایران |
| نئون | `eghtesad_novin.svg` | Parent: بانک اقتصاد نوین |

The 47 unique files serve 66 catalog entries; some parent marks are intentionally
shared. The picker always displays the digital bank's name and its parent, so a
shared mark is not presented as a standalone logo. The official neobank marks
are trademarks of their owners and are used only to identify the user's own
account; they are not covered by the project's source license. See
[`assets/banks/ATTRIBUTION.md`](../assets/banks/ATTRIBUTION.md).

### Custom banks

Selecting «سایر بانک‌ها» lets the user type any bank or neobank name. The name
is stored on the account and the avatar derives its monogram from that name.
The AI can also propose a custom bank through `add_account`; unknown names are
preserved verbatim.

Logos are shown inside a neutral tile for contrast in both themes. Trademarks
remain the property of their owners. The catalog is based on public Iranian
banking/neobank lists and may lag regulatory mergers.

## Web runtime and PWA assets

| Asset | Source | License / notes |
|---|---|---|
| `web/sqlite3.wasm` | [sqlite3.dart 3.9.0](https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-3.9.0) | MIT (package) + SQLite public domain; must match the `sqlite3` dependency |
| `web/drift_worker.js` | compiled from `tool/drift_worker.dart` | drift MIT; regenerate with `dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js` |
| `web/index.html` | original DARAM boot screen | project identity; CanvasKit is bundled locally |
| `web/manifest.json` | original PWA manifest | project identity |
| `web/icons/Icon-*.png`, `web/favicon.png` | generated by `flutter_launcher_icons` | project identity |

These files are copied by `flutter build web` into `build/web/`. The worker and
WASM runtime are served from the origin, not a third-party CDN.

## Icons

- **Lucide** via `lucide_icons_flutter` 4.0.2 — ISC License.
- Category icon slugs stored in SQLite are mapped to Lucide icons in `lib/app/design_system/daram_widgets.dart`.

## DARAM brand assets (original)

| Asset | Where | Notes |
|---|---|---|
| DARAM mark | `lib/app/branding/daram_logo.dart` | Custom painter; works on light/dark, 24–104 px. |
| Launcher icon source | `assets/images/app_icon_1024.png` (+512) | Generated by `tool/generate_icon.py`; platform icons generated by `flutter_launcher_icons`. |
| Adaptive foreground | `assets/images/app_icon_foreground.png` | Mark inside the 60% safe zone. |
| Monochrome icon | `assets/images/app_icon_monochrome.png` | Android 13 themed icons. |
| Android launcher files | `android/app/src/main/res/mipmap-*` | Produced by `flutter_launcher_icons`. |
| iOS app icon set | `ios/Runner/Assets.xcassets/AppIcon.appiconset` | Produced by `flutter_launcher_icons`. |
| PWA icons / favicon | `web/icons`, `web/favicon.png` | Generated by `flutter_launcher_icons` from `app_icon_1024.png`. |
| Splash / onboarding art | `lib/features/splash`, `lib/features/onboarding` | Flutter painting and layout, no external images. |

The icon pipeline is deterministic: `python3 tool/generate_icon.py` creates the source images, then `dart run flutter_launcher_icons` generates Android (legacy/adaptive/monochrome), iOS and web/PWA icons.

## Copy and AI content

- `assets/ai/system_prompt_fa.md`, `assets/ai/tools/*.json`, `assets/ai/examples/*.json` were written for DARAM and are part of the product content.
- No content was copied from another assistant or finance app.

## What is *not* bundled

- No Lottie files: the app uses programmatic motion only, so no third-party animation license is involved.
- No stock photos or illustrations.
- No Google Fonts or remote SVG/PNG URLs.
- No invented letter icons: every catalog entry points to a real bank/neobank mark; digital banks without a standalone mark reuse the parent bank's logo (documented above).
