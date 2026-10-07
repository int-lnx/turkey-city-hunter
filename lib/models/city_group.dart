import 'city_item.dart';

class CityGroup {
  String id;
  String name;
  List<CityItem> items;

  CityGroup({
    required this.id,
    required this.name,
    List<CityItem>? items,
  }) : items = items ?? [];

  CityGroup copyWith({String? id, String? name, List<CityItem>? items}) {
    return CityGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory CityGroup.fromJson(Map<String, dynamic> json) => CityGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CityItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
