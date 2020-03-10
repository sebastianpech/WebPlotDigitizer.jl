using WebPlotDigitizer
using Test

testdir(args...) = abspath(joinpath(dirname(pathof(WebPlotDigitizer)),"..","test",args...))
datadir(args...) = testdir("data",args...)

@testset "WebPlotDigitizer" begin
    @testset "Loading" begin
        wpd = WebPlotDigitizer.load_project(datadir("default.tar"))
        @test collect(keys(wpd.axes)) == ["XY"]
        @test collect(keys(wpd.axes["XY"].data)) == ["Dataset 1", "Dataset 2", "Dataset 3", "Dataset 4"]
        @test_throws ErrorException WebPlotDigitizer.load_from_tar(datadir("no_wpd.tar"))
        newname = WebPlotDigitizer.load_project(datadir("newname.tar"))
        @test collect(keys(newname.axes)) == ["XY", "XY 2"]
        @test collect(keys(newname.axes["XY"].data)) == ["Dataset 1", "Dataset 2", "Dataset 3"]
        @test collect(keys(newname.axes["XY 2"].data)) == ["Dataset 4"]
    end
    @testset "default.tar" begin
        wpd = WebPlotDigitizer.load_project(datadir("default.tar"))
        @test WebPlotDigitizer.getaxistype(wpd["XY"]) == :XYAxes
        @test wpd["XY"].isLogX == false
        @test wpd["XY"].isLogY == false
        wpd
    end
end



