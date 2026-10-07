import 'city_group.dart';
import 'city_item.dart';

class CityModel {
  final String id; // TR plate code e.g. "55" for Samsun
  final String name;
  final bool isVisited;
  List<CityGroup> groups;

  CityModel({
    required this.id,
    required this.name,
    this.isVisited = false,
    List<CityGroup>? groups,
  }) : groups = groups ?? [];

  /// City is visited if explicitly marked OR if any item is checked
  bool get effectiveIsVisited => isVisited || checkedItems > 0;

  /// Total count of items across all groups (including sub-items)
  int get totalItems =>
      groups.fold(0, (sum, g) => sum + g.items.fold(0, (iSum, item) => iSum + item.totalCount));

  /// Checked count of items across all groups (including sub-items)
  int get checkedItems => groups.fold(
      0, (sum, g) => sum + g.items.fold(0, (iSum, item) => iSum + item.checkedCount));

  /// Total weight of all items in this city
  double get totalWeight =>
      groups.fold(0.0, (sum, g) => sum + g.items.fold(0.0, (iSum, item) => iSum + item.totalWeight));

  /// Earned checked weight of items in this city
  double get checkedWeight =>
      groups.fold(0.0, (sum, g) => sum + g.items.fold(0.0, (iSum, item) => iSum + item.checkedWeight));

  /// Weighted completion percentage [0.0 – 1.0]
  double get completionRate {
    if (totalWeight == 0.0) return 0.0;
    return checkedWeight / totalWeight;
  }

  /// Percentage as display string e.g. "47%"
  String get completionPercent =>
      '${(completionRate * 100).toStringAsFixed(0)}%';

  CityModel copyWith({String? id, String? name, bool? isVisited, List<CityGroup>? groups}) {
    return CityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisited: isVisited ?? this.isVisited,
      groups: groups ?? this.groups,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isVisited': isVisited,
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: json['id'] as String,
        name: json['name'] as String,
        isVisited: (json['isVisited'] as bool?) ?? false,
        groups: (json['groups'] as List<dynamic>? ?? [])
            .map((g) => CityGroup.fromJson(g as Map<String, dynamic>))
            .toList(),
      );

  /// Convenience: get all items flat
  List<CityItem> get allItems =>
      groups.expand((g) => g.items).toList();
}
