# Minimal interactive viewer: arrow-key / hjkl panning and +/- zooming, built as
# an input loop around the stateless `render`. Tiles are cached by the
# `TileSource`, so revisiting an area is instant.

import REPL

# --- terminal escape sequences ---
const ALT_SCREEN_ON  = "\e[?1049h"
const ALT_SCREEN_OFF = "\e[?1049l"
const HIDE_CURSOR    = "\e[?25l"
const SHOW_CURSOR    = "\e[?25h"
const CURSOR_HOME    = "\e[H"
const CLEAR_EOL      = "\e[K"
const DIM            = "\e[2m"
const RESET_SGR      = "\e[0m"

# --- pure pan/zoom math (unit-tested) ---
# `world_px` and `wrap_lon` are defined in render.jl.

"""
    pan_center(lon, lat, z, wchars, hchars, fx, fy) -> (lon, lat)

Shift the center by `fx`/`fy` fractions of the visible view (width `wchars`,
height `hchars` characters; 2×4 pixels per character) at zoom `z`. Positive `fx`
moves east, positive `fy` moves south.
"""
function pan_center(lon, lat, z, wchars, hchars, fx, fy)
    wp = world_px(z)
    lon_new = wrap_lon(lon + fx * (2 * wchars) / wp * 360.0)
    yf = (1 - asinh(tan(deg2rad(clamp(lat, -85.0, 85.0)))) / pi) / 2
    yf = clamp(yf + fy * (4 * hchars) / wp, 0.0, 1.0)
    lat_new = rad2deg(atan(sinh(pi * (1 - 2 * yf))))
    return (lon_new, lat_new)
end

"""
    read_key(io) -> Symbol or Char

Read one keystroke, decoding arrow keys (`\\e[A`…/`\\eO`…) to
`:up`/`:down`/`:left`/`:right`, `Ctrl-C` to `:quit`, a lone `Esc` to `:esc`, and
end-of-input to `:eof`. Any other key is returned as a `Char`.
"""
function read_key(io::IO)
    b = try
        read(io, UInt8)
    catch
        return :eof
    end
    if b == 0x1b  # ESC — possibly an arrow-key sequence
        bytesavailable(io) == 0 && return :esc
        b2 = read(io, UInt8)
        if b2 == UInt8('[') || b2 == UInt8('O')
            bytesavailable(io) == 0 && return :esc
            b3 = read(io, UInt8)
            b3 == UInt8('A') && return :up
            b3 == UInt8('B') && return :down
            b3 == UInt8('C') && return :right
            b3 == UInt8('D') && return :left
            return :other
        end
        return :esc
    elseif b == 0x03  # Ctrl-C
        return :quit
    else
        return Char(b)
    end
end

# --- the interactive loop ---

function terminal_size()
    rows, cols = displaysize(stdout)
    return (max(20, cols), max(10, rows))
end

function status_line(lon, lat, z, width)
    coords = "lat $(round(lat, digits = 4))  lon $(round(lon, digits = 4))  z $(round(z, digits = 1))"
    text = " $coords    ←↑↓→/hjkl pan · +/- zoom · q quit"
    return length(text) > width ? text[1:width] : text
end

"""
    explore(; center, zoom, style, source, maxzoom, marker, marker_color,
              max_labels, pan_fraction, zoom_step, min_zoom, max_zoom)

Open an interactive full-screen map. Pan with the arrow keys or `hjkl`, zoom with
`+`/`-`, and quit with `q` (or `Esc`). Returns the final `(; center, zoom)`.

Reuse a `source` across sessions to keep its tile cache warm.
"""
function explore(;
        center::Tuple{<:Real,<:Real} = (0.0, 0.0),
        zoom::Real = 3,
        style::Union{Style,Symbol} = :dark,
        source::TileSource = TileSource(),
        maxzoom::Integer = 14,
        marker::Bool = true,
        marker_color::ColorU = MARKER_COLOR,
        max_labels::Union{Nothing,Integer} = nothing,
        pan_fraction::Real = 0.25,
        zoom_step::Real = 0.5,
        min_zoom::Real = 0.0,
        max_zoom::Real = 19.0,
    )
    lon, lat = float(center[1]), float(center[2])
    z = float(zoom)
    # Anchor the pin to the starting location so it stays put while panning.
    pin = marker ? (lon, lat) : false
    term = REPL.Terminals.TTYTerminal(get(ENV, "TERM", "xterm"), stdin, stdout, stderr)
    print(stdout, ALT_SCREEN_ON, HIDE_CURSOR)
    REPL.Terminals.raw!(term, true)
    try
        while true
            w, h = terminal_size()
            mc = render((lon, lat), z; size = (w, h - 1), style, source, maxzoom,
                        marker = pin, marker_color, max_labels)
            print(stdout, CURSOR_HOME, frame(mc), "\n", DIM, status_line(lon, lat, z, w), CLEAR_EOL, RESET_SGR)
            flush(stdout)

            k = read_key(stdin)
            if k in (:quit, :eof, :esc, 'q', 'Q')
                break
            elseif k === :up || k == 'k'
                lon, lat = pan_center(lon, lat, z, w, h, 0.0, -pan_fraction)
            elseif k === :down || k == 'j'
                lon, lat = pan_center(lon, lat, z, w, h, 0.0, pan_fraction)
            elseif k === :left || k == 'h'
                lon, lat = pan_center(lon, lat, z, w, h, -pan_fraction, 0.0)
            elseif k === :right || k == 'l'
                lon, lat = pan_center(lon, lat, z, w, h, pan_fraction, 0.0)
            elseif k in ('+', '=')
                z = min(z + zoom_step, max_zoom)
            elseif k in ('-', '_')
                z = max(z - zoom_step, min_zoom)
            end
        end
    finally
        REPL.Terminals.raw!(term, false)
        print(stdout, SHOW_CURSOR, ALT_SCREEN_OFF)
        flush(stdout)
    end
    return (; center = (lon, lat), zoom = z)
end
