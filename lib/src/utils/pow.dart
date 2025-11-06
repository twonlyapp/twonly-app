import 'package:cryptography_plus/cryptography_plus.dart';

bool isValid(int difficulty, List<int> digest) {
  final bits = digest.map((i) => i.toRadixString(2).padLeft(8, '0')).join();
  return bits.startsWith('0' * difficulty);
}

Future<int> calculatePoW(String prefix, int difficulty) async {
  var i = 0;
  while (true) {
    i++;
    final s = '$prefix$i';
    final digest = (await Sha256().hash(s.codeUnits)).bytes;
    if (isValid(difficulty, digest)) {
      return i;
    }
  }
}
