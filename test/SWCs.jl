using RealNeuralNetworks.SWCs
using Test

@testset "test SWC" begin 
    # read swc
    exampleFile = joinpath(@__DIR__, "../asset/77625.swc")
    println("load plain text swc using two methods...")
    @time swc = SWCs.load_swc( exampleFile )
    @time swc1 = SWCs.load_swc_v1( exampleFile )
    @assert swc == swc1

    str = String(swc)
    tempFile = tempname() * ".swc"

    println("save plain text swc ...")
    @time SWCs.save_swc(swc, tempFile)
    @test read(exampleFile, String) == read( tempFile , String)
    rm(tempFile)
    
    println("save binary swc ...")
    @time SWCs.save_swc_bin( swc, "$(tempFile).swc.bin" )
    println("load binary swc ...")
    @time swc2 = SWCs.load_swc_bin( "$(tempFile).swc.bin" )
    @test swc == swc2
    rm("$(tempFile).swc.bin")

    # test stretch
    SWCs.stretch_coordinates!(swc, (2,3,4))
end 

