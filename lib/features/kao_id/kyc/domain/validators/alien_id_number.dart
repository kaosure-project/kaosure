/// 13-digit personal number issued by the Department of Provincial
/// Administration, including numbers for non-Thai residents. The last digit is
/// a mod-11 check digit over the first twelve (weights 13..2); the server
/// applies the same rule in `kaoid_private.valid_thai_pid_r16b`.
bool isValidThaiPersonalNumber(String value) {
  if (!RegExp(r'^\d{13}$').hasMatch(value)) return false;
  var total = 0;
  for (var i = 0; i < 12; i++) {
    total += int.parse(value[i]) * (13 - i);
  }
  return (11 - total % 11) % 10 == int.parse(value[12]);
}
