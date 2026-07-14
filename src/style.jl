# Minimal Mapbox GL style parser — a Julia port of mapscii's Styler.js.
#
# Compiles each style layer's `filter` into a predicate closure and indexes
# layers by their `source-layer` so the renderer can, for a given tile layer and
# feature, find the matching style (type + color + zoom range). Draw order is the
# order layers appear in the style document (Mapbox convention: later = on top).

import JSON3

# Recursively convert JSON3 values into plain Julia containers for easy access.
to_native(x::JSON3.Object) = Dict{String,Any}(String(k) => to_native(v) for (k, v) in x)
to_native(x::JSON3.Array) = Any[to_native(v) for v in x]
to_native(x) = x

"""
    LayerStyle

One compiled style layer: paint color, geometry `type`, optional zoom range, and
`applies(props)` — a predicate deciding whether a feature is drawn by this layer.
"""
struct LayerStyle
    id::String
    type::Symbol             # :fill | :line | :symbol | :background
    source_layer::String
    minzoom::Union{Nothing,Float64}
    maxzoom::Union{Nothing,Float64}
    color::ColorU
    line_width::Int
    applies::Function        # props::Dict -> Bool
    paint::Dict{String,Any}
end

struct Style
    name::String
    background::Union{Nothing,ColorU}
    layers::Vector{LayerStyle}                    # in draw order
    by_source_layer::Dict{String,Vector{LayerStyle}}
end

# --- color parsing --------------------------------------------------------

const DEFAULT_COLOR = rgb(200, 200, 200)

# A paint color may be a hex string, or a zoom-stops object {base, stops:[[z,val]]}.
# Zoom-dependent stops are simplified to the first stop (as mapscii does).
function parse_color(x, default::ColorU)::ColorU
    if x isa AbstractString
        startswith(x, "#") ? hex_color(x) : default
    elseif x isa AbstractDict && haskey(x, "stops") && !isempty(x["stops"])
        parse_color(x["stops"][1][2], default)
    else
        default
    end
end

# --- filter compilation ---------------------------------------------------

const TRUE_FILTER = _ -> true

getprop(props, key) = get(props, key, nothing)

function compile_filter(filter)::Function
    (filter === nothing || isempty(filter)) && return TRUE_FILTER
    op = filter[1]
    if op == "all"
        subs = map(compile_filter, filter[2:end])
        return props -> all(f -> f(props), subs)
    elseif op == "any"
        subs = map(compile_filter, filter[2:end])
        return props -> any(f -> f(props), subs)
    elseif op == "none"
        subs = map(compile_filter, filter[2:end])
        return props -> !any(f -> f(props), subs)
    elseif op == "=="
        k, v = filter[2], filter[3]
        return props -> getprop(props, k) == v
    elseif op == "!="
        k, v = filter[2], filter[3]
        return props -> getprop(props, k) != v
    elseif op == "in"
        k = filter[2]
        vals = filter[3:end]
        return props -> getprop(props, k) in vals
    elseif op == "!in"
        k = filter[2]
        vals = filter[3:end]
        return props -> !(getprop(props, k) in vals)
    elseif op == "has"
        k = filter[2]
        return props -> getprop(props, k) !== nothing
    elseif op == "!has"
        k = filter[2]
        return props -> getprop(props, k) === nothing
    elseif op in (">", ">=", "<", "<=")
        k, v = filter[2], filter[3]
        cmp = op == ">" ? (>) : op == ">=" ? (>=) : op == "<" ? (<) : (<=)
        return function (props)
            p = getprop(props, k)
            p === nothing && return false
            try
                return cmp(p, v)
            catch
                return false
            end
        end
    else
        return TRUE_FILTER
    end
end

# --- style construction ---------------------------------------------------

function color_for(type::Symbol, paint::Dict)
    if type == :line
        return parse_color(get(paint, "line-color", nothing), DEFAULT_COLOR)
    elseif type == :fill
        return parse_color(get(paint, "fill-color", nothing), DEFAULT_COLOR)
    elseif type == :symbol
        return parse_color(get(paint, "text-color", nothing), DEFAULT_COLOR)
    else
        return DEFAULT_COLOR
    end
end

function line_width_for(paint::Dict)
    w = get(paint, "line-width", 1)
    w isa Number && return max(1, round(Int, w))
    w isa AbstractDict && haskey(w, "stops") && !isempty(w["stops"]) &&
        return max(1, round(Int, w["stops"][1][2]))
    return 1
end

optional_zoom(layer, key) = haskey(layer, key) ? Float64(layer[key]) : nothing

function Style(doc::AbstractDict)
    name = get(doc, "name", "style")
    raw_layers = get(doc, "layers", Any[])
    layers = LayerStyle[]
    background = nothing
    for layer in raw_layers
        type = Symbol(get(layer, "type", "fill"))
        paint = get(layer, "paint", Dict{String,Any}())
        paint isa AbstractDict || (paint = Dict{String,Any}())
        if type == :background
            background = parse_color(get(paint, "background-color", nothing), rgb(0, 0, 0))
            continue
        end
        push!(layers, LayerStyle(
            get(layer, "id", ""),
            type,
            get(layer, "source-layer", ""),
            optional_zoom(layer, "minzoom"),
            optional_zoom(layer, "maxzoom"),
            color_for(type, paint),
            line_width_for(paint),
            compile_filter(get(layer, "filter", nothing)),
            paint,
        ))
    end
    by_src = Dict{String,Vector{LayerStyle}}()
    for ls in layers
        push!(get!(by_src, ls.source_layer, LayerStyle[]), ls)
    end
    return Style(name, background, layers, by_src)
end

"Parse a Mapbox GL style from a JSON string."
parse_style(json::AbstractString) = Style(to_native(JSON3.read(json)))

"Load a Mapbox GL style from a file path."
load_style(path::AbstractString) = parse_style(read(path, String))

"The bundled OpenMapTiles-schema style."
default_style() = load_style(joinpath(@__DIR__, "styles", "openmaptiles.json"))

"""
    style_for(style, source_layer, props) -> Union{LayerStyle,Nothing}

Return the first style layer (in draw order) whose source-layer matches and whose
filter accepts `props`, or `nothing`.
"""
function style_for(style::Style, source_layer::AbstractString, props)
    candidates = get(style.by_source_layer, source_layer, nothing)
    candidates === nothing && return nothing
    for ls in candidates
        ls.applies(props) && return ls
    end
    return nothing
end
