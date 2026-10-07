/// Grid-based stylized Turkey map.
/// Turkey is represented as a grid where each cell is a province.
/// Coordinates are [col, row] in a grid system.
class TurkeyGridData {
  // Grid dimensions
  static const int cols = 13;
  static const int rows = 7;

  /// Each entry: cityId → [col, row] (0-indexed)
  /// Designed to roughly match Turkey's geography
  static const Map<String, List<int>> cityGrid = {
    // Row 0 (top - north)
    '22': [0, 0], // Edirne
    '39': [1, 0], // Kırklareli
    '34': [2, 0], // İstanbul
    '41': [3, 0], // Kocaeli
    '67': [4, 0], // Zonguldak
    '74': [5, 0], // Bartın
    '78': [6, 0], // Karabük
    '37': [7, 0], // Kastamonu
    '57': [8, 0], // Sinop
    '19': [9, 0], // Çorum
    '05': [10, 0], // Amasya
    '60': [11, 0], // Tokat
    // Row 1
    '59': [0, 1], // Tekirdağ
    '77': [1, 1], // Yalova
    '11': [2, 1], // Bilecik
    '14': [3, 1], // Bolu
    '81': [4, 1], // Düzce
    '54': [5, 1], // Sakarya
    '18': [6, 1], // Çankırı
    '71': [7, 1], // Kırıkkale
    '06': [8, 1], // Ankara
    '40': [9, 1], // Kırşehir
    '66': [10, 1], // Yozgat
    '58': [11, 1], // Sivas
    '24': [12, 1], // Erzincan
    // Row 2
    '10': [0, 2], // Balıkesir
    '16': [1, 2], // Bursa
    '43': [2, 2], // Kütahya
    '26': [3, 2], // Eskişehir
    '68': [4, 2], // Aksaray — moved
    '50': [5, 2], // Nevşehir
    '38': [6, 2], // Kayseri
    '44': [7, 2], // Malatya
    '23': [8, 2], // Elazığ
    '62': [9, 2], // Tunceli
    '29': [10, 2], // Gümüşhane
    '69': [11, 2], // Bayburt
    '25': [12, 2], // Erzurum
    // Row 3
    '17': [0, 3], // Çanakkale
    '45': [1, 3], // Manisa
    '64': [2, 3], // Uşak
    '42': [3, 3], // Konya
    '51': [4, 3], // Niğde
    '46': [5, 3], // Kahramanmaraş
    '27': [6, 3], // Gaziantep
    '21': [7, 3], // Diyarbakır
    '12': [8, 3], // Bingöl
    '04': [9, 3], // Ağrı
    '36': [10, 3], // Kars
    '75': [11, 3], // Ardahan
    '08': [12, 3], // Artvin
    // Row 4
    '35': [0, 4], // İzmir
    '09': [1, 4], // Aydın
    '20': [2, 4], // Denizli
    '15': [3, 4], // Burdur
    '32': [4, 4], // Isparta
    '33': [5, 4], // Mersin
    '31': [6, 4], // Hatay
    '47': [7, 4], // Mardin
    '72': [8, 4], // Batman
    '13': [9, 4], // Bitlis
    '49': [10, 4], // Muş
    '76': [11, 4], // Iğdır
    '53': [12, 4], // Rize
    // Row 5
    '48': [0, 5], // Muğla
    '07': [1, 5], // Antalya
    '70': [2, 5], // Karaman
    '80': [3, 5], // Osmaniye
    '79': [4, 5], // Kilis
    '63': [5, 5], // Şanlıurfa
    '56': [6, 5], // Siirt
    '73': [7, 5], // Şırnak
    '65': [8, 5], // Van
    '30': [9, 5], // Hakkari
    '61': [10, 5], // Trabzon
    '52': [11, 5], // Ordu
    '28': [12, 5], // Giresun
    // Row 6 (extra cities)
    '55': [9, 6], // Samsun — placed prominently
    '03': [3, 6], // Afyonkarahisar
    '02': [5, 6], // Adıyaman
    '01': [6, 6], // Adana
    '33_2': [7, 6], // duplicate slot
  };

  /// Plate number → city name (for display alongside grid)
  static const Map<String, String> cityNames = {
    '01': 'Adana', '02': 'Adıyaman', '03': 'Afyonkarahisar', '04': 'Ağrı',
    '05': 'Amasya', '06': 'Ankara', '07': 'Antalya', '08': 'Artvin',
    '09': 'Aydın', '10': 'Balıkesir', '11': 'Bilecik', '12': 'Bingöl',
    '13': 'Bitlis', '14': 'Bolu', '15': 'Burdur', '16': 'Bursa',
    '17': 'Çanakkale', '18': 'Çankırı', '19': 'Çorum', '20': 'Denizli',
    '21': 'Diyarbakır', '22': 'Edirne', '23': 'Elazığ', '24': 'Erzincan',
    '25': 'Erzurum', '26': 'Eskişehir', '27': 'Gaziantep', '28': 'Giresun',
    '29': 'Gümüşhane', '30': 'Hakkari', '31': 'Hatay', '32': 'Isparta',
    '33': 'Mersin', '34': 'İstanbul', '35': 'İzmir', '36': 'Kars',
    '37': 'Kastamonu', '38': 'Kayseri', '39': 'Kırklareli', '40': 'Kırşehir',
    '41': 'Kocaeli', '42': 'Konya', '43': 'Kütahya', '44': 'Malatya',
    '45': 'Manisa', '46': 'Kahramanmaraş', '47': 'Mardin', '48': 'Muğla',
    '49': 'Muş', '50': 'Nevşehir', '51': 'Niğde', '52': 'Ordu',
    '53': 'Rize', '54': 'Sakarya', '55': 'Samsun', '56': 'Siirt',
    '57': 'Sinop', '58': 'Sivas', '59': 'Tekirdağ', '60': 'Tokat',
    '61': 'Trabzon', '62': 'Tunceli', '63': 'Şanlıurfa', '64': 'Uşak',
    '65': 'Van', '66': 'Yozgat', '67': 'Zonguldak', '68': 'Aksaray',
    '69': 'Bayburt', '70': 'Karaman', '71': 'Kırıkkale', '72': 'Batman',
    '73': 'Şırnak', '74': 'Bartın', '75': 'Ardahan', '76': 'Iğdır',
    '77': 'Yalova', '78': 'Karabük', '79': 'Kilis', '80': 'Osmaniye',
    '81': 'Düzce',
  };
}
