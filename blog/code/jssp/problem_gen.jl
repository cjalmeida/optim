using Random

struct JSSProblemSpec
    n_jobs::JobId
    n_machines::Machine
    process_time::UnitRange{Int}
    seed::Int64
end

function get_problem(spec::JSSProblemSpec)
    ## initialize the seed
    Random.seed!(spec.seed)
    
    # generate a random problem
    M = collect(1:spec.n_machines)
    jobs = Job[]
    for _ in 1:spec.n_jobs
        machines = shuffle(M)
        ptimes = rand(spec.process_time, spec.n_machines)
        ops = Op[]
        for (m, p) in zip(machines, ptimes)
            if p == 0
                continue
            end
            op = Op(m, p)
            push!(ops, op)
        end
        job = Job(ops)
        push!(jobs, job)
    end
    return jobs
end