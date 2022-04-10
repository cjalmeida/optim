include("../common/deps.jl")
include("../common/data.jl")
include("../common/plot.jl")
include("../common/problems.jl")

include("naive.jl")
include("jump.jl")

function main(problem, alg)
    # example from or-tools
    jobs = get_problem(problem)
    plan = solve(alg, jobs)
    span = makespan(plan)
    println("Solution found with makespan: $span")
    return plot(plan)
end

main_naive() = main(:ortools_example, NaiveAlg())
main_mip() = main(:ortools_example, ManneMIPAlg())

"""
    solve(alg, jobs)

Function for solving the Job Shop scheduling problem, where `jobs` is a vector of `Job`
instances.

Return a `plan` consisting of a vector of `Assignment`s. 
"""
function solve(alg::T, jobs) where {T<:SolveAlg} @error("Not Implemented") end

makespan(plan) = plan |> @map(_.t_end) |> maximum