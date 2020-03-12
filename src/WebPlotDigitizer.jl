module WebPlotDigitizer

using JSON
using DataStructures
using Tar

export sortby, sortby!
import Base: getindex, show, size, axes, to_index

abstract type Axes{T} end

getindex(ax::Axes,name::String) = ax.data[name]

struct XYAxes{T} <: Axes{T}
    isLogX::Bool
    isLogY::Bool
    data::OrderedDict{String,<:Matrix{T}}
end

Axis(t::String) = Axis(Val(Symbol(t)))
Axis(::Val{T}) where T = error("Axis types XYAxes known. Got: $T")
Axis(::Val{:XYAxes}) = XYAxes


struct WPDProject
    axes::OrderedDict{String,Axes}
end

getindex(wpd::WPDProject,name::String) = wpd.axes[name]

parse_import_value(val::Number) = float(val)

function load_from_json(path)
    data = JSON.parse(read(path,String))
    return WPDProject(OrderedDict([
        ax["name"] => Axis(ax["type"])(ax["isLogX"],ax["isLogY"],
            OrderedDict([d["name"] => mapfoldr(vcat,d["data"]) do p
                    # Convert to supported types.
                    # Always store a 2D array.
                    transpose(parse_import_value.(p["value"]))
                end
            for d in data["datasetColl"] if d["axesName"] == ax["name"]]))
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

getaxisdescription(::XYAxes{T}) where T = "XYAxes{$T}"

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
