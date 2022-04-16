# This file was generated, do not modify it. # hide
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
            tend = tstart + op.duration
            free_at[op.machine] = tend  # update free time of this machine
            push!(plan, Assignment(jid, opid, op.machine, tstart, tend))
        end
    end

    return plan
end