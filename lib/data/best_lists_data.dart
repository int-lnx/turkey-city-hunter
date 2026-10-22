import '../models/city_item.dart';

class BestListItem {
  final String cityId;
  final String cityName;
  final String title;
  final String description;
  final String imageUrl;
  final ItemImportance importance;

  const BestListItem({
    required this.cityId,
    required this.cityName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.importance,
  });

  Map<String, dynamic> toJson() => {
        'cityId': cityId,
        'cityName': cityName,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'importance': importance.name,
      };

  factory BestListItem.fromJson(Map<String, dynamic> json) {
    return BestListItem(
      cityId: json['cityId'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      importance: ItemImportance.fromName(json['importance'] as String?),
    );
  }
}

class BestListPackage {
  final String id;
  final String title;
  final String subtitle;
  final String iconEmoji;
  final String coverImageUrl;
  final String category;
  final List<BestListItem> items;

  const BestListPackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.coverImageUrl,
    required this.category,
    required this.items,
  });

  BestListPackage copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? iconEmoji,
    String? coverImageUrl,
    String? category,
    List<BestListItem>? items,
  }) {
    return BestListPackage(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'iconEmoji': iconEmoji,
        'coverImageUrl': coverImageUrl,
        'category': category,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory BestListPackage.fromJson(Map<String, dynamic> json) {
    return BestListPackage(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      iconEmoji: json['iconEmoji'] as String? ?? '✨',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'Genel',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BestListItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

/// En İyiler Paketleri (Küratörlü Listeler)
const List<BestListPackage> kBestListPackages = [
  BestListPackage(
    id: 'dogal-guzellikler',
    title: 'En İyi Doğal Güzellikler',
    subtitle: 'Kanyonlar, travertenler, göller ve doğa harikaları',
    iconEmoji: '🌲',
    coverImageUrl: 'https://images.unsplash.com/photo-1598887142487-3c854d51d2c7?w=600&auto=format&fit=crop&q=80',
    category: 'Doğa & Macera',
    items: [
      BestListItem(
        cityId: '20',
        cityName: 'Denizli',
        title: 'Pamukkale Travertenleri',
        description: 'Beyaz traverten terasları ve antik şifalı termal sular.',
        imageUrl: 'https://images.unsplash.com/photo-1598887142487-3c854d51d2c7?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '50',
        cityName: 'Nevşehir',
        title: 'Kapadokya Peri Bacaları',
        description: 'Volkanik tüflerin rüzgar ve yağmurla aşınmasıyla oluşan eşsiz jeolojik oluşumlar.',
        imageUrl: 'https://images.unsplash.com/photo-1641128324571-a92c342eb3a8?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '08',
        cityName: 'Artvin',
        title: 'Borçka Karagöl',
        description: 'Heyelan set gölü olarak oluşan, yemyeşil ladin ormanlarıyla çevrili büyüleyici milli park.',
        imageUrl: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
      BestListItem(
        cityId: '48',
        cityName: 'Muğla',
        title: 'Saklıkent Kanyonu',
        description: 'Binlerce yıllık kireçtaşı aşınmasıyla oluşmuş 18 km uzunluğundaki derin kanyon.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
      BestListItem(
        cityId: '68',
        cityName: 'Aksaray',
        title: 'Ihlara Vadisi',
        description: 'Melendiz Çayı boyunca uzanan, kaya oyma kiliseleri ve yemyeşil florasıyla etkileyici kanyon.',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '07',
        cityName: 'Antalya',
        title: 'Düden Şelalesi & Tazı Kanyonu',
        description: 'Akdeniz’e dökülen şelaleler ve Köprülü Kanyon Milli Parkı’nın uçurumlu manzaraları.',
        imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
    ],
  ),
  BestListPackage(
    id: 'en-iyi-kumsallar',
    title: 'En İyi Kumsallar ve Koylar',
    subtitle: 'Turkuaz denizler, altın kumlar ve bakir kıyılar',
    iconEmoji: '🏖️',
    coverImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80',
    category: 'Deniz & Kıyı',
    items: [
      BestListItem(
        cityId: '07',
        cityName: 'Antalya',
        title: 'Kaputaş Plajı',
        description: 'Kanyon ağzında yer alan turkuaz mavisi doğal koy ve kumsal.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '48',
        cityName: 'Muğla',
        title: 'Ölüdeniz & Belcekız Plajı',
        description: 'Durgun suları ve Babadağ’dan süzülen yamaç paraşütleriyle ünlü dünya harikası lagün.',
        imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '48',
        cityName: 'Muğla',
        title: 'Fethiye Kelebekler Vadisi',
        description: 'Sadece deniz yoluyla veya zorlu patikayla ulaşılabilen saklı cennet koy.',
        imageUrl: 'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '07',
        cityName: 'Antalya',
        title: 'Patara Kumsalı',
        description: '18 kilometrelik uçsuz bucaksız kumsalı ve antik kent kalıntılarıyla caretta caretta yuvası.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
      BestListItem(
        cityId: '48',
        cityName: 'Muğla',
        title: 'Kabak Koyu',
        description: 'Doğayla baş başa kamp ve huzur arayanlar için derin çam ormanlarıyla çevrili koy.',
        imageUrl: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
      BestListItem(
        cityId: '35',
        cityName: 'İzmir',
        title: 'Çeşme Altınkum & Ilıca Plajı',
        description: 'Sıcak termal kaynakların denize karıştığı sığ ve kristal sular.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.recommended,
      ),
    ],
  ),
  BestListPackage(
    id: 'tarihi-noktalar',
    title: 'En İyi Tarihi & Arkeolojik Noktalar',
    subtitle: 'Uygarlıkların beşiği, antik şehirler ve anıtlar',
    iconEmoji: '🏛️',
    coverImageUrl: 'https://images.unsplash.com/photo-1605649487212-47bdab064df8?w=600&auto=format&fit=crop&q=80',
    category: 'Tarih & Miras',
    items: [
      BestListItem(
        cityId: '63',
        cityName: 'Şanlıurfa',
        title: 'Göbeklitepe',
        description: '12.000 yıl öncesine dayanan insanlık tarihinin bilinen en eski anıtsal tapınak kompleksi.',
        imageUrl: 'https://images.unsplash.com/photo-1582298538104-fe2e74c27f59?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '35',
        cityName: 'İzmir',
        title: 'Efes Antik Kenti (Celsus Kütüphanesi)',
        description: 'Roma döneminin en görkemli metropollerinden biri ve Artemis Tapınağı’nın evi.',
        imageUrl: 'https://images.unsplash.com/photo-1605649487212-47bdab064df8?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '02',
        cityName: 'Adıyaman',
        title: 'Nemrut Dağı Tümülüsü',
        description: 'Kommagene Kralı I. Antiochos’un tanrılara adadığı devasa heykeller ve gün doğumu anıtı.',
        imageUrl: 'https://images.unsplash.com/photo-1563822249548-9a72b6353cd1?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '61',
        cityName: 'Trabzon',
        title: 'Sümela Manastırı',
        description: 'Karadağ’ın sarp kayalıklarına inşa edilmiş 1600 yıllık Rum Ortodoks manastırı.',
        imageUrl: 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '34',
        cityName: 'İstanbul',
        title: 'Ayasofya & Sultanahmet Meydanı',
        description: 'Doğu Roma ve Osmanlı İmparatorluklarının kalbi, mimarlık tarihinin şaheseri.',
        imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '47',
        cityName: 'Mardin',
        title: 'Dara Antik Kenti & Deyrulzafaran',
        description: 'İpek Yolu üzerinde antik kaya garnizonu ve Süryani manastır mirası.',
        imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
    ],
  ),
  BestListPackage(
    id: 'mimari-kaleler',
    title: 'En Görkemli Saraylar ve Kaleler',
    subtitle: 'Surları aşan ihtişam, beylikler ve imparatorluk yapıları',
    iconEmoji: '🏰',
    coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop&q=80',
    category: 'Mimari',
    items: [
      BestListItem(
        cityId: '04',
        cityName: 'Ağrı',
        title: 'İshak Paşa Sarayı',
        description: 'Doğubayazıt ovasına hakim, Selçuklu ve Osmanlı mimarisinin görkemli son büyük anıtı.',
        imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '34',
        cityName: 'İstanbul',
        title: 'Topkapı & Dolmabahçe Sarayı',
        description: 'Boğazın kıyısında 600 yıllık cihan imparatorluğunun yönetim merkezleri.',
        imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
      BestListItem(
        cityId: '48',
        cityName: 'Muğla',
        title: 'Bodrum Kalesi (St. Jean)',
        description: 'Şövalyeler tarafından inşa edilen ve günümüzde Sualtı Arkeoloji Müzesi’ne ev sahipliği yapan kale.',
        imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
      BestListItem(
        cityId: '07',
        cityName: 'Antalya',
        title: 'Alanya Kalesi & Kızılkule',
        description: 'Selçuklu Sultanı Alaaddin Keykubat’ın Akdeniz kıyısındaki görkemli savunma kalesi.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.highlyRecommended,
      ),
      BestListItem(
        cityId: '22',
        cityName: 'Edirne',
        title: 'Selimiye Camii',
        description: 'Mimar Sinan’ın "Ustalık eserim" dediği, kubbesi ve minareleriyle dünya mimarlık harikası.',
        imageUrl: 'https://images.unsplash.com/photo-1590076215667-875d4ef2d7ee?w=500&auto=format&fit=crop&q=80',
        importance: ItemImportance.mustSee,
      ),
    ],
  ),
];
