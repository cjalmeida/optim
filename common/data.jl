
struct Op
    machine::Machine
    duration::Duration
end

struct Job
    ops::Vector{Op}
end

Base.show(io::IO, j::Job) = print(io, "Job($(j.id))")

# solution domain

struct Assignment
    jobId::Int
    op::OpId
    machine::Machine
    t_start::Instant
    t_end::Instant
end

const Plan = Vector{Assignment}

# algorithms types

abstract type SolveAlg end