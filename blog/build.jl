using Pkg
Pkg.activate(".")
Pkg.instantiate()

function finalize()
    cp("__site", joinpath("..", "out"))
end

using Franklin
Franklin.publish(final=finalize)
