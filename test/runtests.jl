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
