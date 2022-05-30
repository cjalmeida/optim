## Script compatible with Literate.jl + Franklin.jl #hide
include(joinpath(pwd(), "utils.jl")) #hide

# Let's start by loading the same data structures, example problem and plotting functions we
# created for the part 1. The `include_code` function, defined in `utils.jl` ensures we can use 
# `include` pointing to the correct code path.

include_code("jssp/data.jl")
include_code("jssp/problem_ort.jl")
include_code("jssp/plot.jl")

## We can use `JuMP` and `Cbc` as usual.
using JuMP
using Cbc

# Now let's add a couple of helper functions to transform our original input 
# `jobs::Vector{Job}` into the parameters we expect for the formulation.

"""List of machine indexes in the problem."""
machines(jobs::Vector{Job}) = jobs |>
                              @map(_.ops) |>
                              Iterators.flatten |>
                              @map(_.machine) |>
                              @unique() |>
                              collect

"""
Return the 2D-array `σ[j=job, h=1:m] -> i` representing the order `h` of execution 
for job `j` at given machine `i`. 

If a job is not assigned to any machine, assign to a non-used machine (expect 0 
process_time).
"""
function operations(jobs::Vector{Job})
    n = length(jobs)
    M = machines(jobs)
    m = length(M)
    σ = Array{Int}(undef, (n, m))
    for j in 1:n
        avail = ones(Bool, m)
        ops = jobs[j].ops
        n_ops = length(ops)
        for h = 1:m
            i = if h <= n_ops 
                ops[h].machine 
            else 
                findfirst(avail)
            end
            avail[i] = false
            σ[j, h] = i
        end
    end
    return σ
end

"""Return a lookup matrix of `S[i=machine, j=job] -> h` where h is the op sequence 
number (id)."""
function job_machine_to_op(jobs::Vector{Job})
    n = length(jobs)
    m = length(machines(jobs))
    lookup = zeros(Int, (m, n))
    for j in 1:n
        for (h, op) in enumerate(jobs[j].ops)
            lookup[op.machine, j] = h
        end
    end
    return lookup
end

"""The processing time, as a `p[i=machine, j=job] -> t=time` matrix"""
function processing_time(jobs::Vector{Job})
    n = length(jobs)
    m = length(machines(jobs))
    p = zeros((m, n))  # p_(i,j)
    for j in 1:n
        for op in jobs[j].ops
            i = op.machine
            p[i, j] = op.process_time
        end
    end
    return p
end

# Now we can start building the model that matches the standard form.

## Declare the algo type
struct ManneMIPAlg <: SolveAlg
    solver::Symbol
    ManneMIPAlg() = new(:cbc)  # defaults solver to Cbc
    ManneMIPAlg(solver) = new(solver)  # defaults solver to Cbc
end

## Solver get/close functions

get_solver(alg::ManneMIPAlg) = get_solver(alg, Val(alg.solver))
close_solver(alg::ManneMIPAlg) = close_solver(alg, Val(alg.solver))
close_solver(::ManneMIPAlg, ::Val) = nothing

## Configure Cbc solver
function get_solver(::ManneMIPAlg, ::Val{:cbc})
    return optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0)
end

""" Build a JSSP MP model using Manne formulation.

Based on A.S. Manne disjunctive formulation.

See:
    Ku, Wen-Yang & Beck, J.. (2016). Mixed Integer Programming Models for 
    Job Shop Scheduling: A Computational Analysis. Computers & Operations Research. 
    73. 10.1016/j.cor.2016.04.006. https://tidel.mie.utoronto.ca/pubs/JSP_CandOR_2016.pdf
"""
function build_model(alg::ManneMIPAlg, jobs::Vector{Job})

    ## Create a new model
    solver = get_solver(alg)
    model = Model(solver)
    set_time_limit_sec(model, 15.0)

    #####################
    ## Problem parameters
    J = 1:length(jobs)
    M = machines(jobs)

    n = length(J)
    m = length(M)

    σ = operations(jobs)       ## σ[j=job, h=op_seq] -> j=machine
    p = processing_time(jobs)  ## p[i=machine, j=job] -> t=time

    ## The upper bound of makespan to use in the disjunctive constraints
    V = sum(p)

    #####################

    ## variable indicating the start time of job j in machine i, we also add (C2) as upper bound.
    @variable(model, 0 <= x[i=1:m, j=1:n])

    ## binary variable indicating job j precedes job k on machine i. 
    ## Constraint to binary domain (7)
    @variable(model, z[i=1:m, j=1:n, k=1:n], Bin)

    ## aux variable for makespan
    @variable(model, C)

    ## (1) minimize makespan aux var
    @objective(model, Min, C)

    ## (3) Precedence constraint. It ensures that all operations of a job are executed 
    ## in the given order.
    @constraint(model,
        c3[j ∈ J, h = 2:m; p[σ[j, h-1], j] > 0],       # ∀ j ∈ J, h = 2,...,m
        x[σ[j, h], j]           # start time of i=(ℎ-th op) of job 𝑗
        ≥
        x[σ[j, h-1], j] +       # start time of antecedent op
        p[σ[j, h-1], j]         # process time of antecedent op
    )

    ## Disjunctive constraints (4) and (5) to ensure that no two jobs can be scheduled on 
    ## the same machine at the same time.
    @constraint(model,
        c4[i ∈ M, j ∈ J, k ∈ J; j < k && p[i, k] > 0],
        x[i, j] ≥ x[i, k] + p[i, k] - V * z[i, j, k]
    )
    @constraint(model,
        c5[i ∈ M, j ∈ J, k ∈ J; j < k && p[i, j] > 0],
        x[i, k] ≥ x[i, j] + p[i, j] - V * (1 - z[i, j, k])
    )

    ## (6) to ensures that the makespan is at least the largest completion time of the last
    ## operation of all jobs
    @constraint(model,
        c6[j ∈ J],
        C ≥ x[σ[j, m], j] + p[σ[j, m], j]
    )

    return model, x, m, n, p
end


# With the model built, we can call `optimize!` to get a solution. It checks for the 
# termination status and returns `nothing` if we were not able to solve the model.

"""
Solves the job shop scheduling problem using a MIP approach. 
"""
function solve(alg::ManneMIPAlg, jobs::Vector{Job})

    model, x, m, n, p = build_model(alg, jobs)

    ## optimize to find minimum start times
    optimize!(model)

    term = termination_status(model)
    if term != OPTIMAL
        stat = raw_status(model)
        println("WARN: Solver finished with status $(term)")
        println("WARN: Message from solver $(stat)")
        return nothing
    end

    ## collect back the decisions on start time
    t = Int.(round.(value.(x)))

    ## convert decision variables to assignments
    op_table = job_machine_to_op(jobs)
    plan = Vector{Assignment}()
    for i in 1:m, j in 1:n
        ## if process time is non-zero, we create an assignment
        if p[i, j] > 0
            h = op_table[i, j]
            t_start = t[i, j]
            t_end = t[i, j] + p[i, j]
            a = Assignment(j, h, i, t_start, t_end)
            push!(plan, a)
        end
    end

    ## close solver if needed
    close_solver(alg)

    return plan
end

# Again, let's wrap everything together.

function run_jump1()
    jobs = get_problem(:ortools_example)
    plan = solve(ManneMIPAlg(), jobs)
    span = makespan(plan)
    save(joinpath(@OUTPUT, "jump1.png"), plot(plan); px_per_unit=2) # hide
    return span
end