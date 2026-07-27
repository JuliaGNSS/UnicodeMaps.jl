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

"Total map width/height in pixels at (possibly fractional) zoom `z`."
world_px(z) = TILE_PIXELS * 2.0^z

"Wrap a longitude into [-180, 180)."
wrap_lon(lon) = mod(lon + 180.0, 360.0) - 180.0

# Web-mercator y as a fraction of the whole map (0 at north edge, 1 at south).
merc_yfraction(lat) = (1 - asinh(tan(deg2rad(clamp(lat, -85.0511, 85.0511)))) / pi) / 2

"""
    marker_pixel(clon, clat, mlon, mlat, z, W, H) -> (x, y)

Screen pixel of geographic point `(mlon, mlat)` in a `W×H` pixel view centered on
`(clon, clat)` at zoom `z`. The view center maps to `(W/2, H/2)`.
"""
function marker_pixel(clon, clat, mlon, mlat, z, W, H)
    wp = world_px(z)
    x = W / 2 + wrap_lon(mlon - clon) / 360 * wp
    y = H / 2 + (merc_yfraction(mlat) - merc_yfraction(clat)) * wp
    return (round(Int, x), round(Int, y))
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

segment_length(p, q) = hypot(q[1] - p[1], q[2] - p[2])

onscreen(p, width, height) = 0 <= p[1] < width && 0 <= p[2] < height

# Walk `pts[i:j]` and return the point `target` pixels along it.
function point_at_length(pts, i, j, target)
    acc = 0.0
    for k in i:(j - 1)
        d = segment_length(pts[k], pts[k+1])
        if acc + d >= target
            t = d == 0 ? 0.0 : (target - acc) / d
            return (round(Int, pts[k][1] + t * (pts[k+1][1] - pts[k][1])),
                    round(Int, pts[k][2] + t * (pts[k+1][2] - pts[k][2])))
        end
        acc += d
    end
    return pts[j]
end

"""
    line_label_anchor(pts, width, height) -> Union{Tuple{Int,Int,Float64},Nothing}

Where to put a line feature's label, plus how much of the line is on screen:
the halfway point of the longest run of consecutive on-screen vertices, and that
run's length in pixels. Anchoring on the longest *visible* stretch keeps a street
name on the part of the road the viewer can actually see, instead of at whichever
end of the geometry came first — and gives it the most room before it runs off
the edge. The length doubles as an importance score: a road crossing the whole
view matters more than a stub poking into a corner. `nothing` if no vertex is on
screen.
"""
function line_label_anchor(pts, width, height)
    n = length(pts)
    best = nothing        # index range of the longest visible run
    bestlen = -1.0
    i = 1
    while i <= n
        if !onscreen(pts[i], width, height)
            i += 1
            continue
        end
        j = i
        while j < n && onscreen(pts[j+1], width, height)
            j += 1
        end
        len = sum(k -> segment_length(pts[k], pts[k+1]), i:(j - 1); init = 0.0)
        if len > bestlen
            bestlen = len
            best = (i, j)
        end
        i = j + 1
    end
    best === nothing && return nothing
    x, y = point_at_length(pts, best[1], best[2], bestlen / 2)
    return (x, y, bestlen)
end

"""
    LabelCandidate

A label the renderer may draw, with the two keys that decide who wins when they
compete: `layer` (index into the style's layer list — earlier layer = more
important, so countries beat cities beat street names) and `rank` (importance
*within* a layer, lower first).
"""
struct LabelCandidate
    text::String
    x::Int              # anchor, in screen pixels
    y::Int
    color::ColorU
    layer::Int
    rank::Float64
end

# Sort key: style layer order first, then per-feature importance.
label_priority(l::LabelCandidate) = (l.layer, l.rank)

# Importance of a point feature within its layer. OpenMapTiles ranks places
# 1..n (1 = most prominent); layers without a rank fall back to a tie.
function point_rank(props)
    r = get(props, "rank", nothing)
    r isa Number && return Float64(r)
    return 0.0
end

# How many labels a canvas of `cw`x`ch` characters can carry before it reads as
# soup rather than a map. Purely a function of available room — one label per
# this many character cells — so the same view stays equally legible at any zoom
# and the budget grows with the terminal.
const CELLS_PER_LABEL = 250

