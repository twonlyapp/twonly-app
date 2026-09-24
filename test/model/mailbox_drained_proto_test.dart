import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';

void main() {
  test('decodes the server mailbox-drained signal', () {
    // ServerToClient.V0 (field 1) containing V0.mailboxDrained (field 11).
    final message = ServerToClient.fromBuffer([0x0a, 0x02, 0x58, 0x01]);

    expect(message.v0.hasMailboxDrained(), isTrue);
    expect(message.v0.mailboxDrained, isTrue);
    expect(message.v0.whichKind(), V0_Kind.mailboxDrained);
  });
}
