#=

# Solving the Job Shop Scheduling Problem with Julia

This is the first in a series of posts exploring practical solutions to combinatorial 
optimization problems. In my `$dayjob` at BCG Gamma, the data science arm of [BCG](bcg.com) , 
we deal with a lot of problems that can be  classifed as or reduced to 
[combinatorial optimization](https://en.wikipedia.org/wiki/Combinatorial_optimization) (CO)
problems. These are **optimzation** problems that can be solved by picking a solution
from a discrete and finite (even if huge) set of options.

"Industrial" application of such optimization problems are the object of study 
of [operations research](https://en.wikipedia.org/wiki/Operations_research) discipline 
since the dawn of computing post World War II. Techniques to solving such problems have a number 
of real world applications. Improving airline schedules, reallocating aircrafts during aiport disruptions, 
improving yields in steelmaking operations, improving delivery routes of fuel trucks 
and finding optimal prices during markdown season in retail are some applictions I've
been personally involved.

This series of posts are my take on understanding and exploring this space, in particular
using [Julia](https://julialang.org/) a programming language designed for high performance
scientific computing. 

=#
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