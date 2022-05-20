# This file was generated, do not modify it.

# Script compatible with Literate.jl + Franklin.jl
include(joinpath(pwd(), "utils.jl")) #hide

include_code("jssp/data.jl") #hide

function get_problem(::Val{:ortools_example})
    return [
        Job([Op(1, 3), Op(2, 2), Op(3, 2)]),
        Job([Op(1, 2), Op(3, 1), Op(2, 4)]),
        Job([Op(2, 4), Op(3, 3)])
    ]
end

# This is a shortcut to avoid having to wrap symbols in Val
get_problem(x::Symbol) = get_problem(Val(x))

using DataStructures  # provides DefaultDict

struct NaiveAlg <: SolveAlg end

function solve(::NaiveAlg, jobs)
    plan = Vector{Assignment}()

    # keep track of when machines are "free"
    free_at = DefaultDict{Machine,Instant}(0)

    for (jid, j) in enumerate(jobs)
        tend=0
        for (opid, op) in enumerate(j.ops)
            tstart = max(tend, free_at[op.machine])
            tend = tstart + op.process_time
            free_at[op.machine] = tend  # update free time of this machine
            push!(plan, Assignment(jid, opid, op.machine, tstart, tend))
        end
    end

    return plan
end

include_code("jssp/plot.jl") #hide

function run_naive()
    jobs = get_problem(:ortools_example)
    plan = solve(NaiveAlg(), jobs)
    span = makespan(plan)
    println("Solution makespan: $(span)")
    save(joinpath(@OUTPUT, "naive.png"), plot(plan); px_per_unit = 2) # hide
end

