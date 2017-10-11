using Base.Test
using RealNeuralNetworks.FakeSegmentations 
using RealNeuralNetworks.BranchNets
using RealNeuralNetworks.NodeNets
using RealNeuralNetworks.SWCs

@testset "test BranchNets" begin
    println("create fake cylinder segmentation...")
    @time seg = FakeSegmentations.broken_cylinder()
    println("skeletonization to build a BranchNet ...")
    @time branchNet = BranchNet(seg)
    println("transform to SWC structure ...")
    @time swc = SWCs.SWC( branchNet )
    SWCs.save(swc, "/tmp/cylinder.swc")

    println("create fake ring segmentation ...")
    seg = FakeSegmentations.broken_ring()
    branchNet = BranchNet(seg)
    swc = SWCs.SWC( branchNet )
    SWCs.save(swc, "/tmp/ring.swc")
end 