module SWCs
using ..RealNeuralNetworks.NodeNets

export SWC

type PointObj
    point_type  :: UInt8 
    x           :: Float32 
    y           :: Float32 
    z           :: Float32 
    radius      :: Float32 
    parent      :: Int32
end

function PointObj( p::Union{Tuple, Vector} )
    @assert length(p)==6
    PointObj( UInt8(p[1]), Float32(p[2]), Float32(p[3]), Float32(p[4]), Float32(p[5]), Int32(p[6]) )
end 

function Base.String(self::PointObj)
    "$(self.point_type) $(self.x) $(self.y) $(self.z) $(self.radius) $(self.parent)"
end 

typealias SWC Vector{PointObj}

function SWC(nodeNet::NodeNet)
    edges = NodeNets.get_edges(nodeNet)
    swc = SWC()
    sizehint!(swc, NodeNets.get_node_num(nodeNet))

    for node in NodeNets.get_node_list(nodeNet)
        point = PointObj(0, node[1], node[2], node[3], node[4], -1)
        push!(swc, point)
    end
    # assign parents according to edge 
    for e in edges 
        swc[e[2]].parent = e[1]
    end  
    swc
end

################## properties #######################
function get_node_num(self::SWC)
    length(self)
end 
function get_edge_num(self::SWC)
    num_edges = 0
    for pointObj in self 
        if pointObj.parent != -1
            num_edges += 1
        end 
    end 
    num_edges 
end

"""
    get_edges(self::SWC)

get the edges represented as a Vector{NTuple{2,UInt32}}
"""
function get_edges(self::SWC)
    edges = Vector{NTuple{2,UInt32}}()
    for (index, pointObj) in enumerate(self)
        if pointObj.parent != -1
            push!(edges, (pointObj.parent, index))
        end 
    end 
    edges 
end 

################## IO ###############################

"""
get binary buffer formatted as neuroglancer nodeNet.

# Binary format
    UInt32: number of vertex
    UInt32: number of edges
    Array{Float32,2}: Nx3 array, xyz coordinates of vertex
    Array{UInt32,2}: Mx2 arrray, node index pair of edges
reference: 
https://github.com/seung-lab/neuroglancer/wiki/Skeletons
"""
function get_neuroglancer_precomputed(self::SWC)
    @show get_node_num(self)
    @show get_edge_num(self)
    # total number of bytes
    num_bytes = 4 + 4 + 4*3*get_node_num(self) + 4*2*get_edge_num(self)
    buffer = IOBuffer( num_bytes )
    # write the number of vertex, and edges
    write(buffer, UInt32(get_node_num(self)))
    write(buffer, UInt32(get_edge_num(self)))
    # write the node coordinates
    for pointObj in self 
        write(buffer, pointObj.x)
        write(buffer, pointObj.y)
        write(buffer, pointObj.z)
    end
    # write the edges
    for edge in get_edges( self )
        # neuroglancer index is 0-based
        write(buffer, UInt32( edge[1]-ONE_UINT32 ))
        write(buffer, UInt32( edge[2]-ONE_UINT32 ))
    end
    bin = Vector{UInt8}(take!(buffer))
    close(buffer)
    return bin 
end 

function save(self::SWC, file_name::AbstractString)
    f = open(file_name, "w")
    for i in 1:length(self)
        write(f, "$i $(String(self[i])) \n")
    end
    close(f)
end 

function load(file_name::AbstractString)
    swc = SWC()
    open(file_name) do f
        for line in eachline(f)
            try 
                numbers = map(parse, split(line))
                # construct a point object
                pointObj = PointObj( numbers[2:7] )
                push!(swc, pointObj)
            catch err 
                if !constains(line, "#")
                    println("comment in swc file: $line")
                else
                    warn("invalid line: $line")
                end 
            end 
        end 
    end 
    return swc
end 

#################### manipulate ######################

"""
note that only stretch the coordinates here, not including the radius
since radius was already adjusted in the neighborhood weights 
"""
function stretch_coordinates!(self::SWC, expansion::Tuple)
    @assert length(expansion) == 3
    for i in 1:length( self )
        self[i].x       *= expansion[1]
        self[i].y       *= expansion[2]
        self[i].z       *= expansion[3]
        self[i].radius  *= (prod(expansion))^(1/3)
    end 
end 

"""
stretch the coordinate according to the mip level
normally, we only build mip level at XY plane, not Z
"""
function stretch_coordinates!(self::SWC, mip::Integer)
    stretch_coordinates!(self, (2^mip, 2^mip, 1))
end 

function add_offset!(self::SWC, offset::Tuple)
    @assert length(offset) == 3
    for in in length( self )
        self[i].x += offset[1]
        self[i].y += offset[2]
        self[i].z += offset[3]
    end 
end 

end # module of SWCs
