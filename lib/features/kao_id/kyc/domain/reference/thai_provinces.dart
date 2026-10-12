/// One of Thailand's 77 provinces. [th] is the stored value and must match
/// `kaoid_private.thai_provinces_r16b()` on the server.
class ThaiProvince {
  const ThaiProvince(this.th, this.en);

  final String th;
  final String en;

  String label(String languageCode) => languageCode == 'th' ? th : '$en ($th)';
}

const thaiProvinces = <ThaiProvince>[
  ThaiProvince('กรุงเทพมหานคร', 'Bangkok'),
  ThaiProvince('กระบี่', 'Krabi'),
  ThaiProvince('กาญจนบุรี', 'Kanchanaburi'),
  ThaiProvince('กาฬสินธุ์', 'Kalasin'),
  ThaiProvince('กำแพงเพชร', 'Kamphaeng Phet'),
  ThaiProvince('ขอนแก่น', 'Khon Kaen'),
  ThaiProvince('จันทบุรี', 'Chanthaburi'),
  ThaiProvince('ฉะเชิงเทรา', 'Chachoengsao'),
  ThaiProvince('ชลบุรี', 'Chon Buri'),
  ThaiProvince('ชัยนาท', 'Chai Nat'),
  ThaiProvince('ชัยภูมิ', 'Chaiyaphum'),
  ThaiProvince('ชุมพร', 'Chumphon'),
  ThaiProvince('เชียงราย', 'Chiang Rai'),
  ThaiProvince('เชียงใหม่', 'Chiang Mai'),
  ThaiProvince('ตรัง', 'Trang'),
  ThaiProvince('ตราด', 'Trat'),
  ThaiProvince('ตาก', 'Tak'),
  ThaiProvince('นครนายก', 'Nakhon Nayok'),
  ThaiProvince('นครปฐม', 'Nakhon Pathom'),
  ThaiProvince('นครพนม', 'Nakhon Phanom'),
  ThaiProvince('นครราชสีมา', 'Nakhon Ratchasima'),
  ThaiProvince('นครศรีธรรมราช', 'Nakhon Si Thammarat'),
  ThaiProvince('นครสวรรค์', 'Nakhon Sawan'),
  ThaiProvince('นนทบุรี', 'Nonthaburi'),
  ThaiProvince('นราธิวาส', 'Narathiwat'),
  ThaiProvince('น่าน', 'Nan'),
  ThaiProvince('บึงกาฬ', 'Bueng Kan'),
  ThaiProvince('บุรีรัมย์', 'Buri Ram'),
  ThaiProvince('ปทุมธานี', 'Pathum Thani'),
  ThaiProvince('ประจวบคีรีขันธ์', 'Prachuap Khiri Khan'),
  ThaiProvince('ปราจีนบุรี', 'Prachin Buri'),
  ThaiProvince('ปัตตานี', 'Pattani'),
  ThaiProvince('พระนครศรีอยุธยา', 'Phra Nakhon Si Ayutthaya'),
  ThaiProvince('พะเยา', 'Phayao'),
  ThaiProvince('พังงา', 'Phangnga'),
  ThaiProvince('พัทลุง', 'Phatthalung'),
  ThaiProvince('พิจิตร', 'Phichit'),
  ThaiProvince('พิษณุโลก', 'Phitsanulok'),
  ThaiProvince('เพชรบุรี', 'Phetchaburi'),
  ThaiProvince('เพชรบูรณ์', 'Phetchabun'),
  ThaiProvince('แพร่', 'Phrae'),
  ThaiProvince('ภูเก็ต', 'Phuket'),
  ThaiProvince('มหาสารคาม', 'Maha Sarakham'),
  ThaiProvince('มุกดาหาร', 'Mukdahan'),
  ThaiProvince('แม่ฮ่องสอน', 'Mae Hong Son'),
  ThaiProvince('ยโสธร', 'Yasothon'),
  ThaiProvince('ยะลา', 'Yala'),
  ThaiProvince('ร้อยเอ็ด', 'Roi Et'),
  ThaiProvince('ระนอง', 'Ranong'),
  ThaiProvince('ระยอง', 'Rayong'),
  ThaiProvince('ราชบุรี', 'Ratchaburi'),
  ThaiProvince('ลพบุรี', 'Lop Buri'),
  ThaiProvince('ลำปาง', 'Lampang'),
  ThaiProvince('ลำพูน', 'Lamphun'),
  ThaiProvince('เลย', 'Loei'),
  ThaiProvince('ศรีสะเกษ', 'Si Sa Ket'),
  ThaiProvince('สกลนคร', 'Sakon Nakhon'),
  ThaiProvince('สงขลา', 'Songkhla'),
  ThaiProvince('สตูล', 'Satun'),
  ThaiProvince('สมุทรปราการ', 'Samut Prakan'),
  ThaiProvince('สมุทรสงคราม', 'Samut Songkhram'),
  ThaiProvince('สมุทรสาคร', 'Samut Sakhon'),
  ThaiProvince('สระแก้ว', 'Sa Kaeo'),
  ThaiProvince('สระบุรี', 'Saraburi'),
  ThaiProvince('สิงห์บุรี', 'Sing Buri'),
  ThaiProvince('สุโขทัย', 'Sukhothai'),
  ThaiProvince('สุพรรณบุรี', 'Suphan Buri'),
  ThaiProvince('สุราษฎร์ธานี', 'Surat Thani'),
  ThaiProvince('สุรินทร์', 'Surin'),
  ThaiProvince('หนองคาย', 'Nong Khai'),
  ThaiProvince('หนองบัวลำภู', 'Nong Bua Lam Phu'),
  ThaiProvince('อ่างทอง', 'Ang Thong'),
  ThaiProvince('อำนาจเจริญ', 'Amnat Charoen'),
  ThaiProvince('อุดรธานี', 'Udon Thani'),
  ThaiProvince('อุตรดิตถ์', 'Uttaradit'),
  ThaiProvince('อุทัยธานี', 'Uthai Thani'),
  ThaiProvince('อุบลราชธานี', 'Ubon Ratchathani'),
];

ThaiProvince? thaiProvinceByName(String? th) {
  for (final province in thaiProvinces) {
    if (province.th == th) return province;
  }
  return null;
}
