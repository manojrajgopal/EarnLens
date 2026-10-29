# Design system & UX infrastructure

Visual direction: premium lavender/purple finance app — lavender-tinted light background with
soft glows, white rounded cards with lavender-tinted shadows, purple gradient hero surfaces,
pastel organic tiles, large bold amounts, pill controls, a floating capsule navigation with a
raised centre orb. Dark theme mirrors it on deep purple-black surfaces.

## Tokens — `lib/core/theme/tokens.dart`

| Group | Tokens |
|---|---|
| Core colours | `lavender #CB7EEF`, `white #FFFFFF`, `black #000000`, `background #F3F3F3` (neutral), `pageLight #F6F4FB` (tinted page) |
| Purples | `violet` (links, active states, primary buttons — AA on white), `violetDeep`, `violetNight`, `orchid`, `lilacSoft` |
| Pastels | `peach/peachSoft`, `mint/mintSoft`, `sky/skySoft` (quick actions, rate tiles) |
| Status | `positive`, `warning`, `overdue`, `error` (+ `*Soft` backgrounds) |
| Spacing | `AppSpace.xs…xxl`, `gutter` (20; 16 below 360 px) |
| Radii | `AppRadius.sm 12 · md 20 · lg 28 · xl 36 · pill` |
| Elevation | `AppShadows.card(brightness)`, `glow`, `nav` |
| Gradients | `AppGradients.hero`, `night`, `progress`, `orb`, `glow(opacity)` |
| Motion | `AppDurations.fast/medium/slow/chart/entrance`, `AppCurves.emphasized/decelerate/standard/overshoot/spring` |
| Icons | `AppIconSize.sm/md/lg/badge` |
| Breakpoints | `compact 360`, `twoColumn 700`, `rail 840`, `threeColumn 1100`, `contentMax 720`, `wideMax 1280` |
| Type | `AppType` — Urbanist: light display headings, medium labels, bold amounts |

Semantic colours per theme live in `EarnColors` (`context.colors`), which falls back to the default
palette if a widget is used outside the app theme.

## Components

`lib/shared/widgets/components.dart`: `EarnCard` (default / `accent` purple gradient / `dark` night
gradient / `tint` pastel; foreground inherited), `SectionHeader`, `LinkAction`, `Pill`, `Metric`,
`AmountText` (privacy masking), `EmptyState` (animated), `ErrorState`, `LoadingState` + `EarnLoader`
(branded bars), `EntranceScale`, `RoundIconButton`, `GradientButton`, `BusyButton` (duplicate-tap
safe), `InfoTip`, `confirmDialog`, `runGuarded`.

`lib/shared/widgets/organic.dart`: `OrganicBorder` (soft uneven card silhouette, deterministic per
seed), `OrganicTile`, `GradientProgress`, `AnimatedAmount` (display-only tween; final frame exact).

## Safe areas & edge-to-edge — `lib/shared/layout/page_layout.dart`

* The app is edge-to-edge (`SystemUiMode.edgeToEdge`) with transparent system bars; icon brightness
  follows the theme (`systemBarsFor`, applied via AppBar and an app-level `AnnotatedRegion`).
* Android windows extend into display cutouts on short edges (`values-v27`, `values-night-v27`);
  Flutter reports cutouts as `MediaQuery` padding.
* Top insets: handled by `AppBar`, or explicitly (dashboard adds `MediaQuery.padding.top`).
* Bottom insets: the shell `Scaffold` uses `extendBody`, so every screen inside the shell sees the
  floating nav's *measured* height (including the gesture handle or 3-button bar) as bottom
  `MediaQuery` padding. `AppInsets.bottomClearance` adds a 24 px gap — no hardcoded nav heights.
* Landscape cutouts: left/right padding is added to gutters.
* `EarnPageList` is the standard scrollable page: full-width scroll area (so pulls and scrolls work
  anywhere), content centred at a max width, optional pull-to-refresh.
