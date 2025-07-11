# twonly

<a href="https://twonly.eu" rel="some text"><img src="docs/header.webp" alt="twonly, a privacy-friendly way to connect with friends through secure, spontaneous image sharing." /></a>

This repository contains the complete source code of the [twonly](https://twonly.eu) apps.

## Features

- Offer a Snapchat™ like experience
- End-to-End encryption using the [Signal Protocol](https://de.wikipedia.org/wiki/Signal-Protokoll)
- No email or phone number required to register
- Privacy friendly - Everything is stored on the device

## In work

- We plan to implement a Sealed Sender feature to minimize metadata
- We currently evaluating to switch from the Signal Protocol to [MLS](https://openmls.tech/).


## Security Issues
If you discover a security issue in twonly, please adhere to the coordinated vulnerability disclosure model. Please send us your report to security@twonly.eu. We also offer for critical security issues a small bug bounties, but we can not guarantee a bounty currently :/

## Development

<details>
<summary>Setup Instructions (macOS)</summary>

## Building

Some dependencies are downloaded directly from the source as there are some new changes which are not yet published on
pub.dev or because they require some special installation.

- `flutter_secure_storage`: We need the 10.0.0-beta version, but this version has some issues which are fixed but [not yet published](https://github.com/juliansteenbakker/flutter_secure_storage/issues/866):

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


## License
This project is licensed under the [GNU AGPL 3.0](LICENSE) license.