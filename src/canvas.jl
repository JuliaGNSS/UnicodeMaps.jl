# Drawing primitives on top of UnicodePlots' BrailleCanvas.
#
# We reuse BrailleCanvas for its 4x2 braille grid, 24-bit color model and pixel!
# plumbing, and add the two things it lacks for map rendering: filled polygons
# (scanline even-odd fill) and text-label placement (overwriting grid cells).
#
# Coordinates here are integer *screen pixels* with a top-left origin and y
# increasing downward — matching how tile geometry is scaled in the renderer.

import UnicodePlots as UP

const ColorU = UInt32

"Pack 8-bit r,g,b into a 24-bit UnicodePlots color (rendered as truecolor)."
@inline rgb(r::Integer, g::Integer, b::Integer)::ColorU =
    (UInt32(r & 0xff) << 16) | (UInt32(g & 0xff) << 8) | UInt32(b & 0xff)

"Parse a CSS hex color (`#rgb` or `#rrggbb`) into an (r,g,b) tuple."
function hex2rgb(s::AbstractString)
    (startswith(s, "#") && (length(s) == 4 || length(s) == 7)) ||
        throw(ArgumentError("unsupported hex color: $s"))
    hex = s[2:end]
    if length(hex) == 3
        return (
            parse(Int, hex[1] * hex[1]; base = 16),
            parse(Int, hex[2] * hex[2]; base = 16),
            parse(Int, hex[3] * hex[3]; base = 16),
        )
    else
        return (
            parse(Int, hex[1:2]; base = 16),
            parse(Int, hex[3:4]; base = 16),
            parse(Int, hex[5:6]; base = 16),
        )
    end
end

hex_color(s::AbstractString)::ColorU = rgb(hex2rgb(s)...)

"""
    MapCanvas(char_width, char_height)

A braille drawing surface `char_width` × `char_height` characters, i.e.
`2*char_width` × `4*char_height` pixels.
"""
struct MapCanvas
    canvas::UP.BrailleCanvas
    width::Int   # pixel width
    height::Int  # pixel height
end

function MapCanvas(char_width::Integer, char_height::Integer)
    canvas = UP.BrailleCanvas(char_height, char_width; blend = false)
    return MapCanvas(canvas, UP.pixel_width(canvas), UP.pixel_height(canvas))
end

@inline inbounds(mc::MapCanvas, x::Integer, y::Integer) =
    0 <= x < mc.width && 0 <= y < mc.height

@inline function set_pixel!(mc::MapCanvas, x::Integer, y::Integer, color::ColorU)
    inbounds(mc, x, y) && UP.pixel!(mc.canvas, x, y, color, false)
    return mc
end

"Integer Bresenham line."
function draw_line!(mc::MapCanvas, x0::Integer, y0::Integer, x1::Integer, y1::Integer, color::ColorU)
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = x0 < x1 ? 1 : -1
    sy = y0 < y1 ? 1 : -1
    err = dx + dy
    while true
        set_pixel!(mc, x0, y0, color)
        (x0 == x1 && y0 == y1) && break
        e2 = 2err
        if e2 >= dy
            err += dy
            x0 += sx
        end
        if e2 <= dx
            err += dx
            y0 += sy
        end
    end
    return mc
end

"""
    draw_polyline!(mc, pts, color; width=1)

Draw a connected polyline through `pts` (`Vector{Tuple{Int,Int}}`, screen pixels).
`width > 1` thickens the line cheaply by drawing 1-pixel x/y offset copies.
"""
function draw_polyline!(mc::MapCanvas, pts, color::ColorU; width::Integer = 1)
    offsets = width <= 1 ? ((0, 0),) : ((0, 0), (1, 0), (0, 1))
    for (ox, oy) in offsets
        for i in 2:length(pts)
            x0, y0 = pts[i-1]
            x1, y1 = pts[i]
            draw_line!(mc, x0 + ox, y0 + oy, x1 + ox, y1 + oy, color)
        end
    end
    return mc
end

