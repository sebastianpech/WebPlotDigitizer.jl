module WebPlotDigitizer

using JSON
using DataStructures
using Tar
using Dates

export sortby, sortby!
import Base: getindex, show, size, axes, to_index

abstract type Axes{T} end

getindex(ax::Axes,name::String) = ax.data[name]

struct XYAxes{T} <: Axes{T}
    isLogX::Bool
    isLogY::Bool
    data::OrderedDict{String,<:Matrix{T}}
end

struct BarAxes{T} <: Axes{T}
    isRotated::Bool
    isLog::Bool
    data::OrderedDict{String,<:Matrix{T}}
end

struct PolarAxes{T} <: Axes{T}
    isClockwise::Bool
    isLog::Bool
    isDegrees::Bool
    data::OrderedDict{String,<:Matrix{T}}
end

Axis(ax::Dict,data::Dict) = Axis(Val(Symbol(ax["type"])),ax,data)
Axis(::Val{T},args...) where T = error("Axis types XYAxes known. Got: $T")

function Axis(::Val{:XYAxes},ax,data)
    XYAxes(ax["isLogX"],ax["isLogY"],
        OrderedDict([d["name"] => convert_values_entry(d["data"],ax)
                for d in data["datasetColl"] if d["axesName"] == ax["name"]]))
end

function Axis(::Val{:BarAxes},ax,data)
    BarAxes(ax["isRotated"],ax["isLog"],
        OrderedDict([d["name"] => convert_values_entry(d["data"],ax)
                for d in data["datasetColl"] if d["axesName"] == ax["name"]]))
end

function Axis(::Val{:PolarAxes},ax,data)
    PolarAxes(ax["isClockwise"],ax["isLog"],ax["isDegrees"],
        OrderedDict([d["name"] => convert_values_entry(d["data"],ax)
                for d in data["datasetColl"] if d["axesName"] == ax["name"]]))
end

const re_full_datetime = r"^\d{4}\/\d{1,2}\/\d{1,2} \d{1,2}:\d{1,2}$"
const re_full_date     = r"^\d{4}\/\d{1,2}\/\d{1,2}$"
const re_year_month    = r"^\d{4}\/\d{1,2}$"
const re_time          = r"^\d{1,2}:\d{1,2}$"
const re_datetime = [re_full_datetime, re_full_date, re_year_month, re_time]

function parse_import_value(val::Number, dx::String)
    if any(x->occursin(x,dx), re_datetime)
        if occursin(re_time,dx) # time only
            return Time(Dates.unix2datetime(val/1000))
        elseif !(occursin(":",dx))
            return Date(round(Dates.unix2datetime(val/1000),Dates.Day))
        end
        return DateTime(Dates.unix2datetime(val/1000))
    elseif tryparse(Float64,dx) != nothing
        return float(val)
    end
    error("Expected to parse a date or time value. Got:$dx")
end

parse_import_value(val::Number, dx::Number) = float(val)

get

# Convert to supported types.
# Always store a 2D array.
const column_names = ("dx", "dy", "dz")
convert_values_entry(values,ax) = mapfoldr(vcat,values) do p
    col_specification = getindex.(Ref(ax["calibrationPoints"][1]),column_names)[1:length(p["value"])]
    permutedims(parse_import_value.(p["value"], col_specification))
end

struct WPDProject
    axes::OrderedDict{String,Axes}
end

getindex(wpd::WPDProject,name::String) = wpd.axes[name]

function load_from_json(path)
    data = JSON.parse(read(path,String))
    return WPDProject(OrderedDict([
        ax["name"] => Axis(ax,data)
    for ax in data["axesColl"]]))
end

function isWPDProject(path,name)
    content = getfield.(Tar.list(path),:path)
    "$name/info.json" in content
end

function getWPDProjectName(path)
    content = filter(Tar.list(path)) do f
        f.type == :directory
    end
    length(content) != 1 && error("Can't retrive project name. There are multiple folders at toplevel, a WebPlotDigitizer project only has one.")
    return dirname(content[1].path)
end

function getWPDProjectFile(wpd_folder)
    info = JSON.parse(read(joinpath(wpd_folder, "info.json"),String))
    return info["json"]
end

function load_from_tar(path)
    name = getWPDProjectName(path)
    isWPDProject(path,name) || error("Tar at '$path' is not a WebPlotDigitizer project.")
    tmp_dir = Tar.extract(path)
    wpd_folder = joinpath(tmp_dir, name)
    wpd_file_name = getWPDProjectFile(wpd_folder)
    wpd_file = joinpath(tmp_dir, name, wpd_file_name)
    wpd = load_from_json(wpd_file)
    rm(tmp_dir,recursive=true)
    return wpd
end

const load_project = load_from_tar
const load_json = load_from_json

getaxisdescription(::T) where T = split("$T",".")[end]

function show(io::IO,wpd::WPDProject)
    axes = keys(wpd.axes)
    print(io,"WebPlotDigitizer:")
    for axis in keys(wpd.axes)
        println(io)
        print(io," '$axis' $(getaxisdescription(wpd[axis]))")
        for dataset in keys(wpd[axis].data)
            println(io)
            print(io,"   $dataset")
        end
    end
end

function sortby(ds::Matrix,by::Int;rev::Bool=false)
    idx = to_index(ds,by)
    return sortslices(ds,by=x->x[idx],dims=1,rev=rev)
end

function sortby!(ds::Matrix,by::Int;rev::Bool=false)
    sorted = sortby(ds,by,rev=rev)
    ds .= sorted
end

function sortby!(ax::Axes, by::Int; rev::Bool=false)
    for ds in ax.data
        sortby!(ds[2], by, rev=rev)
    end
end

end
