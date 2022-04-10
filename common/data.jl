
const Machine = Int8
const Duration = Int64
const Instant = Int64
const OpId = Int16
const JobId = Int16

struct Op
    machine::Machine
    duration::Duration
end

struct Job
    id::Int
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