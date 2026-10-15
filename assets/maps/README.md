# Offline country lookup

`countries.json.gz` contains Natural Earth v5.1.2 Admin 0 countries at 1:50m.
The data is [public domain](https://www.naturalearthdata.com/about/terms-of-use/).

Regenerate it by downloading the source URL in
`scripts/generate_memory_map_countries.py` and passing the downloaded GeoJSON
path to that script. The source digest is checked before generation.

All polygon components and interior rings are retained. Coordinates are
rounded to 0.001 degrees and delta encoded before gzip compression. Country
assignment is an approximate local lookup for selecting the initial map view;
it requires no reverse-geocoding requests or database changes.
