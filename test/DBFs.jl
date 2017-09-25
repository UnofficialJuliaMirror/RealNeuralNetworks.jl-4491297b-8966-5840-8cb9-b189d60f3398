using TEASAR
using TEASAR.DBFs   
using Base.Test

seg = zeros(UInt32,(100,100,100))
seg[48:52,48:52,:] = UInt32(1)
seg[49:52, 49:52, 48:52] = 1
seg[47:54, 47:54, 71:78] = 1

points = TEASAR.PointArrays.from_seg(seg)
boundary_point_indexes = TEASAR.PointArrays.get_boundary_point_indexes(points, seg)

@testset "test dbf computation" begin 
    dbf1 = DBFs.compute_DBF(points)
    #dbf2 = DBFs.compute_DBF(points, boundary_point_indexes)
    bin_im = DBFs.create_binary_image( seg )
    bin_im2 = DBFs.create_binary_image( points )
    @show size(bin_im)
    @show size(bin_im2)
    @test all(bin_im .== bin_im2)
    dbf3 = DBFs.compute_DBF(points, bin_im )
    #@show dbf1 
    #@show dbf3 
    # map((x,y) -> @test_approx_eq_eps(x,y,1), dbf1, dbf2)
    map((x,y) -> @test_approx_eq_eps(x,y,1), dbf1, dbf3)
end 

