@def date = "2022-05-19T12:00:00"
@def literate_mds = true

# Discrete optimization problems with Julia. Part 3: Benchmarking

In the [previous post](/posts/jssp2/) we solved the archetypical job shop scheduling problem (JSSP) using [Mixed Integer Linear Programming (MILP)][milp]. But the problem instance was very small. Now let's explore some of the scaling issues when solving integer programming problems.

@@quote
The source code is available at blog repo:
[link]({{fill blog_repo}}/code/jssp/benchmark.jl)
@@

\literate{/code/jssp/benchmark.jl}

This example is small and contrived; and tests a only single instance of the job-shop scheduling problem. In Section 4 of the paper, \cite{beck} do more extensive analysis. Compare the time of to solve `8j x 8m` instances, less than a second on average, vs `12j x 12m` instances, that took as much as 212 seconds on the fastest solver!

## On MILP solvers


Commercial solvers have thousands of PhD hours poured in to [implement heuristics][heur] such as identifying special structures, "presolving", removing redundant constraints and others that improve the search time required to find a solution. Looking at [Hans Mittelman benchmarks for MILP][bench] solvers, Gurobi is generally ahead of open-source solvers [^1], and this also matches my experience in real-world projects.

However, in a lot of cases open-source (and the semi-commercial SCIP) solvers are very useful. For instance, Gurobi/CPLEX/Xpress can be quite expensive and licensing can be limiting. One example is when you need to run multiple optimizations in parallel for simulating different parameters, or as part of a custom search procedure (eg. [column generation][colgen]). You can use cloud providers to spin up hundreds of CPU cores without any license limit. Moreover, while commercial solvers can be 10x or 20x times faster than their OS counterparts, it does not change the fact that NP problems scale exponentially in the worst case. The bottom line is that, in the world of discrete optimization, the fastest MILP solver may not always be the best solver for a particular problem. 

In fact, while MILP is among the most commonly used technique to solve discrete optimization problems, it might not even be the right tool for the job. This series of posts are not (only) about MILP solvers. Here's where the fun begin we start exploring other methods for solving such problems. In the [next post][next], we'll talk about more general [constraint programming][cp] solvers.

## References

- \biblabel{beck}{Ku, Beck (2016)} Ku, Wen-Yang, and J. Christopher Beck. "Mixed
  integer programming models for job shop scheduling: A computational analysis."
  Computers & Operations Research 73 (2016): 165-173. [PDF][beck]

[^1]: Note CPLEX and Xpress decided not to participate in the benchmarks.

[milp]: https://en.wikipedia.org/wiki/Integer_programming
[bench]: http://plato.asu.edu/ftp/milp.html
[colgen]: https://optimization.mccormick.northwestern.edu/index.php/Column_generation_algorithms
[next]: /code/jssp4
[heur]: https://or.stackexchange.com/questions/5150/what-are-the-advantages-of-commercial-solvers-like-gurobi-or-xpress-over-open-so
[cp]: https://en.wikipedia.org/wiki/Constraint_programming
[beck]: https://tidel.mie.utoronto.ca/pubs/JSP_CandOR_2016.pdf