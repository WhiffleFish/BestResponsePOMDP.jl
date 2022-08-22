struct POMCPExploitabilitySolver{SOL, POMCP, G}
    sol::SOL # Abstract CFR solver
    pomcp::POMCP # POMCP solver
    game::G
    use_tree_value::Bool # use root value in tree (true), or traverse tree for action maximizing value
    value_samples::Int # number of mc tree traversals to make to estimate value
    p::Int # exploiting player
end

function POMCPExploitabilitySolver(
    cfr_sol::CFR.AbstractCFRSolver,
    pomcp_sol::POMCPSolver, # currently only supporting pomcp solver
    game::CFR.Game = cfr_sol.game;
    use_tree_value = true,
    value_samples = pomcp_sol.tree_queries,
    p = 2)

    #=
    default POMCP value estimator calls `actions(pomdp)`,
    but games require `actions(pomdp, s)`, so we keep all settings
    except for `estimate_value`, which we change to state-dependent
    random rollout
    =#
    modified_sol = POMCPSolver(NamedTuple(
        k => k == :estimate_value ? BestResponsePOMDP.RandomRollout() : getfield(pomcp_sol, k)
        for k in propertynames(pomcp_sol)
    )...)

    return POMCPExploitabilitySolver(cfr_sol, modified_sol, game, use_tree_value, value_samples, p)
end


function (sol::POMCPExploitabilitySolver)()
    return approx_exploitability(
        sol.pomcp,
        sol.sol,
        sol.value_samples,
        sol.game,
        sol.p;
        sol.use_tree_value
    )
end

mutable struct POMCPExploitabilityCallback{SOL<:POMCPExploitabilitySolver}
    sol::SOL
    n::Int
    state::Int
    hist::CFR.ExploitabilityHistory
    function POMCPExploitabilityCallback(sol, n=1)
        return new{typeof(sol)}(
            sol, n, 0, CFR.ExploitabilityHistory()
        )
    end
end

function (cb::POMCPExploitabilityCallback)()
    if iszero(rem(cb.state, cb.n))
        push!(cb.hist, cb.state, cb.sol())
    end
    cb.state += 1
end
