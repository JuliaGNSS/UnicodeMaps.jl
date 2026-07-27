# UnicodeMaps.jl

Render OpenStreetMap-derived **vector** map tiles to your terminal as colored
braille/Unicode art — a Julia take on [mapscii](https://github.com/rastapasta/mapscii).

It downloads [Mapbox Vector Tiles](https://github.com/mapbox/vector-tile-spec)
(MVT), decodes them, applies a [Mapbox GL](https://maplibre.org/maplibre-style-spec/)
style, and draws the result on a braille canvas with 24-bit color.

```julia
using UnicodeMaps

# Berlin at zoom 6
worldmap(center = (13.42, 52.51), zoom = 6)

# The whole world
worldmap(center = (0.0, 20.0), zoom = 1)
```

`worldmap` returns a `MapImage` that prints itself as colored terminal art.

## Examples

Real output (in the terminal it is 24-bit color; shown here in monochrome).
By default a red pin marks the requested `center` (Google-Maps style); it is
omitted from these monochrome samples for clarity — pass `marker = false` to hide it.

**The whole world**, `worldmap(center = (0.0, 25.0), zoom = 1)`:

```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⠉⠀⠀⠀⠀⠀⠈⢹⣂⠀⢀⣽⠖⢒⣖⣉⠭⠭⣇⣀⣠⢤⣤⡀⠀⠀⠀⠀⠀⢀⣺⠀⠀⠀⠀⢮⡀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿France⢴⣍⣥⠿⠛⢣⠤⡾⢅⣀⣀⡜⠀⠀⠀⠀⣯⢧⣴⣄⣄⣤⣶⠛⠁⠀⠀⠀⠀⠀⢸⣦⣶
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⠇⠀⠀⠀⠀⠐⣇⣤⡀⠀⢿⣿⣷⠓⢺⡃⠳⣆⡀⢀⣀⣹⣿⣿⣿⣴⣶⣧⣤⡀⠀⠀⠀⠀⠰⣿⣿⡟
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⣀⠀⠀⠈⠓⠒⠦⣾⣿⣶⣿⡏Italy⣿⣮⣿⡷⣏⠈⢁⣀⣿⣿⣿⠿⠿⢿⣿⣿⣿⣯⠑⠖⠦⡀⢹⣿⣷
North Atlantic Ocean⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢁⡎⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⡇⣿⣿⣿⣶⡄⣭⣿⣿⠞⢍⣹⣿⠕⠚⠈⠁⠀⠀⠀⠀⠉⠈⠉⠉⢯⣻⡋⡉⣼⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧Spain⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⠛⣯⣿⣿⣿⡄⢠⣿⣿⡀⠀⠀Turkey⠀⠀⣀⢸⡈⠋⠛⠿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠐⠶⢶⠛⠋⠉⠁⠀⠁⠀⡇⠐⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⢿⣷⣶⣴⣶⣴⣾⣷⠓⠑⠊⢹⠁⠉⠧⡄⠀⠀⠈
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠘⡄⠀⠀⠀Tunisia⢿⣿⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⢇⣠⠔⠊⠀⠀⠸⡀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿Morocco⠁⠀⠀⠀⠀⠀⠀⠱⡔⠁⠀⠀⠛⠿⢿⠇⠀⠀⠩⡋⠙⠻⠛⠙⠛⢻⢿⠱⡒⠑⠢⢄⡀⠀⠈⣆⡀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⡔⠚⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡆⠀⠀⠀⠀⠠⢰⡓⠋⠀⠀⠀⠀⠈⠒⠪⢽⣿⣄
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⣠⠶⠾⠗⠤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡇⠀⠀⠀Libya⠀⠀⡇⠀⠀⠀⠀⠀Saudi Arabia⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠉⣤⡻⠀⠀⠀⢸⠉⠒⢄⡀⠀⠀⠀⠀⠀⠀⠀⢑⡢⢄⢀⡠⣀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⢼⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠛
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿Mauritania⠀⠈⠒⣄⠀⠀⢀⡠⠒⠁⠀⠀⠉⣆⠀⠉⠒⠤⣀⠀⡗⠒⠒⠒⠚⠒⠒⠒⢻⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠈⠓⡖⠁⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⡏⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣧⡀⡀⠀⠀⡤⠤⠒
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠗⠒⠢⢄⣄⡠⠤⠤⠇⠀⠀⣀⣀⣀⣠⠃⠀⠀⠀⠀⠀⠀⡔⠁⠀⠀⠀⠀⢠⠇⠀⠀⠀⠀⠀⠀⠀⠀⡎⡀⠻⢿⣿⠉⠉⠉⠁⠀⣀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣖⣆⣸⣄Burkina Faso⠤⠤⠤⠤⠞⣤⠀⠀⠀⠀⢰⡅⠀⠀⠀⠀⠀⠀⢀⠀⢠⠋⠈⠉⠱⣹⣦⣤⣶⣶⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡁⡠⢍⠈⣧⠴⢯⣀⡖⠒⣲⡍⢸⠀⠀⠀⠀⠀⠀Africa⡰⠫⣀⠤⣀⣀⡤⡠Ethiopia⡙⠋⠉⠀⡆⣼
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣥⡸⠢⡞⠀⠀⢠⠃⠀⢹⡇⡇⠀⠀⠀⠀⣀⣰⠁⢑⠦⠖⠊⠉⠀⠈⠙⢄⡀⠀⠀⠀⠐⢇⠀⠀⠀⠀⠀⠀⠈⠉⡲⠊⣰⣿
⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿Liberia⣦⣧⣴⣾⣿⣿⣷⣄⣤⣜⠀⠁⠀⢹⡀⢀⡠⠢⢄⡤⠤⠞⠗⡤⢄⣀⣀⣠⠷⢄⠀⢀⣀⣠⠤⠔⠁⣰⣿⣿
⠁⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡖⢤⡤⠼⠁⡇⠀⠀⠀⠀⠀⠀⠀⠀⡇⠁⢘Kenya⠀⣀⣤⣾⣿⣿⣿
⠀⠉⠙⠛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿Gabon⢀⠜⠀⠀⠀⠀⠀⠀⠀⠀⣮⣤⣾⢧⣀⠀⠀⠀⢇⣼⣿⣿⣿⣿⣿⣿
⠀⠀⠀⠀⠀⠈⠈⠉⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡿⣉⣁⡸⠀⠀⠀⠀⠀⠀⠀⠀⠘⣾⠋⠀⠀⠈⠙⠦⣸⣿⣿⣿⣿⣿⣿⣿⣿
```

**Europe**, `worldmap(center = (10.0, 50.0), zoom = 4)`:

```
⣿⣿⣿⣿⣿⡟⠀Netherlands⠀⠉⣇⣀⡠⠋⠑⣦⠀⠈⢆⠈⠑⣱⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠀⠀⠀⠀⢰⡁⠀⠀⠀⠈⠉⠛⠑⠋⠀⠀⠀⠀⣇⡀⠀⠀⠀⠀⠀⢹⠀⠀⠀
⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠔⠁⠀⠀⠀⠀⣽⣄⠖⠞⠀⠀⠙⢦⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⠃⠀⠀⠀⠀⠀⠈⢆⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠅⠀⠀⠀⠀⠀⢸⡀⠀⠀
⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡤⣠⣀⠬⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠧⡄⠀⠀⠀⠀⠀⢹⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠑⠒⢄⡤⠀⠀⠀⠀⠀⠀⠀⡜⠀⠀⠀⠀⠀⠀⠀⠩⢧⡀
⡿⠧⣏⡧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢳⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣥⡀⠀⠀⠀⣀⢈⣆⣀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡠⡠⣠⠃⠀⠀⠀⠀⠀⠀⠀⠘⡄⠀⠀⠀⠀⠀⡔⠉⠦⠋
⠦⠤⣨⢝⣂⡤⢦⣲⣰⡄⠀⠀⠀⠀⠀⢱⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡖⠴⠃⢐⡇⣠⠤⠶⠁⠉⠀⢹⣀⣀⠀⠀⠀⠀⢸⠉⠁⠀⠀⠀⣗⣠⡀⠀⢀⠖⠙⠊⠉⠣⣄⠤⠔⠤⠊⠀⠀⠀⠀
⠖⠲⠤⠔⠃⠁⠀⠀⠀⠙⠒⠲⢄⣀⢰⡉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠞⡅⠀⠀⠀⠈⠙Germany⠀⠠⡕⠀⠀⠀⣯⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠀⠀⠀⠀⠀⢱⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣎⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⢸⠉⠀⠀⠀⠀⠀⠀⢀⡬⠇⠀⠀⠀⠀⠀⠀⠉⠙⠤⢄⣈⠖⠦⡀⠀⠀Dresden⠴⡄⢀⢧⢤⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢪⣄⣞⡀⠀⠀⠀⠀⠀⠀⢀⣠⠟⠱⣰⠙⠉⠀⠀⠀⠀⠀⠀⠀⢰⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠊⠁⠀⠀⠀⠀⢀⣀⡤⠤⠋⡵⠟⠞⠚⠀⠳⢤⢄⡀⠀⠀⠀
⣀⠀⠀Belgium⠀⠀⠀⠀⠀⣷⡀⠀⠀⣠⠴⠒⠃⠀⠀⢀⡽⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢻⢄⡀⠀⠀⠀⠀⢀⡀⠀⠀⣠⠔⠃⠀⠀⠀⣀⡠⠒⠃⠀⠀⠀⠈⢆⣀⡠⠲⣄⣀⣈⡆⠈⠛⠊⣣
⠈⡧⠤⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡷⠖⠾⠍⠀⠀⠀⠀⠀⠘⣆⠀⠀⠀⠀⠀⠀⠀⠀⣰⠒⠁⠀⠙⢤⢴⡲⠴⡵⠙⠒⠒⠳⣄⢠⠖⠊⠑⠳⢤⠀⠀⠀⢠⠤⠤⠋⠁⠀⠀⢼⣀⠁⠀⠀⠀⠸⢆
⣀⣀⣀⡸⡅⠀⢠⢲⠆⠀⠀⠀⠀⢠⠖⡏⠀⠀⠀⠀⠀⠀⠀⠀⢠Frankfurt⠟⠁⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀⠀⢹⡃⠀⠀⠀⢀⢸⢤⡖⠉⠁⠀⡴⠒⢢⠀⠀⠀⢸⠤⠴⠖⠦⣀⡠
⠀⠀⠈⠙⢲⠒⠉⢘⠄⠀Luxembourg⠀⠀⠀⠀⠀⠉⠁⠸⡀⠀⠀⢸⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡢⠖⠒⠁⠉⠀⠈⢑⠄⠀⠘⠉⠉⠀⠀⠀⠈⣖⣀⠀⠀⠁⠀
⠀⠀⠀⡠⠃⠀⠀⠈⠉⢱⣢⡀⠈⢳⠀⠀⢠⠃⢀⣀⣀⢀⠀⠀⠀⠀⠀⠰⡋⣀⠀⢀⣇⡿⠉⠓⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣇⠀⠀⠀⠀⠀⠀⣞⠀⠀⠀⠀⠀Czechia⠒⠢⣀
⠀⢀⣀⡮⠀⠀⠀⠀⠀⡏⠁⠛⠋⠙⠦⠒⠟⢍⠁⠀⠀⢹⡀⠀⠀⠀⠀⠀⢽⠉⢵⠞⠃⠀⠀⠀⠙⢺⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀⠀⠀⢸⠒⠉⠉⠉⠉⠁⡇⠀⠀⠀⠀⠀⠀⠀⢺
⢀⣧⠀⠀⠀⠀⠀⠀⢰⠃⠀⠀⠀⠀⠀⠀⠀⠈⢆⡤⣄⢰⣁⠀⠀⠀⠀⢀⠏⠀⠀⠀⠀⠀⠀⠀⠀⠘⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠣⡀⠀⠀⡞⠀⠀⠀⠀⠀⠀⠑⠲⢢⣀⠀⠀⠀⢸⠁
⡸⠂⠀⠀⠀⠀⠀⠀⣸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡟⠫⠤⡝⠒⠢⢤⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠣⣾⠀⠀⠀⠀⠀⠀⠀⢔⢄⠤⢼⠥⠒⠒⠋⠀
⠃⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢳⠀⠀⠀⡠⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣸⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢱⢄⡀⠀⠀⠀⡔⠎⠀⠀⠀⠉⠙⠤⠤⠴
⠃⠀⠀⠀⠀⠀⠀⠀⠈⠑⢤⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠞⠀⠀⡸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡠⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠒⠞⠀⠑⠒⠊⠙⠓⡄⠀⠀⠀⠀⠀⠀⠀⠀
⢢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠓⢄⠀⠀⠀⠀⠀⠀⠀⢘⠆⠀⢀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠱⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠔⠊⠀⠀⠀⠀⠀⢠⣀⣀⣱⠀⠀⠀⠀Vien
⠈⠉⣆⠀⡀⢀⣠⣄⠀⠀⠀⠀⠘⣄⣀⡀⢀⠀⠀⢀⠜⠀⠀⢎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⠀⠀Munich⠀⠀⠀⠐⣅⢄⣀⡀⠀⠀⠀⠀⠀⠼⡈⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉
⠀⠀⠈⠉⠉⠁⠀⠈⣵⠀⠀⠀⢠⠊⠁⠈⠁⠉⠑⠼⡀⠀⠀⡏⠀⠀⠀⠀⣠⣤⡀⢀⢄⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⢨⠂⠈⢦⡄⢀⡀⠀⠀⠀⣈⣇⣀⠤⠤⣀⡀⠀⠀⠀⡎
⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠶⡿⠉⠀⠀⠀⠀⠀⠀⠀⣪⡀⢠⡵⠤⠤⠔⠲⠟⠏⠉⠋⠙⠻⢶⣶⣭⡙⠀⢠⡠⣀⡀⠀⠀⣀⡤⠴⠒⠚⠉⠓⡝⡎⢽⠀⠀Austria⠀⠀⠀⠀⠀⠘⢦⣀⠀⡝
```

## Interactive viewer

`explore` opens a full-screen live map. Pan with the arrow keys (or `hjkl`),
zoom with `+`/`-`, and quit with `q`. Tiles are cached, so revisiting an area is
instant. The pin stays anchored to the starting location as you pan, so you can
see where you began (and it scrolls off-screen once you pan past it).

```julia
explore(center = (13.42, 52.51), zoom = 12)
```

## How it works

The pipeline mirrors mapscii's, built from reusable pieces:

| Stage | File | Notes |
|-------|------|-------|
| Tile coordinate math | (uses [`MapTiles.jl`](https://github.com/JuliaGeo/MapTiles.jl)) | slippy-map ↔ lon/lat |
| Fetch `.pbf` tiles + cache | `src/tilesource.jl` | HTTP via `Downloads`, OpenFreeMap by default |
| Decode MVT protobuf + geometry | `src/mvt.jl` | `ProtoBuf.jl` bindings + command-stream decoder |
| Parse Mapbox GL style | `src/style.jl` | filters compiled to predicates |
| Braille drawing primitives | `src/canvas.jl` | on [`UnicodePlots.jl`](https://github.com/JuliaPlots/UnicodePlots.jl)'s `BrailleCanvas`; adds polygon fill + labels |
| Renderer | `src/render.jl` | visible tiles, scaling, draw order, label placement + budget |

## Tile source

By default it resolves [OpenFreeMap](https://openfreemap.org)'s current tile URL
from its TileJSON (`https://tiles.openfreemap.org/planet`) — free, no API key,
[OpenMapTiles](https://openmaptiles.org/schema/) schema. Point it elsewhere with:

```julia
src = TileSource("https://your.server/{z}/{x}/{y}.pbf")
worldmap(center = (2.35, 48.85), zoom = 10, source = src)
```

Reuse one `TileSource` across calls to benefit from its in-memory tile cache.

## Labels

Country, city, place, water and street names are drawn on top of the map. A
terminal has room for far fewer labels than a pixel map, so the renderer keeps a
budget — roughly one label per 250 character cells — and spends it on the most
important candidates first. Style layer order decides between kinds:

> countries → cities → villages/suburbs → oceans, seas and bays → major roads →
> minor roads → lakes, rivers and ponds

and within a kind it is the place's OpenMapTiles `rank`, or for a road the length
of its visible stretch. Overlapping and repeated labels are dropped. (Small water
bodies come last because OpenMapTiles gives an ornamental fountain the same
`class` as a real lake, and on a terminal-sized map a street name is worth more.)

A line feature — a street, or a long lake — is labelled at the midpoint of its
longest *visible* stretch, so the text lands on the part you can actually see.

Because the budget follows the size of your terminal rather than the zoom level,
a view stays about equally busy whether you are looking at a continent or a city
block. Override it with `max_labels`:

```julia
worldmap(center = (13.42, 52.51), zoom = 15)                   # auto budget
worldmap(center = (13.42, 52.51), zoom = 15, max_labels = 5)   # just the headline streets
worldmap(center = (13.42, 52.51), zoom = 15, max_labels = 0)   # none at all
```

Street names come from the `transportation_name` source layer, which the tile
server only ships from zoom 6 up — and the smaller the road, the later it enters
the tiles — so they fill in as you zoom.

## Color schemes

Two bundled themes (OpenMapTiles schema): `:dark` (default) and `:light`. The
land is filled with the theme's background color, so areas without roads read as
land rather than empty terminal.

```julia
worldmap(center = (13.42, 52.51), zoom = 6, style = :light)
worldmap(center = (13.42, 52.51), zoom = 6, style = :dark)   # default
```

Or supply your own Mapbox GL style JSON:

```julia
worldmap(center = (0.0, 0.0), zoom = 3, style = load_style("mystyle.json"))
```

## Status / roadmap

v1 renders a single static frame. Not yet implemented (deferred):
interactivity (pan/zoom keys), MBTiles/local sources, spatial indexing,
zoom-dependent paint interpolation, label clustering.

## License

MIT.
