# Mapbox Vector Tile (MVT) decoding.
#
# Wraps the vendored ProtoBuf.jl bindings (`src/vendor/gen/vector_tile/`) and adds
# the geometry-command decoder + feature/property assembly that the raw protobuf
# structs don't provide. This is the "usable format" step: turning a feature's
# `geometry::Vector{UInt32}` command stream into concrete rings/lines/points.
#
# References:
#   MVT spec §4.3 (geometry encoding): https://github.com/mapbox/vector-tile-spec

import ProtoBuf as PB

# The generated module defines `Tile`, `Tile.Layer`, ... — kept in its own module
# so its `Tile` type does not clash with `MapTiles.Tile`.
include("vendor/gen/vector_tile/vector_tile.jl")

const PBTile = vector_tile.Tile
const PBGeomType = vector_tile.var"Tile.GeomType"

# MVT geometry command ids (§4.3.3.1)
const CMD_MOVETO = UInt32(1)
const CMD_LINETO = UInt32(2)
const CMD_CLOSEPATH = UInt32(7)

"""
    VectorFeature

A single decoded feature. `geometry` is a vector of paths (rings for polygons,
line strings for lines, single-point paths for points) in **tile-local integer
coordinates** (0 .. `extent`, origin top-left). `properties` maps attribute names
to their decoded values.
"""
struct VectorFeature
    id::UInt64
    geomtype::Symbol  # :point | :linestring | :polygon | :unknown
    properties::Dict{String,Any}
    geometry::Vector{Vector{Tuple{Int,Int}}}
end

"""
    VectorLayer

A decoded layer: its name, coordinate `extent` (usually 4096) and features.
"""
struct VectorLayer
    name::String
    extent::Int
    features::Vector{VectorFeature}
end

# ZigZag decode (§4.3.2): maps unsigned parameter integers back to signed deltas.
@inline function zigzag(n::UInt32)
    i = Int64(n)
    return (i >> 1) ⊻ (-(i & 1))
end

geomtype_symbol(t) =
    t == PBGeomType.POINT      ? :point :
    t == PBGeomType.LINESTRING ? :linestring :
    t == PBGeomType.POLYGON    ? :polygon : :unknown

"""
    decode_geometry(commands) -> Vector{Vector{Tuple{Int,Int}}}

Decode an MVT geometry command stream into paths of absolute tile coordinates.
A `MoveTo` starts a new path; `LineTo` extends the current path; `ClosePath`
appends the path's first vertex to close a ring.
"""
function decode_geometry(commands::AbstractVector{UInt32})
    paths = Vector{Vector{Tuple{Int,Int}}}()
    cur = Tuple{Int,Int}[]
    x = 0
    y = 0
    i = 1
    n = length(commands)
    while i <= n
        cmd_int = commands[i]
        i += 1
        cmd = cmd_int & 0x7
        count = cmd_int >> 3
        if cmd == CMD_MOVETO
            for _ in 1:count
                i + 1 <= n || break
                x += zigzag(commands[i])
                y += zigzag(commands[i+1])
                i += 2
                # Each MoveTo begins a fresh path (new ring / line / point).
                isempty(cur) || push!(paths, cur)
                cur = Tuple{Int,Int}[(x, y)]
            end
        elseif cmd == CMD_LINETO
            for _ in 1:count
                i + 1 <= n || break
                x += zigzag(commands[i])
                y += zigzag(commands[i+1])
                i += 2
                push!(cur, (x, y))
            end
        elseif cmd == CMD_CLOSEPATH
            isempty(cur) || push!(cur, first(cur))
        end
    end
    isempty(cur) || push!(paths, cur)
    return paths
end

# Extract the single set field of a Tile.Value oneof. Priority order handles the
# ambiguity that decoded defaults look identical to genuine zero/empty values.
function value_to_any(v)
    isempty(v.string_value) || return v.string_value
    v.double_value != 0 && return v.double_value
    v.float_value != 0 && return v.float_value
    v.int_value != 0 && return v.int_value
    v.uint_value != 0 && return v.uint_value
    v.sint_value != 0 && return v.sint_value
    v.bool_value && return true
    return ""
end

function build_properties(tags::Vector{UInt32}, keys::Vector{String}, values)
    props = Dict{String,Any}()
    i = 1
    while i + 1 <= length(tags)
        ki = Int(tags[i]) + 1      # proto indices are 0-based
        vi = Int(tags[i+1]) + 1
        if 1 <= ki <= length(keys) && 1 <= vi <= length(values)
            props[keys[ki]] = value_to_any(values[vi])
        end
        i += 2
    end
    return props
end

"""
    parse_tile(bytes) -> Dict{String,VectorLayer}

Decode raw MVT protobuf `bytes` into a dictionary of layers keyed by layer name.
"""
function parse_tile(bytes::AbstractVector{UInt8})
    decoder = PB.ProtoDecoder(IOBuffer(bytes))
    tile = PB.decode(decoder, PBTile)
    layers = Dict{String,VectorLayer}()
    for layer in tile.layers
        feats = Vector{VectorFeature}(undef, length(layer.features))
        for (j, f) in enumerate(layer.features)
            feats[j] = VectorFeature(
                f.id,
                geomtype_symbol(f.var"#type"),
                build_properties(f.tags, layer.keys, layer.values),
                decode_geometry(f.geometry),
            )
        end
        layers[layer.name] = VectorLayer(layer.name, Int(layer.extent), feats)
    end
    return layers
end
