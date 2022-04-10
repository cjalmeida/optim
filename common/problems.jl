get_problem(x::Symbol) = get_problem(Val(x))

"""Example JobShop problem from OR-Tools"""
function get_problem(::Val{:ortools_example})
    return [
        Job(1, [Op(1, 3), Op(2, 2), Op(3, 2)]),
        Job(2, [Op(1, 2), Op(3, 1), Op(2, 4)]),
        Job(3, [Op(2, 4), Op(3, 3)])
    ]
end