"""
    fill_polygon!(mc, rings, color)

Fill a polygon given as one or more `rings` (each a `Vector{Tuple{Int,Int}}` in
screen pixels) using scanline fill with the even-odd rule, so interior holes are
left unfilled automatically. Rings need not be explicitly closed.
"""
function fill_polygon!(mc::MapCanvas, rings, color::ColorU)
    isempty(rings) && return mc
    ymin, ymax = typemax(Int), typemin(Int)
    for ring in rings, (_, y) in ring
        ymin = min(ymin, y)
        ymax = max(ymax, y)
    end
    ymin = max(ymin, 0)
    ymax = min(ymax, mc.height - 1)
    xs = Float64[]
    for y in ymin:ymax
        yc = y + 0.5
        empty!(xs)
        for ring in rings
            n = length(ring)
            n < 2 && continue
            for i in 1:n
                x1, y1 = ring[i]
                x2, y2 = ring[i == n ? 1 : i + 1]  # wrap to close the ring
                y1 == y2 && continue
                if (y1 <= yc) != (y2 <= yc)
                    push!(xs, x1 + (yc - y1) / (y2 - y1) * (x2 - x1))
                end
            end
        end
        sort!(xs)
        for k in 1:2:length(xs)-1
            xl = max(0, ceil(Int, xs[k]))
            xr = min(mc.width - 1, floor(Int, xs[k+1]))
            for x in xl:xr
                set_pixel!(mc, x, y, color)
            end
        end
    end
    return mc
end

# Points evenly spaced around a circle (screen pixels), for use as a fill ring.
circle_ring(cx, cy, r) =
    [(round(Int, cx + r * cos(a)), round(Int, cy + r * sin(a)))
     for a in range(0, 2π; length = 37)]

"""
    draw_marker!(mc, x, y, color; radius, height, hole)

Draw a Google-Maps-style pin whose **tip points exactly at** screen pixel
`(x, y)`: a round head of `radius` sitting `height` pixels above the tip, a
tapered stem down to the tip, and a small punched-out `hole` in the head.
"""
function draw_marker!(
        mc::MapCanvas, x::Integer, y::Integer, color::ColorU;
        radius::Integer = 3, height::Integer = 9,
        hole::ColorU = rgb(0x0a, 0x0e, 0x14),
    )
    hcx, hcy = x, y - height
    fill_polygon!(mc, [[(hcx - radius, hcy), (hcx + radius, hcy), (x, y)]], color)  # stem
    fill_polygon!(mc, [circle_ring(hcx, hcy, radius)], color)                        # head
    fill_polygon!(mc, [circle_ring(hcx, hcy, max(1, radius ÷ 3))], hole)             # hole
    set_pixel!(mc, x, y, color)  # ensure the exact tip pixel lands on the target
    return mc
end

"""
    draw_text!(mc, text, x, y, color)

Write `text` starting at screen pixel `(x, y)`, one character per braille cell
(cells are 2 pixels wide), overwriting any braille dots there.
"""
function draw_text!(mc::MapCanvas, text::AbstractString, x::Integer, y::Integer, color::ColorU)
    grid = mc.canvas.grid
    colors = mc.canvas.colors
    for (i, ch) in enumerate(text)
        px = x + (i - 1) * 2
        inbounds(mc, px, y) || continue
        cx, cy = UP.pixel_to_char_point(mc.canvas, px, y)
        if checkbounds(Bool, grid, cy, cx)
            grid[cy, cx] = UInt32(ch)
            colors[cy, cx] = color
        end
    end
    return mc
end

"Render the canvas to a string of colored braille/text rows."
function frame(mc::MapCanvas)
    c = mc.canvas
    buf = IOBuffer()
    io = IOContext(buf, :color => true)
    for row in 1:UP.nrows(c)
        for col in 1:UP.ncols(c)
            UP.print_color(io, c.colors[row, col], Char(c.grid[row, col]))
        end
        row < UP.nrows(c) && print(io, '\n')
    end
    return String(take!(buf))
end
