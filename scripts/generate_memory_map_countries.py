"""Build the compact, offline Memories map country lookup.

Usage: python3 scripts/generate_memory_map_countries.py SOURCE.geojson
Source: https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_50m_admin_0_countries.geojson
Natural Earth data is public domain: https://www.naturalearthdata.com/about/terms-of-use/
"""

import gzip
import hashlib
import json
from pathlib import Path
import sys

SOURCE_SHA256 = "3e458fc036ad0a66411f2c1e6cac49c5d7bfb81cb1123bc513b22511a2b7fdeb"
SCALE = 1000


def main():
    source = Path(sys.argv[1]).read_bytes()
    if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
        raise ValueError("Unexpected Natural Earth source; check its version and digest")
    countries = []
    for feature in json.loads(source)["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"]
        if geometry["type"] == "Polygon":
            polygons = [polygons]
        encoded_polygons = []
        for polygon in polygons:
            rings = []
            for ring in polygon:
                previous = [0, 0]
                deltas = []
                for coordinates in ring:
                    point = [round(value * SCALE) for value in coordinates]
                    deltas.extend([point[0] - previous[0], point[1] - previous[1]])
                    previous = point
                rings.append(deltas)
            encoded_polygons.append(rings)
        countries.append([feature["properties"]["ADM0_A3"], encoded_polygons])
    payload = json.dumps(
        {"scale": SCALE, "countries": countries}, separators=(",", ":")
    ).encode()
    output = Path(__file__).resolve().parents[1] / "assets/maps/countries.json.gz"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(gzip.compress(payload, mtime=0))
    print(f"Wrote {len(countries)} countries in {output.stat().st_size} bytes")


if __name__ == "__main__":
    main()
