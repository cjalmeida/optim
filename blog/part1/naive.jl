struct NaiveAlg <: SolveAlg end

"""
This creates a very bad schedule but feasible schedule by assigning the jobs to each machine in sequence.
"""
function solve(::NaiveAlg, jobs::Vector{Job})
    plan = Vector{Assignment}()

    free_at = DefaultDict{Machine,Instant}(0)

    for j in jobs
        t = 0
        for (idx, op) in enumerate(j.ops)
            tstart = max(t, free_at[op.machine])
            tend = tstart + op.duration
            t = tend
            free_at[op.machine] = tend
            push!(plan, Assignment(j.id, idx, op.machine, tstart, tend))

        end
    end

    maxtime = maximum(values(free_at))

    return plan, maxtime
end
