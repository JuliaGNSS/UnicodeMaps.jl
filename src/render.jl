# The renderer: given a geographic center, zoom and output size, work out which
# tiles are visible, scale each feature's geometry into screen pixels, and draw
# features in style order. A Julia analogue of mapscii's Renderer.js, simplified
# for static (non-interactive) single-frame output.

import MapTiles

const TILE_PIXELS = 256  # nominal pixels per tile at an integer zoom level

"Fractional slippy-map tile coordinates for a lon/lat at zoom `z`."
function lonlat_to_tile(lon::Real, lat::Real, z::Real)
    n = 2.0^z
    x = (lon + 180.0) / 360.0 * n
    latrad = deg2rad(lat)
    y = (1.0 - asinh(tan(latrad)) / pi) / 2.0 * n
    return (x, y)
end

"Geographic bounding box (WGS84 Extent) of an integer tile — via MapTiles."
tile_extent(z::Integer, x::Integer, y::Integer) =
    MapTiles.extent(MapTiles.Tile(x, y, z), MapTiles.wgs84)

typestr(gt::Symbol) = gt == :polygon ? "Polygon" : gt == :linestring ? "LineString" : "Point"

# Preferred label field, most specific first.
function label_text(props)
    for k in ("name:en", "name_en", "name")
        v = get(props, k, nothing)
        v === nothing || return string(v)
    end
    return nothing
end

# A tile positioned on the screen: wrapped x/y indices and the pixel offset of
# its top-left corner.
struct PlacedTile
    z::Int
    x::Int
    y::Int
    px::Float64
    py::Float64
end

function visible_tiles(lon, lat, zoom, z, tilesize, width, height)
    n = 2^z
    cx, cy = lonlat_to_tile(lon, lat, z)
    x0 = floor(Int, cx - (width / 2) / tilesize) - 1
    x1 = floor(Int, cx + (width / 2) / tilesize) + 1
    y0 = floor(Int, cy - (height / 2) / tilesize) - 1
    y1 = floor(Int, cy + (height / 2) / tilesize) + 1
    tiles = PlacedTile[]
    for ty in y0:y1
        0 <= ty < n || continue
        for tx in x0:x1
            px = width / 2 - (cx - tx) * tilesize
            py = height / 2 - (cy - ty) * tilesize
            push!(tiles, PlacedTile(z, mod(tx, n), ty, px, py))
        end
    end
    return tiles
end

zoom_ok(ls::LayerStyle, zoom) =
    (ls.minzoom === nothing || zoom >= ls.minzoom) &&
    (ls.maxzoom === nothing || zoom <= ls.maxzoom)

# Scale a path of tile-local coords to integer screen pixels, dropping repeated
# points (port of the core of Renderer._scaleAndReduce).
function scale_path(path, px, py, scale)
    out = Tuple{Int,Int}[]
    lastx = typemin(Int)
    lasty = typemin(Int)
    for (x, y) in path
        sx = round(Int, px + x * scale)
        sy = round(Int, py + y * scale)
        (sx == lastx && sy == lasty) && continue
        push!(out, (sx, sy))
        lastx, lasty = sx, sy
    end
    return out
end

# Simple label collision: reject a label whose character-cell bounding box
# overlaps an already-placed one, or whose text was already shown.
struct LabelBuffer
    boxes::Vector{NTuple{4,Int}}
    seen::Set{String}
end
LabelBuffer() = LabelBuffer(NTuple{4,Int}[], Set{String}())

function place_label!(lb::LabelBuffer, text, cx, cy, margin)
    text in lb.seen && return false
    x1 = cx - margin
    y1 = cy - margin
    x2 = cx + length(text) + margin
    y2 = cy + margin
    for (bx1, by1, bx2, by2) in lb.boxes
        (x1 <= bx2 && bx1 <= x2 && y1 <= by2 && by1 <= y2) && return false
    end
    push!(lb.boxes, (x1, y1, x2, y2))
    push!(lb.seen, text)
    return true
end

"""
    render(center, zoom; size, style, source, maxzoom) -> MapCanvas

Fetch, style, and draw the map for `center = (lon, lat)` at `zoom`, returning the
filled `MapCanvas`. `size = (chars_wide, chars_high)`.
"""
function render(
        center::Tuple{<:Real,<:Real},
        zoom::Real;
        size::Tuple{Integer,Integer} = (120, 50),
        style::Style = default_style(),
        source::TileSource = TileSource(),
        maxzoom::Integer = 14,
    )
    lon, lat = center
    cw, ch = size
    mc = MapCanvas(cw, ch)
    z = clamp(floor(Int, zoom), 0, maxzoom)
    tilesize = TILE_PIXELS * 2.0^(zoom - z)

    tiles = visible_tiles(lon, lat, zoom, z, tilesize, mc.width, mc.height)
    fetched = [(t, get_tile(source, t.z, t.x, t.y)) for t in tiles]

    labels = Tuple{String,Int,Int,ColorU}[]  # text, pixel x, pixel y, color

    for ls in style.layers
        zoom_ok(ls, zoom) || continue
        for (t, layers) in fetched
            layer = get(layers, ls.source_layer, nothing)
            layer === nothing && continue
            scale = tilesize / layer.extent
            for f in layer.features
                props = f.properties
                haskey(props, "\$type") || (props["\$type"] = typestr(f.geomtype))
                ls.applies(props) || continue
                if ls.type == :fill
                    rings = [scale_path(p, t.px, t.py, scale) for p in f.geometry]
                    fill_polygon!(mc, rings, ls.color)
                elseif ls.type == :line
                    for p in f.geometry
                        pts = scale_path(p, t.px, t.py, scale)
                        length(pts) >= 2 && draw_polyline!(mc, pts, ls.color; width = ls.line_width)
                    end
                elseif ls.type == :symbol
                    txt = label_text(props)
                    txt === nothing && continue
                    for p in f.geometry, (x, y) in scale_path(p, t.px, t.py, scale)
                        push!(labels, (txt, x, y, ls.color))
                    end
                end
            end
        end
    end

    # Place labels last so they sit on top; skip overlaps.
    lb = LabelBuffer()
    for (txt, x, y, color) in labels
        (0 <= x < mc.width && 0 <= y < mc.height) || continue
        cx, cy = UP.pixel_to_char_point(mc.canvas, x, y)
        startx = cx - length(txt) ÷ 2  # roughly center the label on its point
        if place_label!(lb, txt, startx, cy, 1)
            draw_text!(mc, txt, max(0, (startx - 1) * 2), y, color)
        end
    end

    return mc
end
