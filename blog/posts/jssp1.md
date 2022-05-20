@def date = "2022-04-16T10:00:00"

# Solving the Job Shop Scheduling Problem with Julia (part 1)

This is the first in a series of posts exploring practical solutions to combinatorial optimization problems. If you just landed here, the [home page] explains why those problems matter.

But before we dive into stating problems and finding solutions, let's talk a bit why I picked Julia for this series. You can [skip](#the_problem) the next section if you're already sold on Julia.

## Why Julia?

Nowadays, Python is arguably the most popular language for scientific computing, including solving optimization problems. Indeed, at my daily work I use Python in most of my projects. So, again, *Why Julia?* and *Why Julia instead of Python?*

Well, most importantly, I personally wanted to learn more about it :). That said, Julia is designed to solve a problem that hit me hard a couple of times: the *two languages problem*. Python is a very productive language but it's fundamentally slow. Whenever we need to make a Python algorithm fast, we need to rely on *native extensions* written in C/C++. This is usually not a problem as the ecosystem is huge, and a data scientist or ML engineer can find pre-packaged libraries for most of what they'd like to do.

But whenever you want to do something that the library developers did not anticipate you're in trouble. In one case, we needed to quickly build and solve many graph-related problems. Existing libraries would not fit the bill, and the custom Python code would be much slower than the equivalent C++ code. Writing fast, scalable *native extensions* in C/C++ is far from easy and not a skill you can naturally expect from a data scientist. This ends up creating the commonly seen two tiers of practitioners: one responsible for writing "experimental" research-grade code, and another responsible with translating this code into production. And in my opinion, this split creates a number of practical problems in maintainability.

Julia, however, was designed to solve this issue (among others). It's a [dynamic language](https://en.wikipedia.org/wiki/Dynamic_programming_language) with Python inspired syntax, thus easy to prototype and experiment. It supports [Jupyter Notebooks](https://github.com/JuliaLang/IJulia.jl) and has it's own *reactive* notebook system in [Pluto.jl]. But can be as fast as C/C++ with careful (but idiomatic) coding. The ecosystem is far from that of Python, but for the nice of scientific computing, it provides libraries that are considered state-of-the-art in their niche, eg. [JuMP] for mathematical programming and [DifferentialEquations.jl] for solving many kinds of differential equations. Also, interoperability is great, so you can bring your Python/C++ libraries along if you want.

But please don't think it's all roses and unicorns. Julia ecosystem is comparatively much smaller and less mature than Python. It has some known trade-offs that requires adaptation to your typical workflow. But when the stars align (and for this series of posts), Julia can make life easier compared to Python.

## The Job Shop Scheduling Problem (JSSP)

We'll use the standard version of the [Job Shop Scheduling Problem](https://en.wikipedia.org/wiki/Job-shop_scheduling) as our first example to guide us through. This archetypal problem can be found in numerous settings, ranging from actual manufacturing to distributed computing. Google OR-Tools package has a [very nice description](https://developers.google.com/optimization/scheduling/job_shop) of the problem:

@@quote
Each job consists of a sequence of tasks, which must be performed in a given order, and each task must be processed on a specific machine. For example, the job could be the manufacture of a single consumer item, such as an automobile. The problem is to schedule the tasks on the machines so as to minimize the length of the schedule—the time it takes for all the jobs to be completed.

There are several constraints for the job shop problem:

 - No task for a job can be started until the previous task for that job is completed.
 - A machine can only work on one task at a time.
 - A task, once started, must run to completion.
@@

We'll begin by creating a very naive solution to this problem, one that is feasible but far from optimal. This will allow us to introduce the Julia machinery and create some nice visualization.

## A naive solution

@@quote
Note this section is very code heavy. The source is available at blog repo:
[link]({{fill blog_repo}}/code/jssp/naive.jl)
@@

\literate{/code/jssp/naive.jl}

```julia:./code/naive
span = run_naive()
println("Solution makespan: $(span)")
```

\figalt{Naive}{naive.png}
\output{./code/naive}

The optimal makespan for this problem is `11`. As you can see from the above result
we can do much better.

## A brief discussion of optimization problems and solution algorithms

When trying to chart a solution to an optimization problem, it's very useful to try to understand [how complex the problem is in computational terms](https://en.wikipedia.org/wiki/Computational_complexity). If you're lucky, you will be able to apply one of many "exact algorithms" that are able to solve the problem in [polynomial time (**P**)](https://en.wikipedia.org/wiki/Time_complexity#Polynomial_time). In layman terms, this means such problems are "tractable", ie. even large instances can be solved to optimality using a reasonable amount of computing power. An special but very large class of problems are those that provably have a [convex solution space][convex]. This class includes [linear problems(LP)][linear], and have tractable solutions.


However, a lot of interesting problems fall into the so-called [**NP** class](https://en.wikipedia.org/wiki/NP_(complexity)) where no tractable algorithm was found and [likely never will](https://en.wikipedia.org/wiki/P_versus_NP_problem). This include the very important class of linear problems with solution that only accept integer values, known as [Mixed-Integer Linear Programming (MILP)](milp). This means that, to exactly solve large instances of such problems, you need huge amounts of computing power. Our job shop scheduling in one example of an *NP problem*. But we can still solve to optimality such problems if they're not too large. Increases in computing power and clever techniques have been pushing the limit of what's "solvable", and nowadays we are able to solve real-world instances that are quite large.

But it's not rare to find cases when finding an exact optimal solution is not feasible. In such situations, one can use so-called non-exact [**heuristics** algorithms](https://en.wikipedia.org/wiki/Heuristic_(computer_science)), that try to find solutions that (may be) close to the optimal. Usually such algorithms are much faster, but don't give you "hard" guarantees on how far the solution is from the optimal. Yet, they may be able to produce good solutions that work in practice.

We'll cover *heuristic approaches* later in the series. [In the part 2](/posts/jssp2/), 
we'll use [Mixed-Integer Linear Programming](milp), an *exact algorithm*, to solve our job shop example to optimality.

[home page]: /
[milp]: https://www.gurobi.com/resource/mip-basics/
[linear]: https://en.wikipedia.org/wiki/Linear_programming
[convex]: https://www.solver.com/convex-optimization
[JuMP]: https://jump.dev/JuMP.jl/stable/
[DifferentialEquations.jl]: https://diffeq.sciml.ai/dev/index.html
[Pluto.jl]: https://github.com/fonsp/Pluto.jl