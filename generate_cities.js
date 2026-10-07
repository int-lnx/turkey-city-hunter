const fs = require('fs');

const rawText = fs.readFileSync('raw_text.txt', 'utf8');
const cityPlateMap = JSON.parse(fs.readFileSync('city_plate_map.json'));

const lines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);

// Helper for TR uppercase
function trUpper(str) {
  return str.replace(/i/g, 'İ').replace(/ı/g, 'I').toUpperCase();
}

const parsedByPlate = {}; // plate -> list of place strings

let currentPlate = null;

lines.forEach(line => {
  const upper = trUpper(line);
  // Check if line matches a city name in cityPlateMap
  let foundPlate = null;
  for (const [cityName, plate] of Object.entries(cityPlateMap)) {
    if (upper === trUpper(cityName)) {
      foundPlate = plate;
      break;
    }
  }

  if (foundPlate) {
    currentPlate = foundPlate;
    if (!parsedByPlate[currentPlate]) parsedByPlate[currentPlate] = [];
  } else if (currentPlate) {
    parsedByPlate[currentPlate].push(line);
  }
});

console.log('Total cities with POIs parsed:', Object.keys(parsedByPlate).length);

// Generate turkey_cities_data.dart
let dartCode = `import '../models/city_model.dart';
import '../models/city_group.dart';
import '../models/city_item.dart';

List<CityModel> buildDefaultCities() {
  return [
`;

const plates = Object.keys(cityPlateMap).map(name => ({
  name: name,
  plate: cityPlateMap[name]
})).sort((a, b) => parseInt(a.plate) - parseInt(b.plate));

plates.forEach(({ name, plate }) => {
  const places = parsedByPlate[plate] || [];
  dartCode += `    // ── ${plate} ${name} ─────────────────────────────────────────────\n`;
  dartCode += `    CityModel(\n`;
  dartCode += `      id: '${plate}',\n`;
  dartCode += `      name: '${name}',\n`;
  if (places.length > 0) {
    dartCode += `      groups: [\n`;
    dartCode += `        CityGroup(\n`;
    dartCode += `          id: 'g-${plate}-1',\n`;
    dartCode += `          name: 'Görülecek Yerler',\n`;
    dartCode += `          items: [\n`;
    places.forEach((place, idx) => {
      // Escape single quotes if any
      const escapedPlace = place.replace(/'/g, "\\'");
      dartCode += `            CityItem(id: 'i-${plate}-${idx + 1}', name: '${escapedPlace}'),\n`;
    });
    dartCode += `          ],\n`;
    dartCode += `        ),\n`;
    dartCode += `      ],\n`;
  }
  dartCode += `    ),\n`;
});

dartCode += `  ];\n}\n`;

fs.writeFileSync('lib/data/turkey_cities_data.dart', dartCode);
console.log('turkey_cities_data.dart generated successfully!');
