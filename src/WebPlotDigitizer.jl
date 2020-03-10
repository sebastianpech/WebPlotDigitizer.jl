module WebPlotDigitizer

using JSON
using NamedDims
using DataStructures
using Tar

import Base: getindex, show

export load_project, load_json

struct Axis{L,T,N}
    isLogX::Bool
    isLogY::Bool
    data::OrderedDict{String,<:NamedDimsArray{L, T, N}}
end

getindex(ax::Axis,name::String) = ax.data[name]

struct WPDProject
    axes::OrderedDict{String,Axis}
    path
end

getindex(wpd::WPDProject,name::String) = wpd.axes[name]

AxisType(t::String) = AxisType(Val(Symbol(t)))
AxisType(::Val{T}) where T = error("Axis type '$T' not defined for import.")
AxisType(::Val{:XYAxes}) = NamedDimsArray{(:X, :Y), Float64, 2, Array{Float64, 2}} 
getaxistype(::Axis{(:X, :Y)}) = :XYAxes

axis_from_JSON(ax::Dict{String}) =  Axis(ax["isLogX"],ax["isLogY"],OrderedDict{String,AxisType(ax["type"])}())
axes_from_JSON(axs::Vector) = OrderedDict(map(axs) do ax
    ax["name"] => axis_from_JSON(ax)
end)

add_dataset_from_JSON!(wpd::WPDProject, j::Dict{String}) = add_dataset_from_JSON!(wpd[j["axesName"]],j)
add_dataset_from_JSON!(ax::Axis{L}, j::Dict{String}) where L = ax.data[j["name"]] = NamedDimsArray{L}(mapfoldr(vcat,j["data"]) do p
    transpose(convert(Vector{Float64},p["value"]))
end)

function load_from_json(path,original_path=path)
    data = JSON.parse(read(path,String))
    wpd = WPDProject(axes_from_JSON(data["axesColl"]),original_path)
    for jdataset in data["datasetColl"]
        add_dataset_from_JSON!(wpd, jdataset)
    end
    wpd
end

function isWPDProject(path)
    content = getfield.(Tar.list(path),:path)
    "wpd_project/info.json" in content
end

function getWPDProjectFile(wpd_folder)
    info = JSON.parse(read(joinpath(wpd_folder, "info.json"),String))
    return info["json"]
end

function load_from_tar(path)
    isWPDProject(path) || error("Archive in '$path' is not a WebPlotDigitizer project.")
    tmp_dir = Tar.extract(path)
    wpd_folder = joinpath(tmp_dir, "wpd_project")
    wpd_file_name = getWPDProjectFile(wpd_folder)
    wpd_file = joinpath(tmp_dir, "wpd_project",wpd_file_name)
    wpd = load_from_json(wpd_file,path)
    rm(tmp_dir,recursive=true)
    return wpd
end

const load_project = load_from_tar
const load_json = load_from_json

function show(io::IO,wpd::WPDProject)
    axes = keys(wpd.axes)
    println(io,"WebPlotDigitizer:")
    for axis in keys(wpd.axes)
        print(io," $axis ($(getaxistype(wpd[axis])))")
        for dataset in keys(wpd[axis].data)
            println(io)
            print(io,"  $dataset")
        end
    end
end


end
