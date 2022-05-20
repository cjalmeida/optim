const Machine = Int8
const Duration = Int32
const Instant = Int32
const OpId = Int16
const JobId = Int16

# An operation within a job. 
# Op id's are inferred from their index in the job "ops" vector.
struct Op
    machine::Machine
    process_time::Duration
end

# An operation within a problem. 
# Job id's are inferred from their index in the problem vector.
struct Job
    ops::Vector{Op}
end

struct Assignment
    job::Int
    op::OpId
    machine::Machine
    t_start::Instant
    t_end::Instant
end

const JSSProblem = Vector{Job}
const Plan = Vector{Assignment}

# Base type for solving algorithms
abstract type SolveAlg end

