import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';

class _Party {
  _Party(this.name)
    : store = InMemorySignalProtocolStore(
        generateIdentityKeyPair(),
        generateRegistrationId(false),
      );

  final String name;
  final InMemorySignalProtocolStore store;
  var _nextKeyId = 1;

  SignalProtocolAddress get address => SignalProtocolAddress(name, 1);

  SessionCipher cipherFor(_Party other) =>
      SessionCipher.fromStore(store, other.address);

  Future<PreKeyBundle> newBundle() async {
    final keyId = _nextKeyId++;
    final preKey = generatePreKeys(keyId, 1).single;
    await store.storePreKey(preKey.id, preKey);
    final identity = await store.getIdentityKeyPair();
    final signedPreKey = generateSignedPreKey(identity, keyId);
    await store.storeSignedPreKey(signedPreKey.id, signedPreKey);
    return PreKeyBundle(
      await store.getLocalRegistrationId(),
      1,
      preKey.id,
      preKey.getKeyPair().publicKey,
      signedPreKey.id,
      signedPreKey.getKeyPair().publicKey,
      signedPreKey.signature,
      identity.getPublicKey(),
    );
  }

  /// Starts a new session with [other] and has [other] accept it.
  Future<void> startSessionWith(_Party other) async {
    await SessionBuilder.fromSignalStore(
      store,
      other.address,
    ).processPreKeyBundle(await other.newBundle());
    final first = await cipherFor(other).encrypt(_text('first'));
    await other.cipherFor(this).decrypt(PreKeySignalMessage(first.serialize()));
  }
}

Uint8List _text(String text) => Uint8List.fromList(utf8.encode(text));

/// Alice encrypts [count] messages that never reach Bob.
Future<void> _loseMessages(SessionCipher aliceCipher, int count) async {
  for (var i = 0; i < count; i++) {
    await aliceCipher.encrypt(_text('lost $i'));
  }
}

Future<SignalMessage> _whisper(SessionCipher cipher, String text) async =>
    SignalMessage.fromSerialized(
      (await cipher.encrypt(_text(text))).serialize(),
    );

void main() {
  late _Party alice;
  late _Party bob;
  late SessionCipher aliceCipher;
  late SessionCipher bobCipher;

  setUp(() async {
    alice = _Party('alice');
    bob = _Party('bob');
    await alice.startSessionWith(bob);
    aliceCipher = alice.cipherFor(bob);
    bobCipher = bob.cipherFor(alice);
    // Bob's reply makes Alice ratchet to a sending chain Bob has not seen.
    final reply = await bobCipher.encrypt(_text('reply'));
    await aliceCipher.decryptFromSignal(
      SignalMessage.fromSerialized(reply.serialize()),
    );
  });

  test('accepts a message on a working chain', () async {
    final message = await _whisper(aliceCipher, 'hello');

    final record = await bob.store.loadSession(alice.address);
    expect(isBeyondReceivingWindow(record, message), isFalse);
    expect(utf8.decode(await bobCipher.decryptFromSignal(message)), 'hello');
  });

  test('agrees with libsignal at the edge of the receiving window', () async {
    await _loseMessages(aliceCipher, 2000);
    final atEdge = await _whisper(aliceCipher, 'counter 2000');
    final beyond = await _whisper(aliceCipher, 'counter 2001');
    expect(atEdge.getCounter(), 2000);

    final record = await bob.store.loadSession(alice.address);
    expect(isBeyondReceivingWindow(record, atEdge), isFalse);
    expect(isBeyondReceivingWindow(record, beyond), isTrue);

    await expectLater(
      bobCipher.decryptFromSignal(beyond),
      throwsA(isA<InvalidMessageException>()),
    );
    expect(
      utf8.decode(await bobCipher.decryptFromSignal(atEdge)),
      'counter 2000',
    );
  });

  test('checks archived session states as well', () async {
    await _loseMessages(aliceCipher, 2000);
    final delivered = await _whisper(aliceCipher, 'counter 2000');
    final heldBack = await _whisper(aliceCipher, 'counter 2001');
    await _loseMessages(aliceCipher, 2000);
    final farAhead = await _whisper(aliceCipher, 'counter 4002');
    expect(farAhead.getCounter(), 4002);

    // Bob's chain for these messages now continues at 2001.
    await bobCipher.decryptFromSignal(delivered);
    // A new session from Alice turns that chain's state into an archived one.
    await alice.startSessionWith(bob);

    final record = await bob.store.loadSession(alice.address);
    expect(record.previousSessionStates, hasLength(1));

    // Too far ahead for a new chain of the current state, but next in line
    // for the archived one.
    expect(isBeyondReceivingWindow(record, heldBack), isFalse);
    // Too far ahead for both.
    expect(isBeyondReceivingWindow(record, farAhead), isTrue);

    await expectLater(
      bobCipher.decryptFromSignal(farAhead),
      throwsA(isA<InvalidMessageException>()),
    );
    expect(
      utf8.decode(await bobCipher.decryptFromSignal(heldBack)),
      'counter 2001',
    );
  });

  test('leaves a missing session to libsignal', () async {
    final message = await _whisper(aliceCipher, 'hello');

    // Without a session there is no state to judge, libsignal reports the
    // missing session itself.
    final record = await bob.store.loadSession(
      const SignalProtocolAddress('carol', 1),
    );
    expect(isBeyondReceivingWindow(record, message), isFalse);
  });
}
