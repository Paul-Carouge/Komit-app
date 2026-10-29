import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/third_party_licenses.dart';

void main() {
  test('the vendored Lucide font and its code points list their licenses', () async {
    registerThirdPartyLicenses();

    final packages = await LicenseRegistry.licenses.expand((license) => license.packages).toSet();

    expect(packages, containsAll(['Lucide', 'lucide_icons_flutter']));
  });
}
