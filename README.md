# Read to Scroll

An iOS app that keeps Instagram locked until you've earned time by reading in Apple Books.

By default, 1 minute of reading earns 3 minutes of Instagram, up to 60 minutes a day. When your balance runs out, Instagram is shielded until you read more. The balance resets at local midnight.

## How it works

- **Earn:** reading time in Apple Books is tracked through Screen Time (DeviceActivity threshold events).
- **Spend:** Instagram use draws down the earned balance. At zero, a custom shield screen blocks the app and tells you how much reading unlocks more.
- **Adjustable rules:** set the ratio (1–10× reading time) and the daily cap (10–120 min). Stricter changes apply immediately. Looser ones (higher ratio, higher cap, turning enforcement off) wait until the next day, so you can't loosen the rules on impulse.
- **Emergency unlock:** opens Instagram for a few minutes (1–15, default 5) when you need your messages. These minutes don't count against your earned balance.
- **Log screen:** every shield decision is logged with its reason, for live diagnostics.

## Project layout

| Path | What it is |
| --- | --- |
| `App/` | SwiftUI app: setup, today view, settings, debug log |
| `Monitor/` | DeviceActivity monitor extension; records read/spend events and applies the shield |
| `Shield/` | Shield configuration extension (custom block screen) |
| `ShieldAction/` | Shield action extension (close button) |
| `Shared/` | Bridge between RewardCore and FamilyControls / ManagedSettings / DeviceActivity; App Group storage |
| `Packages/RewardCore/` | Pure Swift package with all the business rules (policy, daily ledger, settings roll-over, shield copy), with no Screen Time imports |
| `project.yml` | XcodeGen spec for all four targets |

App and extensions share state through App Group `UserDefaults`.

## Building

Requirements: Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen), a **physical iPhone on iOS 17+** (Screen Time APIs don't work in the Simulator), and an Apple developer account with the Family Controls capability.

```bash
brew install xcodegen
xcodegen generate          # creates ReadToScroll.xcodeproj (git-ignored)
open ReadToScroll.xcodeproj
```

To build under your own account, change `DEVELOPMENT_TEAM`, `bundleIdPrefix`, the bundle identifiers and the App Group (`group.com.joshhinder.readtoscroll`) in `project.yml`.

On first launch, grant Screen Time access, pick Apple Books as the "earn" app and Instagram as the "spend" app.

## Tests

The business logic is unit-tested without a device:

```bash
cd Packages/RewardCore
swift test
```

## Limitations

- Screen Time locks the whole app, so all of Instagram is blocked (including DMs). Emergency unlock is the way around this.
- Reading is measured as time spent in the Books app, not pages read.
- iOS requires DeviceActivity windows of at least 15 minutes, so an emergency unlock runs in a 16-minute monitoring window.
