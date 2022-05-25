using Query
using Franklin
using Dates
using Markdown

function include_code(fname)
  include(joinpath(pwd(), "code", fname))
end

function post_params(fname)
  title = nothing
  for line in readlines(fname)
    line = strip(line)
    if startswith(line, "@def")
      expr = strip(chop(line, head=4, tail=0))
      eval(Meta.parse(expr))
    end

    if startswith(line, "# ")
      title = strip(chop(line, head=2, tail=0))
    end
  end

  return parse(DateTime, date), title
end

function hfun_allposts()
  posts = readdir("posts") |> 
    @filter(endswith(_, ".md")) |>
    @map(joinpath("posts", _)) |>
    @map((post_params(_)..., _)) |>
    collect
  
  sort!(posts, rev=false)
  
  names = posts |> 
    @map(last(splitpath(last(_)))) |>
    @map(first(splitext(_))) |>
    collect

  io = IOBuffer()
  write(io, "<ul>\n")
  fmt = dateformat"yyyy-mm-dd"

  for (i, (date, title, post)) in enumerate(posts)
    fi = "/posts/" * names[i]
    dt = Dates.format(date, fmt)
    write(io, """<li><a href="$fi">$dt - $title</a></li>\n""")
  end
  write(io, "</ul>\n")
  return String(take!(io))
end