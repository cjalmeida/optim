## Script compatible with Literate.jl + Franklin.jl #hide
include(joinpath(pwd(), "utils.jl")) #hide

# Let's include the code we used in previous posts to define the data structures and 
# solve the problem using JuMP. We'll also include a helper that generate random JSSP 
# problem instances of a given size.

include_code("jssp/data.jl")
include_code("jssp/jump.jl")
include_code("jssp/problem_gen.jl")
include_code("jssp/solvers.jl")

using Random

const seed = 42

# Now let's write code to run the benchmark.

function run_benchmark1()

    println("Sanity check on ORTools example")
    alg = ManneMIPAlg()
    jobs = get_problem(:ortools_example)
    solve(alg, jobs)  ## warmup
    plan = @time solve(alg, jobs)
    @assert makespan(plan) == 11

    println("\nA random 5j x 4m problem")
    alg = ManneMIPAlg()
    spec = JSSProblemSpec(5, 4, 0:5, seed)
    jobs = get_problem(spec)
    plan = @time solve(alg, jobs)

    println("\nA random 8j x 5m problem")
    alg = ManneMIPAlg()
    spec = JSSProblemSpec(8, 5, 0:5, seed)
    jobs = get_problem(spec)
    plan = @time solve(alg, jobs)

    println("\nBenchmark done!")
end

md"""
```julia:./code/bench1
run_benchmark1()
```
\output{./code/bench1}
"""

# We can see that the last `8j x 5m` problem did not finished in the alloted time (15s)
# despite being only 2x "bigger" then the `5j x 4m` instance! Let's try solving the same instance using 
# different solvers. We'll use SCIP, a solver that's free for non-commercial uses. I 
# have access to a Gurobi license so I'll also try it.

function run_benchmark2()
    ort_jobs = get_problem(:ortools_example)
    size = "8j x 5m"
    spec = JSSProblemSpec(8, 5, 0:5, seed)
    jobs = get_problem(spec)

    println("\nA random $size problem using SCIP")
    alg = ManneMIPAlg(:scip)
    solve(alg, ort_jobs) # warmup
    plan = @time solve(alg, jobs)

    println("\nA random $size problem using HiGHS")
    alg = ManneMIPAlg(:highs)
    solve(alg, ort_jobs) # warmup
    plan = @time solve(alg, jobs)

    try
        println("\nA random $size problem using Gurobi")
        alg = ManneMIPAlg(:gurobi)
        solve(alg, ort_jobs) # warmup
        plan = @time solve(alg, jobs)
    catch e
        @show e
        println("Could not run benchmark on Gurobi")
    end
end

md"""
```julia:./code/bench2
run_benchmark2()
```

\output{./code/bench2}
"""
