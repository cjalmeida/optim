using PythonCall

include("data.jl")
include("jump.jl")

function build_model(alg::CpOrtools, jobs::Vector{Job})
    cp_model = pyimport("ortools.sat.python.cp_model")

    #####################
    ## Problem parameters
    J = 1:length(jobs)
    M = machines(jobs)

    n = length(J)
    m = length(M)

    σ = operations(jobs)       ## σ[j=job, h=op_seq] -> j=machine

    ## The upper bound of makespan to use when declaring variables
    V = sum(p)

    #####################

    model = cp_model.CpModel()

    ## Create start, end variables, where j=job, i=machine, t=time
    s = Array{Py}(undef, (n, m))  ## start: s[j, i] = t
    e = Array{Py}(undef, (n, m))  ## end: e[j, i] = t

    ## Create CP interval variables for the no-overlap constraint
    r = Array{Py}(undef, (n, m))  ## end: r[j, i] = interval(s, d, e)

    ## Fill the variables from the input
    for j ∈ J
        for (h, op) ∈ enumerate(jobs[j].ops)
            m = op.machine
            d = op.process_time
            suffix = "$(j)_$(h)"
            s_var = model.NewIntVar(0, V, "s_$suffix")
            e_var = model.NewIntVar(0, V, "e_$suffix")
            r_var = model.NewIntervalVar(s_var, d, e_var, "r_$suffix")
            s[j, i] = s_var
            e[j, i] = e_var
            r[j, i] = r_var
        end
    end

    ## Aux variable for makespan
    C = model.NewIntVar(0, horizon, "makespan")

    ## Add the no-overlap disjunctive constraint. This ensures that for a given machine
    ## no overlapping intervals are allowed.
    for i ∈ M
        model.AddNoOverlap(r[:, i])
    end

    ## The precedence constraint. The start time (s) of the a given operation (h) 
    ## must come after the end time (e) of the preceding operation (h-1) 
    for j ∈ J, h = 2:m
        m_oper = σ[j, h]
        m_prec = σ[j, h-1]
        model.Add(s[j, m_oper] >= e[m_prec, j])
    end

    ## objective: minimize makespan aux var
    model.AddMaxEquality(obj_var, [
    all_tasks[job_id, len(job) - 1].end
    last = Vector{Py}()
    for j ∈ J, h ∈ 1:m
        if j.ops[h]
        last_e = e[]
    end

])


end