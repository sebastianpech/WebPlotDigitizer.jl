using WebPlotDigitizer
using Test
using Dates

testdir(args...) = abspath(joinpath(dirname(pathof(WebPlotDigitizer)),"..","test",args...))
datadir(args...) = testdir("data",args...)

function testDate(dt::Date)
    res = WebPlotDigitizer.parse_import_value(Dates.datetime2unix(DateTime(dt))*1000.0,"2020/10/10")::Date
    res === res
end
function testDate(dt::DateTime)
    res = WebPlotDigitizer.parse_import_value(Dates.datetime2unix(DateTime(dt))*1000.0,"2020/10/10 10:00")::DateTime
    res === res
end
function testDate(dt::Time)
    res = WebPlotDigitizer.parse_import_value(Dates.datetime2unix(today()+dt)*1000.0,"10:00")::Time
    res === res
end

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
        @test wpd["XY"] isa WebPlotDigitizer.XYAxes
        @test wpd["XY"].isLogX == false
        @test wpd["XY"].isLogY == false
        wpd
    end
    @testset "basictypes.tar" begin
        wpd = WebPlotDigitizer.load_project(datadir("basictypes.tar"))
        @test all(wpd["XY Date"]["Dataset 4"][:,1] .== [Date(2020,1,1), Date(2020,1,3), Date(2020,2,1), Date(2020,2,13)])
        @test all(isapprox.(wpd["XY Date"]["Dataset 4"][:,2], [7,2,3,1], atol=0.1))
        @test all(isapprox.(wpd["XY"]["Dataset 0"][:,1], [0,1,3,5], atol=0.1))
        @test all(isapprox.(wpd["XY"]["Dataset 0"][:,2], [7,2,3,1], atol=0.1))
        @test all(isapprox.(wpd["XY Log"]["Dataset 3"][:,1], [1, 10, 100, 1000], atol=0.01))
        @test all(isapprox.(wpd["XY Log"]["Dataset 3"][:,2], [7,2,3,1], atol=0.1))
        @test all(isapprox.(wpd["Bar"]["Dataset 1"][:,1], [10,2,5,11], atol=0.1))
        @test all(isapprox.(wpd["Polar"]["Dataset 2"][:,2], rad2deg.([0,0.3,0.6,0.7]*2π), atol=0.5))
        @test all(isapprox.(wpd["Polar"]["Dataset 2"][:,1], [1,2,3,2], atol=0.1))
    end
    @testset "dateandtime.tar" begin
        wpd = WebPlotDigitizer.load_project(datadir("dateandtime.tar"))
        x1 = [Time(10,1,3), Time(10,2,3), Time(11,3,4), Time(13,10,3)]
        y1 = [1, 10, -3, 3]
        x2 = Date(2020,9,1) .+ x1
        y2 = [-1, 6, 3, -10]

        @test all((wpd["Time"]["D1"][:,1] .- x1) .< Dates.Second(10))
        @test all(isapprox.(wpd["Time"]["D1"][:,2], y1, atol=0.1))
        @test all((wpd["Datetime"]["D2"][:,1] .- x2) .< Dates.Second(10))
        @test all(isapprox.(wpd["Datetime"]["D2"][:,2], y2, atol=0.1))
    end
    @testset "Sorting" begin
        wpd = WebPlotDigitizer.load_project(datadir("default.tar"))
        @test issorted(wpd["XY"]["Dataset 2"][:,2]) == false
        sortby!(wpd["XY"],2)
        @test issorted(wpd["XY"]["Dataset 2"][:,2])
    end
    @testset "Date parser" begin
        @test testDate(Date(2020,10,1))
        @test testDate(DateTime(2020,10,1,10,1,2))
        @test testDate(Time(10,1))
    end
end