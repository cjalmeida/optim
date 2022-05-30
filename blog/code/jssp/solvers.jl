# Add extra solvers

using SCIP
using Gurobi
using HiGHS
using ConfigEnv

# load .env config, this will likely hold GRB_LICENSE_FILE
dotenv()

## Configure SCIP solver
function get_solver(::ManneMIPAlg, ::Val{:scip})
    return optimizer_with_attributes(SCIP.Optimizer, "display/verblevel" => 0)
end

GRB_ENV = Ref{Gurobi.Env}()

## Configure Gurobi solver
function get_solver(::ManneMIPAlg, ::Val{:gurobi})
    # We'll try to initialize the gurobi solver but fail gracefully if not available
    # At the time of this writing, by default it comes pre-installed with Gurobi 9.5
    # but you may change it by following the docs.
    #
    # Otherwise, it's regular Gurobi usage (eg. setting up GRB_LICENSE_FILE var, etc.)
    try
        if !isdefined(GRB_ENV, 1)
            GRB_ENV[] = Gurobi.Env(started=false)
            GRBsetintparam(GRB_ENV[], "OutputFlag", 0)
            GRBstartenv(GRB_ENV[])
        end
        env = GRB_ENV[]

        opt = optimizer_with_attributes(() -> Gurobi.Optimizer(env))

        return opt
    catch e
        @show e
        println("Could not initialize Gurobi solver. Returning nothing")
        # return nothing
        throw(e)
    end
end


## Configure HiGHS solver
function get_solver(::ManneMIPAlg, ::Val{:highs})
    return optimizer_with_attributes(HiGHS.Optimizer, "log_to_console" => false)
end
