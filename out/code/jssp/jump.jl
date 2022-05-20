using JuMP
using Cbc

struct ManneMIPAlg <: SolveAlg end
const Jobs = Vector{Job}


machines(jobs::Jobs) = jobs |> @map(_.ops) |> Iterators.flatten |> @map(_.machine) |> @unique() |> collect

"""
Operations as `O[j=job, h=1:m] -> i` representing the order `h` of execution 
for job `j` at given machine `i`. 

If a job is not assigned to any machine, we assign it to machine `1` (expecting 0.0 process_time).
"""
function operations(jobs::Jobs)
    n = length(jobs)
    m = length(machines(jobs))
    O = ones(Int, (m, n))
    for j in 1:n
        for (h, op) in enumerate(jobs[j].ops)
            O[j, h] = op.machine
        end
    end
    return O
end

"""Return a lookup matrix of `[i=machine, j=job] -> h` where h is the op sequence number (id)."""
function job_machine_to_op(jobs::Jobs)
    n = length(jobs)
    m = length(machines(jobs))
    lookup = zeros(Int, (m, n))  # p_(i,j)
    for j in 1:n
        for (h, op) in enumerate(jobs[j].ops)
            lookup[op.machine, j] = h
        end
    end
    return lookup
end

"""The processing time, as a `p[i=machine, j=job] -> time` matrix"""
function processing_time(jobs::Vector{Job})
    n = length(jobs)
    m = length(machines(jobs))
    p = zeros((n, m))  # p_(i,j)
    for j in 1:n
        for op in jobs[j].ops
            i = op.machine
            p[i, j] = op.process_time
        end
    end
    return p
end

"""
Solves the job shop scheduling problem using a MIP approach.

We expect the `jobs` to be typical where a job have at most one operation per machine.

Based on A.S. Manne disjunctive formulation.

See:
    Ku, Wen-Yang & Beck, J.. (2016). Mixed Integer Programming Models for Job Shop Scheduling: A Computational Analysis. 
    Computers & Operations Research. 73. 10.1016/j.cor.2016.04.006.
    https://tidel.mie.utoronto.ca/pubs/JSP_CandOR_2016.pdf

"""
function solve(alg::ManneMIPAlg, jobs::Vector{Job})
    
    model, x = build_model(alg, jobs)

    # optimize to find minimum start times
    optimize!(model)

    # decision on start time
    t = Int.(round.(value.(x)))
    
    # convert this to assignments format
    op_table = job_machine_to_op(jobs)
    plan = Vector{Assignment}()
    for i in 1:m, j in 1:n
        # if process time is non-zero
        if p[i, j] > 0
            h = op_table[i, j]
            t_start = t[i, j]
            t_end = t[i, j] + p[i, j]
            a = Assignment(jobs[j].id, h, i, t_start, t_end)
            push!(plan, a)
        end
    end
end

function build_model(alg::ManneMIPAlg, jobs::Vector{Job})
    model = Model(Cbc.Optimizer)

    J = 1:length(jobs)         
    M = machines(jobs)

    n = length(J)
    m = length(M)

    σ = operations(jobs)       # σ[j=job, h=op_seq] -> j=machine
    p = processing_time(jobs)  # p[i=machine, j=job] -> t=time

    # The upper bound of makespan to use in the disjunctive constraints
    V = sum(p)

    # variable indicating the start time of job j in machine i, we also add (C2) as upper bound.
    @variable(model, 0 <= x[i=1:m, j=1:n])

    # binary variable indicating job j precedes job k on machine i. 
    # Constraint to binary domain per (C7)
    @variable(model, z[i=1:m, j=1:n, k=1:n], Bin)

    # aux variable for makespan
    @variable(model, C)
    
    # (O1) minimize makespan aux var
    @objective(model, Min, C)

    # (C3) Precedence constraint. It ensures that all operations of a job are executed 
    # in the given order.
    @constraint(model,
        [j = 1:n, h = 2:m],       # ∀ j ∈ J, h = 2,...,m
        x[σ[j, h], j]           # start time of i=(ℎ-th op) of job 𝑗
        ≥
        x[σ[j, h-1], j] +       # start time of antecedent op
        p[σ[j, h-1], j]         # process time of antecedent op
    )

    # Disjunctive constraints (C4) and (C5) to ensure that no two jobs can be scheduled on 
    # the same machine at the same time.
    @constraint(model,
        [i ∈ M, j ∈ J, k ∈ J; j < k],
        x[i, j] ≥ x[i, k] + p[i, k] - V * z[i, j, k]
    )
    @constraint(model,
        [i ∈ M, j ∈ J, k ∈ J; j < k],
        x[i, k] ≥ x[i, j] + p[i, j] - V * (1 - z[i, j, k])
    )

    # (C6) to ensures that the makespan is at least the largest completion time of the last
    # operation of all jobs
    @constraint(model,
        [j ∈ J],
        C ≥ x[σ[j, m], j] + p[σ[j, m]]
    )

    return model, x
end