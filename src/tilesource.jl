# Vector-tile source: fetch `.pbf` tiles over HTTP, decode them, and cache the
# result. A Julia analogue of mapscii's TileSource.js (HTTP mode only for v1).

import Downloads
import CodecZlib
import JSON3

# OpenFreeMap serves a TileJSON here whose `tiles` entry points at the current
# versioned tile URL template (the version changes as the planet is re-imported).
const OPENFREEMAP_TILEJSON = "https://tiles.openfreemap.org/planet"

"""
    TileSource(url_template)

Fetches and caches decoded vector tiles. `url_template` uses `{z}`/`{x}`/`{y}`
placeholders. Use the no-argument `TileSource()` to auto-resolve OpenFreeMap's
current tile URL from its TileJSON.
"""
struct TileSource
    url_template::String
    cache::Dict{Tuple{Int,Int,Int},Dict{String,VectorLayer}}
end
TileSource(url_template::AbstractString) =
    TileSource(url_template, Dict{Tuple{Int,Int,Int},Dict{String,VectorLayer}}())
TileSource() = from_tilejson(OPENFREEMAP_TILEJSON)

# Download a URL fully into a byte vector.
function download_bytes(url::AbstractString)
    buf = IOBuffer()
    Downloads.download(url, buf)
    return take!(buf)
end

"Resolve a TileJSON document's first `tiles` template into a `TileSource`."
function from_tilejson(tilejson_url::AbstractString)
    tj = JSON3.read(download_bytes(tilejson_url))
    templates = tj.tiles
    (templates === nothing || isempty(templates)) &&
        error("TileJSON at $tilejson_url has no `tiles` templates")
    return TileSource(String(templates[1]))
end

function tile_url(src::TileSource, z::Integer, x::Integer, y::Integer)
    return replace(src.url_template, "{z}" => z, "{x}" => x, "{y}" => y)
end

gzipped(bytes) = length(bytes) >= 2 && bytes[1] == 0x1f && bytes[2] == 0x8b
maybe_gunzip(bytes) = gzipped(bytes) ? transcode(CodecZlib.GzipDecompressor, bytes) : bytes

"""
    get_tile(src, z, x, y) -> Dict{String,VectorLayer}

Return the decoded layers for tile `(z, x, y)`, fetching and caching on first
access. Missing/empty tiles (HTTP errors or empty bodies) yield an empty layer
dictionary.
"""
function get_tile(src::TileSource, z::Integer, x::Integer, y::Integer)
    key = (Int(z), Int(x), Int(y))
    haskey(src.cache, key) && return src.cache[key]
    layers = try
        bytes = download_bytes(tile_url(src, z, x, y))
        isempty(bytes) ? Dict{String,VectorLayer}() : parse_tile(maybe_gunzip(bytes))
    catch err
        err isa InterruptException && rethrow()
        Dict{String,VectorLayer}()
    end
    src.cache[key] = layers
    return layers
end
