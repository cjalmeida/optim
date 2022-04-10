
num_machines(plan) = plan |> @map(_.machine) |> @unique() |> @count()

function plot(plan::Plan)
    df = DataFrame(plan)
    fig = Figure()
    colors = cgrad(:tab10)

    ax = Axis(
        fig[1, 1],
        ylabel="Machine",
        xlabel="Time",
        height=150,
        width=700,
        yticks=LinearTicks(num_machines(plan))
    )
    barplot!(
        df.machine,
        df.t_end,
        fillto=df.t_start,
        direction=:x,
        color=colors[df.jobId],
        width=0.75,
    )
    labels = ["$j.$o" for (j, o) in zip(df.jobId, df.op)]
    text!(
        labels,
        position=Point2f.(
            (df.t_start .+ 0.1),
            df.machine
        ),
        textsize=11,
        color="#ffffff",
        align=(:left, :center)
    )


    return fig
end
