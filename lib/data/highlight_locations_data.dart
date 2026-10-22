import '../models/city_item.dart';

class HighlightLocation {
  final String cityId;
  final String cityName;
  final String title;
  final String imageUrl;
  final ItemImportance importance;
  final String category;
  /// Optional name or keyword matching the item in city data to verify if visited
  final String? itemNameMatch;

  const HighlightLocation({
    required this.cityId,
    required this.cityName,
    required this.title,
    required this.imageUrl,
    required this.importance,
    required this.category,
    this.itemNameMatch,
  });
}

/// Türkiye'nin mutlaka görülmesi gereken önemli kültürel, tarihi ve doğal lokasyonları
const List<HighlightLocation> kHighlightLocations = [
  HighlightLocation(
    cityId: '50',
    cityName: 'Nevşehir',
    title: 'Kapadokya Peri Bacaları',
    imageUrl: 'https://images.unsplash.com/photo-1641128324571-a92c342eb3a8?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Doğa & Tarih',
    itemNameMatch: 'Kapadokya',
  ),
  HighlightLocation(
    cityId: '34',
    cityName: 'İstanbul',
    title: 'Ayasofya & Sultanahmet',
    imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Tarihi Miras',
    itemNameMatch: 'Ayasofya',
  ),
  HighlightLocation(
    cityId: '20',
    cityName: 'Denizli',
    title: 'Pamukkale Travertenleri',
    imageUrl: 'https://images.unsplash.com/photo-1598887142487-3c854d51d2c7?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Doğal Mucize',
    itemNameMatch: 'Pamukkale Travertenleri',
  ),
  HighlightLocation(
    cityId: '02',
    cityName: 'Adıyaman',
    title: 'Nemrut Dağı Heykelleri',
    imageUrl: 'https://images.unsplash.com/photo-1563822249548-9a72b6353cd1?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Tarih & Gizem',
    itemNameMatch: 'Nemrut Dağı',
  ),
  HighlightLocation(
    cityId: '35',
    cityName: 'İzmir',
    title: 'Efes Antik Kenti (Celsus)',
    imageUrl: 'https://images.unsplash.com/photo-1605649487212-47bdab064df8?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Antik Çağ',
    itemNameMatch: 'Efes Antik Kenti',
  ),
  HighlightLocation(
    cityId: '63',
    cityName: 'Şanlıurfa',
    title: 'Göbeklitepe',
    imageUrl: 'https://images.unsplash.com/photo-1582298538104-fe2e74c27f59?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Tarihin Sıfır Noktası',
    itemNameMatch: 'Göbeklitepe',
  ),
  HighlightLocation(
    cityId: '07',
    cityName: 'Antalya',
    title: 'Kaş & Kaputaş Plajı',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.highlyRecommended,
    category: 'Turkuaz Kıyı',
    itemNameMatch: 'Kaputaş Plajı',
  ),
  HighlightLocation(
    cityId: '48',
    cityName: 'Muğla',
    title: 'Ölüdeniz & Kelebekler Vadisi',
    imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Doğa & Deniz',
    itemNameMatch: 'Ölüdeniz',
  ),
  HighlightLocation(
    cityId: '61',
    cityName: 'Trabzon',
    title: 'Sümela Manastırı',
    imageUrl: 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.highlyRecommended,
    category: 'Kültürel Miras',
    itemNameMatch: 'Sümela',
  ),
  HighlightLocation(
    cityId: '47',
    cityName: 'Mardin',
    title: 'Eski Mardin Taş Konakları',
    imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Tarihi Doku',
    itemNameMatch: 'Dara Antik Kenti',
  ),
  HighlightLocation(
    cityId: '08',
    cityName: 'Artvin',
    title: 'Borçka Karagöl',
    imageUrl: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.highlyRecommended,
    category: 'Milli Park & Doğa',
    itemNameMatch: 'Karagöl',
  ),
  HighlightLocation(
    cityId: '04',
    cityName: 'Ağrı',
    title: 'İshak Paşa Sarayı',
    imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.highlyRecommended,
    category: 'Osmanlı Mimarisi',
    itemNameMatch: 'İshak Paşa',
  ),
  HighlightLocation(
    cityId: '65',
    cityName: 'Van',
    title: 'Akdamar Adası ve Kilisesi',
    imageUrl: 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.highlyRecommended,
    category: 'Göl & Tarih',
    itemNameMatch: 'Akdamar',
  ),
  HighlightLocation(
    cityId: '06',
    cityName: 'Ankara',
    title: 'Anıtkabir',
    imageUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Milli Bellek',
    itemNameMatch: 'Anıtkabir',
  ),
  HighlightLocation(
    cityId: '27',
    cityName: 'Gaziantep',
    title: 'Zeugma Mozaik Müzesi',
    imageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.highlyRecommended,
    category: 'Sanat & Mozaik',
    itemNameMatch: 'Zeugma',
  ),
  HighlightLocation(
    cityId: '22',
    cityName: 'Edirne',
    title: 'Selimiye Camii',
    imageUrl: 'https://images.unsplash.com/photo-1590076215667-875d4ef2d7ee?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Mimar Sinan Şaheseri',
    itemNameMatch: 'Selimiye',
  ),
  HighlightLocation(
    cityId: '42',
    cityName: 'Konya',
    title: 'Mevlana Müzesi & Türbesi',
    imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=500&auto=format&fit=crop&q=80',
    importance: ItemImportance.mustSee,
    category: 'Manevi & Tarih',
    itemNameMatch: 'Mevlana',
  ),
];