label_budget(cw, ch) = clamp((cw * ch) ÷ CELLS_PER_LABEL, 3, 60)

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

# Google Maps' pin red.
const MARKER_COLOR = rgb(0xea, 0x43, 0x35)

"""
    render(center, zoom; size, style, source, maxzoom, marker, marker_color, max_labels) -> MapCanvas

Fetch, style, and draw the map for `center = (lon, lat)` at `zoom`, returning the
filled `MapCanvas`. `size = (chars_wide, chars_high)`.

`marker` controls the pin: `true` anchors it on `center`, `false` disables it, and
a `(lon, lat)` tuple anchors it at that geographic point (so it stays fixed on the
map while `center` pans, scrolling off-screen when out of view).

`max_labels` caps how many labels are drawn; `nothing` (the default) scales the cap
to the canvas size. The most important candidates are kept — see [`LabelCandidate`](@ref).
"""
function render(
        center::Tuple{<:Real,<:Real},
        zoom::Real;
        size::Tuple{Integer,Integer} = (120, 50),
        style::Union{Style,Symbol} = default_style(),
        source::TileSource = TileSource(),
        maxzoom::Integer = 14,
        marker::Union{Bool,Tuple{<:Real,<:Real}} = true,
        marker_color::ColorU = MARKER_COLOR,
        max_labels::Union{Nothing,Integer} = nothing,
    )
    style = style isa Symbol ? theme(style) : style
    lon, lat = center
    cw, ch = size
    bg = style.background === nothing ? NO_COLOR : style.background
    mc = MapCanvas(cw, ch; background = bg)
    z = clamp(floor(Int, zoom), 0, maxzoom)
    tilesize = TILE_PIXELS * 2.0^(zoom - z)

    tiles = visible_tiles(lon, lat, zoom, z, tilesize, mc.width, mc.height)
    fetched = [(t, get_tile(source, t.z, t.x, t.y)) for t in tiles]

    labels = LabelCandidate[]

    for (li, ls) in enumerate(style.layers)
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
                    if f.geomtype == :linestring
                        # One label per path, on its longest visible stretch;
                        # the longer that stretch, the more the road matters.
                        for p in f.geometry
                            pts = scale_path(p, t.px, t.py, scale)
                            isempty(pts) && continue
                            anchor = line_label_anchor(pts, mc.width, mc.height)
                            anchor === nothing && continue
                            x, y, len = anchor
                            push!(labels, LabelCandidate(txt, x, y, ls.color, li, -len))
                        end
                    else
                        rank = point_rank(props)
                        for p in f.geometry, (x, y) in scale_path(p, t.px, t.py, scale)
                            push!(labels, LabelCandidate(txt, x, y, ls.color, li, rank))
                        end
                    end
                end
            end
        end
    end

    # Place labels last so they sit on top. Most important first, so when the
    # budget runs out or two labels collide it is the lesser one that is dropped.
    sort!(labels; by = label_priority, alg = MergeSort)
    budget = max_labels === nothing ? label_budget(cw, ch) : Int(max_labels)
    lb = LabelBuffer()
    placed = 0
    for l in labels
        placed >= budget && break
        (0 <= l.x < mc.width && 0 <= l.y < mc.height) || continue
        cx, cy = UP.pixel_to_char_point(mc.canvas, l.x, l.y)
        startx = cx - length(l.text) ÷ 2  # roughly center the label on its point
        if place_label!(lb, l.text, startx, cy, 1)
            draw_text!(mc, l.text, max(0, (startx - 1) * 2), l.y, l.color)
            placed += 1
        end
    end

    # Pin anchored to a geographic point (defaults to the view center), on top.
    mpos = marker === true ? center : (marker === false ? nothing : marker)
    if mpos !== nothing
        mx, my = marker_pixel(lon, lat, mpos[1], mpos[2], zoom, mc.width, mc.height)
        if 0 <= mx < mc.width && 0 <= my < mc.height
            draw_marker!(mc, mx, my, marker_color)
        end
    end

    return mc
end
