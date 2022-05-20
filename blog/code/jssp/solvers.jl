# Add extra solvers

using SCIP

## Configure SCIP solver
function get_solver(::ManneMIPAlg, ::Val{:scip})
    return optimizer_with_attributes(SCIP.Optimizer, "display/verblevel" => 0)
end

## Configure SCIP solver
function get_solver(::ManneMIPAlg, ::Val{:gurobi})
    return optimizer_with_attributes(SCIP.Optimizer, "display/verblevel" => 0)
end
