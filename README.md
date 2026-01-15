# twonly

<a href="https://twonly.eu" rel="some text"><img src="docs/header.webp" alt="twonly, a privacy-friendly way to connect with friends through secure, spontaneous image sharing." /></a>

This repository contains the complete source code of the [twonly](https://twonly.eu) apps.

<!-- <a href="https://testflight.apple.com/join/U9B3v2rk" >
    <img alt="Get it on Testflight button" src="https://twonly.eu/assets/buttons/get-it-on-testflight.png"
        width="100px" />
</a> -->
<div class="my-5 space-x-4">
    <div class="flex gap-5 items-center justify-center">
        <a href="https://apps.apple.com/de/app/twonly/id6743774441">
            <img alt="Get it on App Store button" src="https://twonly.eu/assets/buttons/download-on-the-app-store.svg"
                width="100px" />
        </a>
        <a href="https://play.google.com/store/apps/details?id=eu.twonly">
            <img alt="Get it on Google-Play button" src="https://twonly.eu/assets/buttons/get-it-in-google-play.webp"
                width="110px" />
        </a>
        <a href="https://github.com/twonlyapp/twonly-app/releases">
            <img alt="Get it on Github button" src="https://twonly.eu/assets/buttons/get-it-on-github.webp" width="110px" />
        </a>
        <a href="https://releases.twonly.eu/fdroid/repo/">
            <img alt="Get it on F-Droid button" src="https://twonly.eu/assets/buttons/get-it-on-f-droid.webp" width="105px" />
        </a>
    </div>
</div>


## Features

- Offer a Snapchat™ like experience
- End-to-End encryption using the [Signal Protocol](https://de.wikipedia.org/wiki/Signal-Protokoll)
- Open Source and can be downloaded directly from GitHub
- No email or phone number required to register
- Privacy friendly - Everything is stored on the device
- The backend is hosted exclusively in Europe

## Planned

- For Android: Optional support for [UnifiedPush](https://unifiedpush.org/)
- For Android: Reproducible Builds
- Implementing [Sealed Sender](https://signal.org/blog/sealed-sender/) to minimize metadata

## Security Issues

If you discover a security issue in twonly, please adhere to the coordinated vulnerability disclosure model. Please send
us your report to security@twonly.eu. We also offer for critical security issues a small bug bounties, but we can not
guarantee a bounty currently :/

## Development

<details>
<summary>Setup Instructions (macOS)</summary>

## Building

Some dependencies are downloaded directly from the source as there are some new changes which are not yet published on
pub.dev or because they require some special installation.

```bash
git submodule update --init --recursive

cd dependencies/flutter_zxing
git submodule update --init --recursive
./scripts/update_ios_macos_src.s
```

## Debugging files

```bash
run-as eu.twonly.testing ls /data/user/0/eu.twonly.testing/
```

</details>


## Signing Keys

When you download the app **via GitHub or F-Droid** you can verify the signing keys using for example the [AppVerifyer](https://github.com/soupslurpr/AppVerifier) and the following SHA-256 fingerprint of the signing certificate.

eu.twonly
E3:C4:4D:56:8C:67:F9:32:AC:8C:33:90:99:8A:B9:5E:E8:FF:2D:7A:07:3C:24:E3:66:77:93:E6:EA:CD:77:0A


## License
This project is licensed under the [GNU AGPL 3.0](LICENSE) license.
