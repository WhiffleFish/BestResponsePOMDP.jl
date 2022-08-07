Base.@kwdef struct RandomRollout{RNG<:AbstractRNG}
    rng::RNG = Random.default_rng()
end

struct SolvedRandomRollout{P<:POMDP, RNG<:AbstractRNG}
    pomdp::P
    rng::RNG
end

MCTS.convert_estimator(r::RandomRollout, sol, pomdp) = SolvedRandomRollout(pomdp, r.rng)

function MCTS.estimate_value(r::SolvedRandomRollout, pomdp::POMDP, s, h::BeliefNode, steps::Int)
    (;pomdp, rng) = r
    γ = discount(pomdp)

    disc = 1.0
    r_total = 0.0
    step = 1

    while !isterminal(pomdp, s) && step ≤ steps

        a = rand(rng, actions(pomdp, s))

        s, r = @gen(:sp,:r)(pomdp, s, a, rng)

        r_total += disc*r

        disc *= γ
        step += 1
    end

    return r_total
end
