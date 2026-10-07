const fs = require('fs');
const g = JSON.parse(fs.readFileSync('assets/map/turkey.json'));

let out = 'class TurkeyProvinceGeoData {\n';
out += '  static final Map<int, List<List<List<double>>>> provincePolygons = {\n';

g.features.forEach(f => {
  const num = f.properties.number;
  const type = f.geometry.type;
  let coords = [];
  if (type === 'Polygon') {
    coords = [f.geometry.coordinates];
  } else if (type === 'MultiPolygon') {
    coords = f.geometry.coordinates;
  }
  
  out += `    ${num}: [\n`;
  coords.forEach(poly => {
    out += '      [\n';
    poly[0].forEach(pt => {
      out += `        [${pt[0]}, ${pt[1]}],\n`;
    });
    out += '      ],\n';
  });
  out += '    ],\n';
});

out += '  };\n';
out += '}\n';

fs.writeFileSync('lib/data/turkey_provinces_geo.dart', out);
console.log('Dart file generated successfully!');
