module WebPlotDigitizer

using JSON
using DataStructures
using Tar

export sortby, sortby!
import Base: getindex, show, size, axes, to_index

struct Dataset{L,T,N} <: AbstractArray{T,N}
    data::Array{T,N}
end

function Dataset{L}(orig::Array{T,N}) where {T,N,L}
    if N > 2
        throw(ArgumentError(
            "Datasets only support 1 and 2 dimensional arrays. Got: $N"
        ))
    end
    # This is from Nameddims.jl
    if !(L isa NTuple{N, Symbol})
        throw(ArgumentError(
            "A $N dimensional array, needs a $N-tuple of dimension names. Got: $L"
        ))
    end
    return Dataset{L, T, N}(orig)
end

size(ds::Dataset) = size(ds.data)
axes(ds::Dataset) = axes(ds.data)
to_index(ds::Dataset,col::Symbol) = to_index(ds,Val(col))
getindex(ds::Dataset, I...) = ds.data[to_indices(ds, I)...]
getindex(ds::Dataset, col::Symbol) = ds.data[:,to_index(ds, col)]

setindex!(ds::Dataset{L,T}, val::T, I...) where{L,T} = ds.data[to_indices(ds, I)...] = val
setindex!(ds::Dataset{L,T}, val::T, col::Symbol) where{L,T} = ds.data[:,to_index(ds, col)] = val

struct Axis{L,T,N}
    isLogX::Bool
    isLogY::Bool
    data::OrderedDict{String,Dataset{L, T, N}}
end

getindex(ax::Axis,name::String) = ax.data[name]

struct WPDProject
    axes::OrderedDict{String,Axis}
    path
end

getindex(wpd::WPDProject,name::String) = wpd.axes[name]

getaxislabels(t::String) = getaxislabels(Val(Symbol(t)))
getaxislabels(::Val{T}) where T = error("Axis type '$T' not defined for label generation.")
to_index(::Dataset{L},::Val{T}) where {L,T} = error("Dataset only supports columns $L. Got $T")

# Axis types
# XYAxes
getaxislabels(::Val{:XYAxes}) = (:X, :Y)
getaxistype(::Axis{(:X, :Y)}) = :XYAxes
to_index(::Dataset{(:X,:Y)},::Val{:X}) = 1
to_index(::Dataset{(:X,:Y)},::Val{:Y}) = 2

parse_import_value(val::Number) = float(val)

function load_from_json(path,original_path=path)
    data = JSON.parse(read(path,String))
    return WPDProject(OrderedDict([
        ax["name"] => Axis(ax["isLogX"],ax["isLogY"],
            OrderedDict([d["name"] => Dataset{getaxislabels(ax["type"])}(
                mapfoldr(vcat,d["data"]) do p
                    transpose(parse_import_value.(p["value"])) # Convert to supported types
                end)
            for d in data["datasetColl"] if d["axesName"] == ax["name"]]))
    for ax in data["axesColl"]]),original_path)
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
    wpd = load_from_json(wpd_file,path)
    rm(tmp_dir,recursive=true)
    return wpd
end

const load_project = load_from_tar
const load_json = load_from_json

function show(io::IO,wpd::WPDProject)
    axes = keys(wpd.axes)
    print(io,"WebPlotDigitizer:")
    for axis in keys(wpd.axes)
        println(io)
        print(io," $axis ($(getaxistype(wpd[axis])))")
        for dataset in keys(wpd[axis].data)
            println(io)
            print(io,"  $dataset")
        end
    end
end

function sortby(ds::T,by::Symbol;rev::Bool=false) where T <: Dataset
    idx = to_index(ds,by)
    return T(sortslices(ds,by=x->x[idx],dims=1,rev=rev))
end

function sortby!(ds::T,by::Symbol;rev::Bool=false) where T <: Dataset
    idx = to_index(ds,by)
    ds.data .= sortslices(ds,by=x->x[idx],dims=1,rev=rev)
end

end
