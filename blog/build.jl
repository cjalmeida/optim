using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Franklin

function build()
    Franklin.publish()
end
