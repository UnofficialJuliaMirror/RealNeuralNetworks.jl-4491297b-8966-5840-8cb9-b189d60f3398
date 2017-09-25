module Manifests
using GSDicts, BigArrays
import ..TEASAR.DBFs
import ..TEASAR.PointArrays 
export Manifest

immutable Manifest
    # the bigarray for cutout
    ba          ::AbstractBigArray
    # the id of object
    obj_id       ::Integer
    # the unit range list for cutout
    rangeList   ::Vector
end 

"""
Parameters:
    dir 
"""
function Manifest( manifestDirPath::AbstractString, manifestKey::AbstractString, bigArrayPath::AbstractString )
    ba = BigArray( GSDict( bigArrayPath ) )
    h = GSDict( manifestDirPath; valueType=Dict{Symbol, Any})
    Manifest( h[manifestKey], ba )
end
"""
example: {"fragments": ["770048087:0:2968-3480_1776-2288_16912-17424"]}
"""
function Manifest( h::Dict{Symbol, Any}, ba::AbstractBigArray )
    Manifest( h[:fragments], ba )
end 
"""
example: ["770048087:0:2968-3480_1776-2288_16912-17424"]
"""
function Manifest{D,T,N,C}( ranges::Vector, ba::BigArray{D,T,N,C} )
    obj_id = parse( split(ranges[1], ":")[1] )
    obj_id = convert(T, obj_id)
    ranges = map(x-> split(x,":")[end], ranges)
    rangeList = map( BigArrays.Indexes.string2unit_range, ranges )
    Manifest( ba, obj_id, rangeList )
end

function Base.start(self::Manifest)
    1
end 

"""
get the point cloud and dbf
"""
function Base.next(self::Manifest, i )
    # example: [2456:2968, 1776:2288, 16400:16912]
    ranges = self.rangeList[i]
    offset = (map(x-> UInt32(start(x)-1), ranges)...)
    seg = self.ba[ranges...]
    bin_im = DBFs.create_binary_image( seg; obj_id = self.obj_id )
    @assert any(bin_im)
    point_cloud = PointArrays.from_binary_image( bin_im )
    # distance from boundary field
    dbf = DBFs.compute_DBF(point_cloud, bin_im)
    PointArrays.add_offset!(point_cloud, offset)
    return (point_cloud, dbf), i+1
end 
function Base.done(self::Manifest, i)
    i > length( self.rangeList )
end 

end # module