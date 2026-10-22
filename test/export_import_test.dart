import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkiye_kesif_haritasi/providers/city_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Export and import map data creates a new isolated map profile', () async {
    final provider = CityProvider();

    // Export test
    final exportedJson = provider.exportMapData();
    expect(exportedJson.contains('turkiye_kesif_haritasi'), isTrue);
    expect(exportedJson.contains('cities'), isTrue);

    // Import test with existing user conflict
    final importedName1 = await provider.importMapData(exportedJson, customMapName: 'Varsayılan');
    expect(importedName1, equals('Varsayılan (1)'));
    expect(provider.users.contains('Varsayılan (1)'), isTrue);
    expect(provider.currentUser, equals('Varsayılan (1)'));

    // Import again, should generate (2) and not overwrite
    final importedName2 = await provider.importMapData(exportedJson, customMapName: 'Varsayılan');
    expect(importedName2, equals('Varsayılan (2)'));
    expect(provider.users.contains('Varsayılan (2)'), isTrue);
    expect(provider.currentUser, equals('Varsayılan (2)'));
  });
}
