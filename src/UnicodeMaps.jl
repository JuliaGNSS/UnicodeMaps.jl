"""
    UnicodeMaps

Render OpenStreetMap-derived vector map tiles to the terminal as colored
braille/Unicode art — a Julia take on [mapscii](https://github.com/rastapasta/mapscii).

Quick start:

```julia
using UnicodeMaps
worldmap(center = (13.42, 52.51), zoom = 6)   # Berlin
```
"""
module UnicodeMaps

export worldmap,
    explore,
    render,
    MapImage,
    MapCanvas,
    TileSource,
    Style,
    load_style,
    parse_style,
    theme,
    default_style

include("mvt.jl")
include("canvas.jl")
include("style.jl")
include("tilesource.jl")
include("render.jl")
include("interactive.jl")

"""
    MapImage

A rendered map frame that displays itself as colored terminal art when shown.
Wraps the underlying [`MapCanvas`](@ref).
"""
struct MapImage
    canvas::MapCanvas
end

Base.show(io::IO, ::MIME"text/plain", m::MapImage) = print(io, frame(m.canvas))
Base.show(io::IO, m::MapImage) = print(io, frame(m.canvas))

# Character size to fill the current terminal, leaving a row for the prompt.
function default_display_size()
    rows, cols = displaysize(stdout)
    return (max(20, cols), max(10, rows - 1))
end

"""
    worldmap(; center, zoom, size, style, source, maxzoom) -> MapImage

Render the map centered at `center = (longitude, latitude)` at `zoom`, returning a
[`MapImage`](@ref) that prints as colored braille art.

Keyword arguments:
- `center`: `(lon, lat)` in degrees (default `(0.0, 0.0)`).
- `zoom`: map zoom level, may be fractional (default `2`).
- `size`: `(chars_wide, chars_high)`; defaults to fill the terminal.
- `style`: a color scheme — a theme name (`:dark` or `:light`) or a [`Style`](@ref).
  Defaults to `:dark`. Use [`load_style`](@ref) for a custom Mapbox GL style file.
- `source`: a [`TileSource`](@ref); defaults to OpenFreeMap (network access).
- `maxzoom`: highest tile zoom to request (default `14`).
- `marker`: place a pin on `center` (default `true`).
- `marker_color`: the pin color (default Google-Maps red).
- `max_labels`: how many labels to draw at most; defaults to a budget scaled to
  `size`, keeping the most important ones (countries before cities before streets).

Reuse a single `source` across calls to benefit from its tile cache.
"""
function worldmap(;
        center::Tuple{<:Real,<:Real} = (0.0, 0.0),
        zoom::Real = 2,
        size::Tuple{Integer,Integer} = default_display_size(),
        style::Union{Style,Symbol} = :dark,
        source::TileSource = TileSource(),
        maxzoom::Integer = 14,
        marker::Union{Bool,Tuple{<:Real,<:Real}} = true,
        marker_color::ColorU = MARKER_COLOR,
        max_labels::Union{Nothing,Integer} = nothing,
    )
    return MapImage(render(center, zoom; size, style, source, maxzoom, marker,
                           marker_color, max_labels))
end

end # module UnicodeMaps
