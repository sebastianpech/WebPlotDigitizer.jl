using WebPlotDigitizer
using Test

using Plot

testdir(args...) = abspath(joinpath(dirname(pathof(WebPlotDigitizer)),"..","test",args...))
datadir(args...) = testdir("data",args...)

@testset "WebPlotDigitizer" begin
    @testset "Loading" begin
        wpd = load_project(datadir("default.tar"))
        @test collect(keys(wpd.axes)) == ["XY"]
        @test collect(keys(wpd.axes["XY"].data)) == ["Dataset 1", "Dataset 2", "Dataset 3", "Dataset 4"]
        @test_throws ErrorException WebPlotDigitizer.load_from_tar(datadir("no_wpd.tar"))
    end
    @testset "default.tar" begin
        wpd = load_project(datadir("default.tar"))
        @test WebPlotDigitizer.getaxistype(wpd["XY"]) == :XYAxes
        @test wpd["XY"].isLogX == false
        @test wpd["XY"].isLogY == false
        wpd
    end
end


