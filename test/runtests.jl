using Test
using BestResponsePOMDP
using POMDPs
using CounterfactualRegret
using CounterfactualRegret.Games
using BasicPOMCP

@testset "matrix" begin
    # MATRIX GAME
    game = MatrixGame()

    ## test converged solver
    cfr_sol = ESCFRSolver(game)
    train!(cfr_sol, 1_000_000)
    pomdp = POMDP(cfr_sol)

    sol = POMCPSolver(max_depth=5, tree_queries=100_000, estimate_value=BestResponsePOMDP.RandomRollout())
    policy = solve(sol, pomdp)

    e_analytical = exploitability(cfr_sol)
    e_mc1 = approx_exploitability(sol, cfr_sol; use_tree_value=true)
    e_mc2 = approx_exploitability(sol, cfr_sol; use_tree_value=false)
    @test isapprox(e_analytical, e_mc1; atol=0.1)
    @test isapprox(e_analytical, e_mc2; atol=0.1)

    ## test solver that has not converged
    cfr_sol = ESCFRSolver(game)
    train!(cfr_sol, 1)
    pomdp = POMDP(cfr_sol)

    sol = POMCPSolver(max_depth=5, tree_queries=100_000, estimate_value=BestResponsePOMDP.RandomRollout())
    policy = solve(sol, pomdp)

    e_analytical = exploitability(cfr_sol)
    e_mc1 = approx_exploitability(sol, cfr_sol; use_tree_value=true)
    e_mc2 = approx_exploitability(sol, cfr_sol; use_tree_value=false)
    @test isapprox(e_analytical, e_mc1; atol=0.1)
    @test isapprox(e_analytical, e_mc2; atol=0.1)

end

@testset "kuhn" begin
    # KUHN POKER
    game = Kuhn()

    ## test converged solver
    cfr_sol = ESCFRSolver(game)
    train!(cfr_sol, 1_000_000)
    pomdp = POMDP(cfr_sol)

    sol = POMCPSolver(max_depth=10, tree_queries=1_000_000, estimate_value=BestResponsePOMDP.RandomRollout())
    policy = solve(sol, pomdp)

    e_analytical = exploitability(cfr_sol)
    e_mc1 = approx_exploitability(cfr_sol, 100_000; use_tree_value=true)
    e_mc2 = approx_exploitability(cfr_sol, 100_000; use_tree_value=false)
    @test isapprox(e_analytical, e_mc1; atol=0.1)
    @test isapprox(e_analytical, e_mc2; atol=0.1)

    ## test solver that has not converged
    cfr_sol = ESCFRSolver(game)
    train!(cfr_sol, 1)
    pomdp = POMDP(cfr_sol)

    sol = POMCPSolver(max_depth=5, tree_queries=100_000, estimate_value=BestResponsePOMDP.RandomRollout())
    policy = solve(sol, pomdp)

    e_analytical = exploitability(cfr_sol)
    e_mc1 = approx_exploitability(sol, cfr_sol; use_tree_value=true)
    e_mc2 = approx_exploitability(sol, cfr_sol; use_tree_value=false)
    @test isapprox(e_analytical, e_mc1; atol=0.1)
    @test isapprox(e_analytical, e_mc2; atol=0.1)
end
