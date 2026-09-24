import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart';

void main() {
  test('PQC upload preserves migration identity fields on the wire', () {
    final request = ApplicationData_UploadPqcPreKeys(
      eccSignedPrekeyId: Int64(11),
      eccSignedPrekey: [5, 6],
      eccSignedPrekeySignature: [7, 8],
      kyberSignedPrekeyId: Int64(12),
      kyberSignedPrekey: [9, 10],
      kyberSignedPrekeySignature: [11, 12],
      publicIdentityKey: List<int>.filled(33, 1),
      registrationId: Int64(42),
    );

    final decoded = ApplicationData_UploadPqcPreKeys.fromBuffer(
      request.writeToBuffer(),
    );

    expect(decoded.publicIdentityKey, hasLength(33));
    expect(decoded.registrationId, Int64(42));
    expect(decoded.hasPublicIdentityKey(), isTrue);
    expect(decoded.hasRegistrationId(), isTrue);
  });
}
