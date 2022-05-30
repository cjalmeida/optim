using CairoMakie
using DataFrames
using Query

num_machines(plan) = plan |> @map(_.machine) |> @unique() |> @count()

makespan(plan) = plan |> @map(_.t_end) |> maximum

function plot(plan::Plan)
    ## A `Vector{Assignment}` can be easily converted to a `DataFrame`
    df = DataFrame(plan)

    ## Like matplotlib, create a color pallet, and figure and axis objects for layouting
    colors = cgrad(:tab10)
    fig = Figure(resolution=(700, 200))
    ax = Axis(
        fig[1, 1],
        ylabel="Machine",
        xlabel="Time",
        yticks=1:num_machines(plan),
        xticks=0:makespan(plan)
    )

    ## Let's add a barplot showing the machine assignments. The `(x, y)` axis seem 
    ## because we want to show a horizontal chart inverted.
    barplot!(
        df.machine,             # actual y-axis
        df.t_end,               # x (end)
        fillto=df.t_start,      # x (start)
        direction=:x,
        color=colors[df.job],
        width=0.75,
    )

    ## Add labels to the bars to help track jobs
    labels = ["$j.$o" for (j, o) in zip(df.job, df.op)]
    positions=Point2f.((df.t_start .+ 0.1), df.machine)
    text!(
        labels,
        position=positions,
        textsize=9,
        color="#ffffff",
        align=(:left, :center)
    )
    return fig
end

plot(plan, out::String) = save(out, plot(plan); px_per_unit=2) # hide