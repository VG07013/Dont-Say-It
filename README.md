# Don't Say It!

A fast party word game built as a Capacitor app for iOS.

Players describe the big word on the card without saying any of the forbidden words. Score points before the timer runs out.

## What's Inside

- Mobile-first HTML/CSS/JavaScript game in `www/`
- Capacitor iOS project in `ios/`
- Saved shuffled word bank using `localStorage`
- Polished iPhone-friendly layout with safe-area support

## Local Setup

```sh
npm install
npx cap sync ios
```

To preview the web app locally:

```sh
cd www
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Company

Don't Say It! is a VG Creative Labs LLC product.

- Privacy policy: https://vgcreativelabs.com/dont-say-it/
- Terms of Use: https://vgcreativelabs.com/terms/
- Support: support@vgcreativelabs.com

The home screen links all three. If the app ever adds an SDK, network call or new stored data, update the privacy policy (site repo `VG07013/vg-creative-labs`, `dont-say-it/index.html`) and App Privacy in App Store Connect the same day.
