## Script compatible with Literate.jl + Franklin.jl #hide
include(joinpath(pwd(), "utils.jl")) #hide

# Let's include the code we used in previous posts to define the data structures and 
# solve the problem using JuMP. We'll also include a helper that generate random JSSP 
# problem instances of a given size.

include_code("jssp/data.jl")
include_code("jssp/jump.jl")
include_code("jssp/problem_gen.jl")

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

    println("\nA random 3j x 3m problem")
    alg = ManneMIPAlg()
    spec = JSSProblemSpec(3, 3, 0:5, seed)
    jobs = get_problem(spec)
    @time solve(alg, jobs)


    println("\nA random 50j x 5m problem")
    alg = ManneMIPAlg()
    spec = JSSProblemSpec(50, 5, 0:5, seed)
    jobs = get_problem(spec)
    @time solve(alg, jobs)

    println("\nA random 100j x 10m problem")
    alg = ManneMIPAlg()
    spec = JSSProblemSpec(100, 10, 0:5, seed)
    jobs = get_problem(spec)
    @time solve(alg, jobs)

    println("\nBenchmark done!")
end

# ```julia:./code/bench1
# run_benchmark1()
# ```
#
# \textoutput{./code/jump1}
#
# We can see that the last `100j x 10m` problem took way more time than our `50j x 5m`
# instance despite being only 4x bigger! Let's try solving the same instance using 
# different solvers

include_code("jssp/solvers.jl")

function run_benchmark2()
    ort_jobs = get_problem(:ortools_example)
    spec = JSSProblemSpec(100, 10, 0:5, seed)
    jobs = get_problem(spec)
    
    println("\nA random 100j x 10m problem using SCIP")
    alg = ManneMIPAlg(:scip)
    solve(alg, ort_jobs) # warmup
    @time solve(alg, jobs)

    println("\nA random 100j x 10m problem using Gurobi")
    alg = ManneMIPAlg(:gurobi)
    solve(alg, ort_jobs) # warmup
    @time solve(alg, jobs)


end