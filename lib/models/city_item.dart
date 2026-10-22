enum ItemImportance {
  mustSee(10, 'Görmeden Ölme', 0xFFEF4444), // Red
  highlyRecommended(5, 'Mutlaka Görülmeli', 0xFFF59E0B), // Orange/Amber
  recommended(3, 'Görülmeli', 0xFF10B981), // Green
  ordinary(1, 'Sıradan', 0xFF64748B); // Slate Gray

  final int weight;
  final String label;
  final int colorValue;

  const ItemImportance(this.weight, this.label, this.colorValue);

  static ItemImportance fromName(String? name) {
    return ItemImportance.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ItemImportance.ordinary,
    );
  }
}

class CityItem {
  String id;
  String name;
  String note;
  String description;
  String imageUrl;
  bool isChecked;
  ItemImportance importance;
  List<CityItem> subItems;

  CityItem({
    required this.id,
    required this.name,
    this.note = '',
    this.description = '',
    this.imageUrl = '',
    this.isChecked = false,
    this.importance = ItemImportance.ordinary,
    List<CityItem>? subItems,
  }) : subItems = subItems ?? [];

  /// Effective checked count for this item (itself or sub-items if present)
  bool get effectiveIsChecked {
    if (subItems.isEmpty) return isChecked;
    return subItems.every((s) => s.isChecked);
  }

  /// Total weighted score available for this item (including sub-items)
  double get totalWeight {
    if (subItems.isEmpty) {
      return importance.weight.toDouble();
    }
    return subItems.fold(0.0, (sum, s) => sum + s.totalWeight);
  }

  /// Checked weighted score earned by this item (including sub-items)
  double get checkedWeight {
    if (subItems.isEmpty) {
      return isChecked ? importance.weight.toDouble() : 0.0;
    }
    return subItems.fold(0.0, (sum, s) => sum + s.checkedWeight);
  }

  int get totalCount => subItems.isEmpty ? 1 : subItems.length;
  int get checkedCount =>
      subItems.isEmpty ? (isChecked ? 1 : 0) : subItems.where((s) => s.isChecked).length;

  CityItem copyWith({
    String? id,
    String? name,
    String? note,
    String? description,
    String? imageUrl,
    bool? isChecked,
    ItemImportance? importance,
    List<CityItem>? subItems,
  }) {
    return CityItem(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isChecked: isChecked ?? this.isChecked,
      importance: importance ?? this.importance,
      subItems: subItems ?? this.subItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'description': description,
        'imageUrl': imageUrl,
        'isChecked': isChecked,
        'importance': importance.name,
        'subItems': subItems.map((s) => s.toJson()).toList(),
      };

  factory CityItem.fromJson(Map<String, dynamic> json) => CityItem(
        id: json['id'] as String,
        name: json['name'] as String,
        note: (json['note'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        imageUrl: (json['imageUrl'] as String?) ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
        importance: ItemImportance.fromName(json['importance'] as String?),
        subItems: (json['subItems'] as List<dynamic>? ?? [])
            .map((s) => CityItem.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

