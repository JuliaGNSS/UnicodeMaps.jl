using UnicodeMaps
using Test
import MapTiles

const M = UnicodeMaps

@testset "UnicodeMaps" begin

    @testset "zigzag decode" begin
        @test M.zigzag(UInt32(0)) == 0
        @test M.zigzag(UInt32(1)) == -1
        @test M.zigzag(UInt32(2)) == 1
        @test M.zigzag(UInt32(3)) == -2
        @test M.zigzag(UInt32(50)) == 25
        @test M.zigzag(UInt32(34)) == 17
    end

    @testset "geometry command decoder (MVT spec examples)" begin
        # Point (25, 17): §4.3.5.1
        @test M.decode_geometry(UInt32[9, 50, 34]) == [[(25, 17)]]
        # MultiPoint (5,7),(3,2)
        @test M.decode_geometry(UInt32[17, 10, 14, 3, 9]) == [[(5, 7)], [(3, 2)]]
        # LineString (2,2)->(2,10)->(10,10): §4.3.5.2
        @test M.decode_geometry(UInt32[9, 4, 4, 18, 0, 16, 16, 0]) ==
              [[(2, 2), (2, 10), (10, 10)]]
        # Polygon (3,6)->(8,12)->(20,34) + ClosePath: §4.3.5.3
        @test M.decode_geometry(UInt32[9, 6, 12, 18, 10, 12, 24, 44, 15]) ==
              [[(3, 6), (8, 12), (20, 34), (3, 6)]]
    end

    @testset "hex colors" begin
        @test M.hex2rgb("#ffffff") == (255, 255, 255)
        @test M.hex2rgb("#000000") == (0, 0, 0)
        @test M.hex2rgb("#f80") == (255, 136, 0)
        @test M.hex_color("#ff0000") == M.rgb(255, 0, 0)
        @test_throws ArgumentError M.hex2rgb("red")
    end

    @testset "style filter compilation" begin
        cf = M.compile_filter
        @test cf(nothing)(Dict()) == true
        @test cf(["==", "class", "city"])(Dict("class" => "city"))
        @test !cf(["==", "class", "city"])(Dict("class" => "town"))
        @test cf(["!=", "class", "city"])(Dict("class" => "town"))
        @test cf(["in", "class", "a", "b"])(Dict("class" => "b"))
        @test !cf(["in", "class", "a", "b"])(Dict("class" => "c"))
        @test cf(["has", "name"])(Dict("name" => "X"))
        @test !cf(["has", "name"])(Dict())
        @test cf(["<=", "admin_level", 2])(Dict("admin_level" => 2))
        @test !cf(["<=", "admin_level", 2])(Dict("admin_level" => 4))
        @test cf(["all", ["==", "class", "city"], ["has", "name"]])(
            Dict("class" => "city", "name" => "X"))
        @test !cf(["all", ["==", "class", "city"], ["has", "name"]])(
            Dict("class" => "city"))
        @test cf(["any", ["==", "class", "a"], ["==", "class", "b"]])(
            Dict("class" => "b"))
        # missing key comparisons should not error
        @test cf([">", "admin_level", 2])(Dict()) == false
    end

    @testset "bundled style" begin
        style = M.default_style()
        @test !isempty(style.layers)
        @test style.background !== nothing
        ls = M.style_for(style, "water", Dict("\$type" => "Polygon"))
        @test ls !== nothing
        @test ls.type == :fill
        @test M.style_for(style, "no_such_layer", Dict()) === nothing
    end

    @testset "color themes" begin
        @test Set(M.THEMES) == Set((:dark, :light))
        for name in M.THEMES
            t = theme(name)
            @test t isa M.Style
            @test t.background !== nothing
        end
        @test theme(:dark).background != theme(:light).background
        @test_throws ArgumentError theme(:nope)
    end

    @testset "slippy math matches MapTiles" begin
        for (lon, lat, z) in [(13.4, 52.5, 6), (-122.4, 37.8, 8), (0.0, 0.0, 3)]
            fx, fy = M.lonlat_to_tile(lon, lat, z)
            t = MapTiles.Tile((lon, lat), z, MapTiles.wgs84)
            @test floor(Int, fx) == t.x
            @test floor(Int, fy) == t.y
        end
    end

    @testset "canvas primitives" begin
        mc = M.MapCanvas(20, 10)
        M.set_pixel!(mc, 0, 0, M.rgb(255, 0, 0))
        M.draw_line!(mc, 0, 0, 39, 39, M.rgb(0, 255, 0))
        M.fill_polygon!(mc, [[(2, 2), (30, 2), (30, 30), (2, 30)]], M.rgb(0, 0, 255))
        M.draw_text!(mc, "Hi", 4, 4, M.rgb(255, 255, 255))
        s = M.frame(mc)
        @test s isa String
        @test occursin("H", s)   # label char present
        @test !isempty(s)
    end

    @testset "interactive helpers" begin
        # key decoding
        @test M.read_key(IOBuffer("\e[A")) === :up
        @test M.read_key(IOBuffer("\e[B")) === :down
        @test M.read_key(IOBuffer("\e[C")) === :right
        @test M.read_key(IOBuffer("\e[D")) === :left
        @test M.read_key(IOBuffer("\eOA")) === :up
        @test M.read_key(IOBuffer("q")) === 'q'
        @test M.read_key(IOBuffer("\x03")) === :quit
        @test M.read_key(IOBuffer("\e")) === :esc
        @test M.read_key(IOBuffer("")) === :eof
        # longitude wrapping
        @test M.wrap_lon(190.0) ≈ -170.0
        @test M.wrap_lon(-190.0) ≈ 170.0
        # panning: east increases lon, south decreases lat; round-trips back
        lon, lat = 10.0, 50.0
        e = M.pan_center(lon, lat, 8, 100, 40, 0.25, 0.0)
        @test e[1] > lon && e[2] ≈ lat
        s = M.pan_center(lon, lat, 8, 100, 40, 0.0, 0.25)
        @test s[2] < lat && s[1] ≈ lon
        back = M.pan_center(e..., 8, 100, 40, -0.25, 0.0)
        @test back[1] ≈ lon atol = 1e-6
        # higher zoom pans a smaller geographic distance
        far = M.pan_center(lon, lat, 4, 100, 40, 0.25, 0.0)
        @test (far[1] - lon) > (e[1] - lon)
        @test M.pan_center(0.0, 89.0, 3, 80, 40, 0.0, -1.0)[2] <= 85.06  # Mercator pole limit
    end

    @testset "marker pin" begin
        mc = M.MapCanvas(40, 20)
        red = M.rgb(0xea, 0x43, 0x35)
        x, y = mc.width ÷ 2, mc.height ÷ 2
        M.draw_marker!(mc, x, y, red)
        # the exact tip pixel is the marker color
        cx, cy = M.UP.pixel_to_char_point(mc.canvas, x, y)
        @test mc.canvas.colors[cy, cx] == red
        # a pin covers several cells
        @test count(==(red), mc.canvas.colors) > 5
    end

    @testset "marker anchoring (stays put while panning)" begin
        W, H = 200, 160
        # marker on the view center sits at the middle
        @test M.marker_pixel(10.0, 50.0, 10.0, 50.0, 8, W, H) == (100, 80)
        # a point east/south of center is right/below center
        e = M.marker_pixel(10.0, 50.0, 10.5, 50.0, 8, W, H)
        @test e[1] > 100 && e[2] == 80
        s = M.marker_pixel(10.0, 50.0, 10.0, 49.5, 8, W, H)
        @test s[2] > 80 && s[1] == 100
        # panning the view east (center lon increases) moves the fixed pin left
        pin = (10.0, 50.0)
        before = M.marker_pixel(10.0, 50.0, pin..., 8, W, H)[1]
        after = M.marker_pixel(10.2, 50.0, pin..., 8, W, H)[1]
        @test after < before
    end

    @testset "line label anchoring" begin
        W, H = 200, 160
        # a fully visible horizontal line is labelled at its midpoint
        @test M.line_label_anchor([(0, 80), (100, 80)], W, H) == (50, 80, 100.0)
        # a single visible vertex is still a usable anchor, with zero length
        @test M.line_label_anchor([(10, 10)], W, H) == (10, 10, 0.0)
        # nothing on screen -> no anchor
        @test M.line_label_anchor([(-5, -5), (-50, -50)], W, H) === nothing
        # the anchor lands on the longest *visible* run, not the first one
        pts = [(0, 10), (10, 10),            # short visible run
               (-40, 10), (-40, 100),        # off-screen detour
               (20, 100), (180, 100)]        # long visible run
        x, y, len = M.line_label_anchor(pts, W, H)
        @test y == 100 && 20 < x < 180 && len ≈ 160.0
        # a line reaching off-screen is anchored inside the visible part
        x2, y2, _ = M.line_label_anchor([(150, 40), (400, 40)], W, H)
        @test x2 == 150 && y2 == 40
    end

    @testset "label budget and priority" begin
        # the budget follows the canvas area, not the zoom level, and is clamped
        @test M.label_budget(120, 50) == (120 * 50) ÷ M.CELLS_PER_LABEL
        @test M.label_budget(400, 120) > M.label_budget(120, 50)
        @test M.label_budget(10, 5) == 3      # floor: a tiny canvas still labels
        @test M.label_budget(500, 500) == 60  # ceiling: never a wall of text
        # earlier style layer wins; within a layer, lower rank wins
        c(layer, rank) = M.LabelCandidate("x", 0, 0, M.rgb(0, 0, 0), layer, rank)
        cands = [c(3, 1.0), c(1, 9.0), c(1, 2.0), c(2, 0.0)]
        sort!(cands; by = M.label_priority, alg = MergeSort)
        @test [(l.layer, l.rank) for l in cands] ==
              [(1, 2.0), (1, 9.0), (2, 0.0), (3, 1.0)]
        # OpenMapTiles place ranks carry through; rankless layers tie at 0
        @test M.point_rank(Dict("rank" => 3)) == 3.0
        @test M.point_rank(Dict("name" => "Lake")) == 0.0
    end

    @testset "street name style layers" begin
        for name in M.THEMES
            t = theme(name)
            road = filter(l -> l.source_layer == "transportation_name", t.layers)
            @test length(road) == 2
            @test all(l -> l.type == :symbol, road)
            # no zoom gate: the label budget decides what fits, not the zoom
            @test all(l -> l.minzoom === nothing && l.maxzoom === nothing, road)
            # major roads are matched by the first of the two, minor by the second
            @test road[1].applies(Dict("class" => "motorway", "name" => "A1"))
            @test !road[1].applies(Dict("class" => "residential", "name" => "Main St"))
            @test road[2].applies(Dict("class" => "residential", "name" => "Main St"))
        end
    end

    @testset "symbol layer precedence" begin
        # Layer order is the label priority, so it has to encode what matters:
        # places > seas > big roads > small roads > ponds and fountains, which
        # OpenMapTiles gives the same class ("lake") as real lakes.
        for name in M.THEMES
            idx = Dict(l.id => i for (i, l) in enumerate(theme(name).layers))
            @test idx["place-country"] < idx["place-city"] < idx["place-other"]
            @test idx["place-other"] < idx["water-name-sea"]
            @test idx["water-name-sea"] < idx["road-name-major"] < idx["road-name-minor"]
            @test idx["road-name-minor"] < idx["water-name-other"]
        end
        sea, other = let ls = theme(:dark).layers
            (only(filter(l -> l.id == "water-name-sea", ls)),
             only(filter(l -> l.id == "water-name-other", ls)))
        end
        @test sea.applies(Dict("class" => "sea", "name" => "North Sea"))
        @test sea.applies(Dict("class" => "bay", "name" => "Hudson Bay"))
        @test !other.applies(Dict("class" => "bay", "name" => "Hudson Bay"))
        @test !sea.applies(Dict("class" => "lake", "name" => "Neptunbrunnen"))
        @test other.applies(Dict("class" => "lake", "name" => "Neptunbrunnen"))
        @test !other.applies(Dict("class" => "ocean", "name" => "North Atlantic Ocean"))
    end

    @testset "network smoke test (OpenFreeMap)" begin
        ran = false
        try
            src = M.TileSource()
            layers = M.get_tile(src, 0, 0, 0)
            if isempty(layers)
                @info "skipping network smoke test: empty tile / no connectivity"
            else
                ran = true
                @test haskey(layers, "water") || haskey(layers, "boundary")
                img = worldmap(center = (10.0, 30.0), zoom = 2, size = (60, 24), source = src)
                @test img isa MapImage
                @test !isempty(sprint(show, img))
            end
        catch err
            err isa InterruptException && rethrow()
            @info "skipping network smoke test" exception = err
        end
        ran || @test_skip "network unavailable"
    end

end
