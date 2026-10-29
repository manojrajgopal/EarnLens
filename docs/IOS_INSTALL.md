# Installing the iPhone app from Windows

iOS apps can only be compiled on macOS, so EarnLens is built on a free GitHub-hosted Mac (the
`build-ios` job in `.github/workflows/ci.yml`). It produces an unsigned `EarnLens.ipa`, which you
install from Windows with a sideloading tool that signs it with your own Apple ID. No Mac, paid
Apple Developer account or rented machine is needed.

## 1. Get `EarnLens.ipa`

1. Push your changes to `main` on GitHub (or open **Actions → CI → Run workflow**).
2. Wait for the **CI** run to finish (the iOS job takes roughly 10–15 minutes).
3. Open the run, scroll to **Artifacts**, and download **EarnLens-ios**. Unzip it to get
   `EarnLens.ipa`. (The **EarnLens-android** artifact is the Android `EarnLens.apk`.)

Artifacts are kept for 90 days. If the iOS job fails, its log shows the error.

## 2. One-time setup on the PC

1. Install **iTunes** and **iCloud for Windows** from apple.com — the downloads on Apple's website,
   *not* the Microsoft Store versions (sideloading tools need the classic drivers).
2. Install **Sideloadly** from sideloadly.io.

## 3. Install on the iPhone

1. Connect the iPhone by USB, unlock it, and tap **Trust This Computer**.
2. Open Sideloadly, drag `EarnLens.ipa` into it, enter your Apple ID, and click **Start**. Enter
   the verification code if Apple asks for one.
3. On iOS 16 or later, turn on **Settings → Privacy & Security → Developer Mode** and restart when
   asked (one time only).
4. Open **Settings → General → VPN & Device Management**, tap your Apple ID and choose **Trust**.
5. Open **Earn Lens** from the home screen.

## Things to know about free Apple IDs

- **Re-install every 7 days.** Apps signed with a free Apple ID stop opening after 7 days. Repeat
  step 3.2 (Sideloadly can also refresh automatically over Wi-Fi while the PC is on). Your data is
  kept as long as you re-install the same app over the top — don't delete it first.
- **At most 3 sideloaded apps** at a time on the device.
- **"App ID not available" error:** in Sideloadly's *Advanced options*, enable *Change bundle ID*
  and keep using that same ID for every re-install so your data stays.
- Export a backup now and then (**Settings → Backup**) as a safety net.

## Publishing properly later

To install without the 7-day limit, or to publish on the App Store / TestFlight, you need a paid
Apple Developer account; the same CI job can then sign the build with your certificate.
