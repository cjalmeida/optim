function get_problem(::Val{:ortools_example})
    return [
        Job([Op(1, 3), Op(2, 2), Op(3, 2)]),
        Job([Op(1, 2), Op(3, 1), Op(2, 4)]),
        Job([Op(2, 4), Op(3, 3)])
    ]
end

## This is a shortcut to avoid having to wrap symbols in `Val`
get_problem(x::Symbol) = get_problem(Val(x))
