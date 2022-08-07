function aggregate_initialstates(wrapper::POMDPWrapper{SOL,G,S,O}) where {SOL,G,S,O}
    game = wrapper.game
    h0 = CFR.initialhist(game)
    d = Dict{O,Vector{S}}()
    if CFR.player(game, h0) == wrapper.br_player
        I = CFR.infokey(game, h0)
        d[I] = [h0]
    else
        _aggregate_initialstates!(d, wrapper, h0)
    end
    return d
end

function _aggregate_initialstates!(d::Dict{K,V}, wrapper::POMDPWrapper, h) where {K,V}
    game = wrapper.game
    p = CFR.player(wrapper.game, h)
    return if CFR.isterminal(wrapper.game, h)
        nothing
    elseif iszero(p)
        A = CFR.chance_actions(game, h)
        for a ∈ A
            h′ = CFR.next_hist(game, h, a)
            _aggregate_initialstates!(d, wrapper, h′)
        end
        nothing
    elseif p != wrapper.br_player
        A = CFR.actions(game, h)
        for a ∈ A
            h′ = CFR.next_hist(game, h, a)
            _aggregate_initialstates!(d, wrapper, h′)
        end
        nothing
    else
        I = CFR.infokey(game, h)
        v = get!(d, I) do
            typeof(h)[]
        end
        push!(v, h)
        nothing
    end
end

function initialstategen(wrapper::POMDPWrapper)
    (;solver, game, br_player) = wrapper
    s = CFR.initialhist(game)
    p = player(game, s)
    terminal = CFR.isterminal(game, s)
    while !terminal || p != br_player
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
    return s
end
