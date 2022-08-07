struct POMDPWrapper{SOL, G, S, O} <: POMDPs.POMDP{S,Int,O}
    solver::SOL
    game::G
    br_player::Int
    function POMDPWrapper(solver::SOL, game::GAME, p::Int=2) where {SOL,GAME}
        S = CFR.histtype(game)
        O = CFR.infokeytype(game)
        return new{SOL,GAME,S,O}(solver,game,p)
    end

    POMDPWrapper(solver, p::Int=2) = POMDPWrapper(solver,solver.game,p)
end

POMDPs.POMDP(solver::CFR.AbstractCFRSolver, game::CFR.Game, p::Int=2) = POMDPWrapper(solver, game, p)
POMDPs.POMDP(solver::CFR.AbstractCFRSolver, p::Int=2) = POMDPWrapper(solver, p)

POMDPs.discount(::POMDPWrapper) = 1.0

POMDPs.actions(wrapper::POMDPWrapper, h) = eachindex(CFR.actions(wrapper.game, h))

POMDPs.actions(wrapper::POMDPWrapper, b::AbstractParticleBelief) = eachindex(CFR.actions(wrapper.game, first(particles(b))))

POMDPs.isterminal(wrapper::POMDPWrapper, h) = CFR.isterminal(wrapper.game, h)

POMDPs.actions(::POMDPWrapper, ::Deterministic) = 1:1

POMDPs.initialstate(wrapper::POMDPWrapper) = Deterministic(CFR.initialhist(wrapper.game))

"""
Start from some state s where BR player is not at turn to play and keeping
generating new states until BR player is at turn to player or state becomes terminal.
"""
function gen_until_player_turn(wrapper::POMDPWrapper{SOL,G,S}, s::S, rng::AbstractRNG) where {SOL,G,S}
    (;solver, game, br_player) = wrapper
    p = CFR.player(game, s)
    terminal = CFR.isterminal(game, s)
    while !terminal && p != br_player
        a = if iszero(p)
            rand(rng, CFR.chance_actions(game, s))
        else
            A = CFR.actions(game, s)
            k = CFR.infokey(game, s)
            σ = CFR.strategy(solver, k)
            A[CFR.weighted_sample(rng, σ)]
        end
        s = CFR.next_hist(game, s, a)
        terminal = CFR.isterminal(game, s)
        p = CFR.player(game, s)
    end
    return s, terminal
end

function POMDPs.gen(wrapper::POMDPWrapper, s, a::Int, rng::AbstractRNG)
    (;game, br_player) = wrapper
    p = CFR.player(game, s)
    terminal = CFR.isterminal(game, s)

    # handle weird initialstate behavior
    sp, terminal = if p != br_player
        gen_until_player_turn(wrapper, s, rng)
    else
        A = CFR.actions(game, s)
        gen_until_player_turn(wrapper, CFR.next_hist(game, s, A[a]), rng)
    end

    o = CFR.infokey(game, sp)
    r = terminal ? CFR.utility(game, br_player, sp) : 0.0
    return (;sp,o,r)
end
