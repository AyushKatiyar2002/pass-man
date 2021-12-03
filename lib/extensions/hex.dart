extension HexString on String {
  ///In case of string is hex string
  List<int> get hexUnits {
    List<int> res = [];
    if ((this.length % 2) == 1) throw ArgumentError('Text Size is wrong');
    for (int i = 0; i < this.length; i += 2)
      res.add(int.parse(this.substring(i, i + 2), radix: 16));
    return res;
  }

  String get hexString => this.codeUnits.hexString;
}

extension HexList on List<int> {
  String get hexString {
    String res = '', temp;
    this.forEach((value) {
      temp = value.toRadixString(16);
      if (temp.length == 1) temp = '0' + temp;
      res += temp;
    });
    return res;
  }
}
