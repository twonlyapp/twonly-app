# twonly

<a href="https://twonly.eu" rel="some text"><img src="docs/header.webp" alt="twonly, a privacy-friendly way to connect with friends through secure, spontaneous image sharing." /></a>

This repository contains the complete source code of the [twonly](https://twonly.eu) apps.

## Features

- Offer a Snapchat™ like experience
- End-to-End encryption using the [Signal Protocol](https://de.wikipedia.org/wiki/Signal-Protokoll)
- No email or phone number required to register
- Privacy friendly - Everything is stored on the device
- Open-Source

## In work

- For Android: Using [UnifiedPush](https://unifiedpush.org/) instead of FCM 
- For Android: Reproducible Builds + Publishing F-Droid
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

When you download the app **via GitHub** you can verify the signing keys using for example the [AppVerifyer](https://github.com/soupslurpr/AppVerifier) and the following SHA-256 fingerprint of the signing certificate.

eu.twonly
E3:C4:4D:56:8C:67:F9:32:AC:8C:33:90:99:8A:B9:5E:E8:FF:2D:7A:07:3C:24:E3:66:77:93:E6:EA:CD:77:0A


## License
This project is licensed under the [GNU AGPL 3.0](LICENSE) license.