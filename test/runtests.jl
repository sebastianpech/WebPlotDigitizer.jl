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
    @testset "Custom Array" begin
        A = rand(10,2)
        _A = WebPlotDigitizer.Dataset{(:X,:Y)}(A)
        @test A[:,1] == _A[:,:X]
        @test A[:,2] == _A[:,:Y]
        @test A[2:3,2] == _A[2:3,:Y]
        @test A[:,2] == _A[:Y]
        @test_throws ErrorException _A[:Z]
    end
    @testset "default.tar" begin
        wpd = WebPlotDigitizer.load_project(datadir("default.tar"))
        @test WebPlotDigitizer.getaxistype(wpd["XY"]) == :XYAxes
        @test wpd["XY"].isLogX == false
        @test wpd["XY"].isLogY == false
        wpd
    end
end