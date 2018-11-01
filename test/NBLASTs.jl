using Test 

using RealNeuralNetworks.SWCs
using RealNeuralNetworks.NodeNets 
using RealNeuralNetworks.NBLASTs
using RealNeuralNetworks.Utils.VectorClouds 
using RealNeuralNetworks.Utils.RangeIndexingArrays 

using CSV

ASSET_DIR = joinpath(@__DIR__, "../asset/")

NEURON_ID1 = 77625
NEURON_ID2 = 77641

@testset "test NBLAST module..." begin 
    neuron1 = SWCs.load(joinpath(ASSET_DIR, "$(NEURON_ID1).swc.bin")) |> NodeNet;
    neuron2 = SWCs.load(joinpath(ASSET_DIR, "$(NEURON_ID2).swc.bin")) |> NodeNet;

    k = 20

    vectorCloud1 = NBLASTs.VectorCloud(neuron1)
    vectorCloud2 = NBLASTs.VectorCloud(neuron2)

    # transform to micron
    vectorCloud1[1:3, :] ./= 1000
    vectorCloud2[1:3, :] ./= 1000

    # read the precomputed score matrix, which is the joint distribution of the scores
    println("read the precomputed score table...")
    SMAT_FCWB_PATH = joinpath(@__DIR__, "../asset/smat_fcwb.csv")
    df = CSV.read(SMAT_FCWB_PATH)    
    ria = RangeIndexingArray(df)

    println("compute nblast score...")
    @time score = NBLASTs.nblast(ria, vectorCloud2, vectorCloud1) 
    println("query $(NEURON_ID1) against target $(NEURON_ID2): ", score)
    @test isapprox(score, Float32(42678.38))
    @time score = NBLASTs.nblast(ria, vectorCloud1, vectorCloud1)
    println("query $(NEURON_ID1) against itself: ", score)
    @test isapprox(score, Float32(68722.61)) 


    vectorCloudList = [vectorCloud1, vectorCloud2]
    # the result from R NBLAST is :
    # ID        77625	    77641
    # 77625	    68722.61	45593.67
    # 77641	    42678.38	81091.32
    RNBLAST_RESULT = Float32[68722.61 45593.67; 42678.38 81096.32]
    println("compute similarity matrix...")
    @time similarityMatrix = NBLASTs.nblast_allbyall(ria, vectorCloudList; normalisation=:raw)
    @show similarityMatrix
    @test isapprox.(similarityMatrix,  RNBLAST_RESULT) |> all
    
end 