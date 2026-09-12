import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/trusted_peers.dart';

void main() {
  late NooDatabase db;
  late TrustedPeers trusted;

  setUp(() {
    db = NooDatabase.memory();
    trusted = TrustedPeers(db);
  });

  tearDown(() async => db.close());

  test('nothing is trusted to begin with', () async {
    expect(await trusted.all(), isEmpty);
    expect(await trusted.isTrusted('device-a'), isFalse);
  });

  test('trust survives a re-read and keeps the announced name', () async {
    await trusted.trust('device-a', 'Laptop');
    await trusted.trust('device-b', null);

    // A second instance reads what the first wrote — the list is state, not
    // in-memory bookkeeping.
    final reopened = TrustedPeers(db);
    expect(await reopened.all(), {'device-a': 'Laptop', 'device-b': ''});
    expect(await reopened.isTrusted('device-a'), isTrue);
  });

  test('trusting again refreshes a renamed device', () async {
    await trusted.trust('device-a', 'Laptop');
    await trusted.trust('device-a', 'Work Laptop');
    expect(await trusted.all(), {'device-a': 'Work Laptop'});
  });

  test('revoking removes only that device', () async {
    await trusted.trust('device-a', 'Laptop');
    await trusted.trust('device-b', 'Phone');

    await trusted.revoke('device-a');

    expect(await trusted.isTrusted('device-a'), isFalse);
    expect(await trusted.isTrusted('device-b'), isTrue);
  });

  test('revoking an unknown device is a no-op', () async {
    await trusted.trust('device-a', 'Laptop');
    await trusted.revoke('device-nobody');
    expect(await trusted.all(), {'device-a': 'Laptop'});
  });

  test('a corrupt stored value trusts nobody rather than throwing', () async {
    await db.setProperty(TrustedPeers.propertyKey, 'not json at all');

    // Failing open here would let anyone through; failing closed only costs a
    // prompt, and the next trust() rewrites the value cleanly.
    expect(await trusted.all(), isEmpty);
    expect(await trusted.isTrusted('device-a'), isFalse);

    await trusted.trust('device-a', 'Laptop');
    expect(await trusted.all(), {'device-a': 'Laptop'});
  });
}
