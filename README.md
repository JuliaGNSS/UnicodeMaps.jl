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
instant.

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
| Renderer | `src/render.jl` | visible tiles, scaling, draw order, label placement |

## Tile source

By default it resolves [OpenFreeMap](https://openfreemap.org)'s current tile URL
from its TileJSON (`https://tiles.openfreemap.org/planet`) — free, no API key,
[OpenMapTiles](https://openmaptiles.org/schema/) schema. Point it elsewhere with:

```julia
src = TileSource("https://your.server/{z}/{x}/{y}.pbf")
worldmap(center = (2.35, 48.85), zoom = 10, source = src)
```

Reuse one `TileSource` across calls to benefit from its in-memory tile cache.

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
