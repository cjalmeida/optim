# This file was generated, do not modify it. # hide
function run_naive()
    jobs = get_problem(:ortools_example)
    plan = solve(NaiveAlg(), jobs)
    span = makespan(plan)
    println("Solution makespan: $(span)")
    save(joinpath(@OUTPUT, "naive.png"), plot(plan); px_per_unit = 2) # hide
end