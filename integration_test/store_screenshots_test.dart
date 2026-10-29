// Flutter only runs tests on a device from integration_test/. The store
// screenshot test lives in docs/screenshots; run it through
// docs/screenshots/take_screenshots.sh, never on a device with real data.
import '../docs/screenshots/app/store_screenshots.dart' as store_screenshots;

void main() => store_screenshots.main();
