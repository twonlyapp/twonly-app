# twonly

run-as eu.twonly.testing ls /data/user/0/eu.twonly.testing/



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