* Keyboard: Scaffolds resize; forms are scrollable lists so actions stay reachable.

## Navigation — `lib/core/routing/app_shell.dart`

Phones: floating white capsule (max 520 px wide, centred) with Home · Income · **Insights orb** ·
Calendar · Settings. The orb is the real Insights branch. Active items get a lavender pill, bolder
violet label and a spring scale; haptic tick on change; 48 dp targets; Semantics labels. Widths ≥
840 px use a navigation rail. Branch stacks are preserved (`StatefulShellRoute.indexedStack`);
re-selecting a tab returns to its root; system back pops within a tab, and at a tab root returns
to Home before leaving the app.

## Pull-to-refresh — `EarnLensRefreshIndicator`

`lib/shared/widgets/earnlens_refresh_indicator.dart`. Lifecycle:

1. Drag starts at the top of the outermost vertical scrollable (`depth == 0`; horizontal carousels,
   charts and nested lists never trigger it).
2. Content follows the finger with exponential resistance; a lavender glow and a growth glyph
   (three bars) appear; bars rise with the pull.
3. Past the threshold (92 px) the badge fills with the purple orb gradient, an arrow appears, a light
   haptic fires and the label reads "Release to refresh".
4. Release → the content springs to a hold position, the bars pulse and a gradient ring sweeps
   ("Refreshing…") while `onRefresh` runs (min. 550 ms visible so the feedback is perceivable).
5. Success → bars morph into a check ("Updated"); failure → warning glyph ("Couldn't refresh").
6. A critically-damped spring returns everything to rest. Screen readers get an announcement.

Pulls during a refresh are ignored; errors never leave it stuck; reduced motion disables rotation,
pulsing and content translation. Pass `onRefresh` to `EarnPageList` / `PageList` / `AnalyticsBody`
/ `SettingsPage`.

The operation is `AppRefresher.refresh(scopes)` (`lib/features/refresh/application/`): it re-reads
the local database, recomputes derived values, and re-syncs reminders and the home widget. It is
offline, writes nothing (tested), and concurrent calls share one operation. Widget-held filters,
selected months and unsaved inputs are untouched. Forms and static screens have no pull-to-refresh.

## App icon

Source of truth: `assets/images/earnlens_app_icon.png` (the supplied *Glossy Purple Growth
Finance Icon*, 1254×1254, transparent). Derived assets were produced by scaling/placing only:

| Target | Files | Notes |
|---|---|---|
| Android adaptive (8+) | `mipmap-*/ic_launcher_foreground.png`, `mipmap-anydpi-v26/ic_launcher.xml`, `@color/ic_launcher_background #EEEBFB` | tile scaled to 58% of the 108 dp canvas so it sits inside circle/squircle/rounded masks on the tile's own colour |
| Android legacy (7.x) | `mipmap-*/ic_launcher.png` | full image incl. transparent glow |
| Splash (pre-12) | `drawable*/launch_background.xml` | icon on brand background (light/dark) |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` | opaque (App Store forbids alpha): tile on `#EEEBFB` |
| Web | `web/icons/Icon-192/512.png`, `Icon-maskable-*.png`, `web/favicon.png` | maskable variants padded on the tile colour |
| In-app mark | `assets/images/earnlens_mark.png` | cropped tile, used by `EarnLensMark` |

## Visual verification

`test/tools/screenshot_harness_test.dart` renders screens with the real font at several device
profiles (360×640 3-button, 393×852 notch + gesture, 412×915 punch-hole dark, 820×1180 tablet) plus
pull-to-refresh frames, into `build/screens/`:

```bash
flutter test test/tools/screenshot_harness_test.dart --update-goldens --dart-define=SCREENSHOTS=true
```

(Skipped in normal runs. In these renders `₹` appears as a box because the test environment has no
system fallback font, and shadows are unblurred — both render correctly on devices.)
