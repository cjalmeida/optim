## Script compatible with Literate.jl + Franklin.jl
include(joinpath(pwd(), "utils.jl")) #hide

# First, let's create the data structures for the problem and add some aliases and data structures
# to make the code more legible.
# 
# We'll also add data structures and aliases for the solution. We need to assign
# `(job, op)` to `machine` at a given start time `t_start`. We added `t_end` for
# convenience.

# \input{julia}{/code/jssp/data.jl}
include_code("jssp/data.jl") #hide

# Let's begin with the same problem presented in [OR-Tools tutorial](https://developers.google.com/optimization/scheduling/job_shop#example). 
# In this case, a "problem" consist of a list (`Vector`) of job instances. Each job 
# containing list of `Operation(machine, process_time)`. 

function get_problem(::Val{:ortools_example})
    return [
        Job([Op(1, 3), Op(2, 2), Op(3, 2)]),
        Job([Op(1, 2), Op(3, 1), Op(2, 4)]),
        Job([Op(2, 4), Op(3, 3)])
    ]
end

## This is a shortcut to avoid having to wrap symbols in Val
get_problem(x::Symbol) = get_problem(Val(x))

# We'll start by coding a feasible but very naive solution to get more intuition for the problem.
# The solution will simple iterate the job list and assign operations in sequence, 
# making sure we don't assign overlapping operations to machines.
#
# To leverage Julia's multiple dispatch, we'll create an empty `struct` named `NaiveAlg` 
# solution.

using DataStructures  # provides DefaultDict

struct NaiveAlg <: SolveAlg end

function solve(::NaiveAlg, jobs)
    plan = Vector{Assignment}()

    ## keep track of when machines are "free"
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

# A good way to visualize schedules is via "Gantt" charts. Let's create a plotting function
# using `DataFrames` the `Makie` plotting package. And `Query.jl` to make our code more
# expressive using functional operators.

# \input{julia}{/code/jssp/plot.jl}
include_code("jssp/plot.jl") #hide

# Putting everything together we can solve and plot our solution.
function run_naive()
    jobs = get_problem(:ortools_example)
    plan = solve(NaiveAlg(), jobs)
    span = makespan(plan)
    println("Solution makespan: $(span)")
    save(joinpath(@OUTPUT, "naive.png"), plot(plan); px_per_unit = 2) # hide
end
