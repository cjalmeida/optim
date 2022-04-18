@def date = "2022-04-16T11:00:00"

# Solving the Job Shop Scheduling Problem with Julia (part 2)

In the [previous post](/posts/jssp1/) we introduced the job shop scheduling problem 
(JSSP) and built some infrastructure for us to visualize solutions. If you haven't 
read it, I recommend you do it  first.

Our first naive solution to the example was quite poor. In this post we're going to use
a technique called [Mixed Integer Linear Programming (MILP)][milp] to solve this particular
instance to optimality.

## But what exactly is MILP

Let's start with the *linear programming* part. It's a technique that aims to minimize
(or maximize) a **linear function**, subject to **constraints** presented as linear
inequalities. The act of "modeling" a problem so it can be solvable via linear 
programming means turning it into a *canonical form* similar to the example below:

@@quote
A manufacturing plant have products **x** and **y**. The respective prices are **40** 
and **30**. The total manufacturing capacity is **12** tons combined. Product 
*x* consumes **2** times the amount of raw resources compared to *y*, and we have **16** tons of 
such resources. We need to find the amount of *x* and *y* to produce that **maximize** 
revenues.
@@

The problem above can be formulated in canonical form as:
$$
\begin{aligned}

\textrm{maximize} & \quad 40x + 30y \\
\textrm{subject to } 
& \quad x + y \le 12 \\
& \quad 2x + y \le 16 \\
& \quad x \ge 0 \\
& \quad y \ge 0 
\end{aligned}
$$

And the optimal solution to the above is $(x=4; y=5)$. Assuming the variables $x$ and $y$
can assume non-integer values, we can use algorithms such as [simplex] or [barrier]
to efficently solve such problems in polynomial time. But if we constrained any variable
to integer-only values, the problem becomes "hard" (ie. NP complexity) and large
instances will require more computing power. 

Fortunately for us, once we model the problem in the canonical form, we
can leverage a number of [commercial and open-source solvers][solvers] instead of 
writing the algorithms ourselves. Those implement a number of techniques to reduce the 
search space and can still find solution to MILPs in a resonable amount of time.

In this section we barely scratched the surface of (integer) linear programming. For 
those interested in digging deeper, [Prof. Pascal Van Hentenryck][pascal] gives a highly recommended
[Coursera online course][coursera]. For BCG GAMMA employees, 
check our internal *Learning and Development* offerings as frequently we have presential 
or online couses taught by Prof. Pascal himself.

## Formulating the JSSP as an Integer Linear Program 

I'm no modeling expert, so I'll refer to \cite{beck} to guide us into a 
proper formulation. The paper compares a *Disjunctive Model* to a *Time-indexed model*.
You can refer to the paper for more details on their differences, but for this post
we'll pick the *disjunctive model* they present in section *3.1* of the paper. 

This model was formulated by \cite{manne} and requires the following set 
of parameters:

- $J_n$: representing the $n$-th job in job list $J$
- $M_m$: representing the $m$-th machine in machine list $M$
- $\sigma^j_h$: representing the machine of the $h$-th operation of job $j$
- $p_{ij}$: representing the processing time of job $j$ in machine $i$
- $V$: a large enough number, assigned to $\sum_{j \in J}\sum_{i \in M}{p_{ij}}$

And this set of decision variables:
 
- $x_{ij}$ is the integer start time of job $j$ on machine $i$.
- $z_{ijk}$ is binary and equal to 1 if job $j$ precedes job $k$ on machine $i$.
- $C_{\max}$ is an the variable that stores the current makespan.

Thus, the models is formulated as:

$$
\begin{align}
\min. \quad         & C_{\max} \\
\textrm{s.t.} \quad & x_ij \ge 0 && \quad \forall j \in J, i \in M \\
                    & x_{\sigma^{j}_h,j} \ge x_{\sigma^{j}_{h-1},j} + p_{\sigma^{j}_{h-1},j} 
                        && \quad \forall j \in J, h=2..m \\
                    & x_{ij} \ge x_{ik} + p_{ik} - V \cdot z_{ijk} 
                        && \quad \forall j,k \in J, j \lt k, i \in M \\
                    & x_{ik} \ge x_{ij} + p_{ij} - V \cdot (1 - z{ijk}) 
                        && \quad \forall j,k \in J, j \lt k, i \in M \\
                    & C_{\max} \ge x_{\sigma^{i}_m,j} + p_{\sigma^{i}_m,j}
                        && \quad \forall j,k \in J, i \in M  \\
                    & z_{ijk} \in \{0, 1\}
\end{align}
$$

where:

- $(1)$ we state our objecive, to minimize the makespan,
- $(2)$ ensure times are non-negative,
- $(3)$ the *precedence constraint* ensures jobs are executed in the correct order,
- $(4)$ is one of the *disjunctive constraints* that ensure no two jobs are executed in the same machine
  at the same time,
- $(5)$ is the other *disjunctive constraint*,
- $(6)$ we ensure the makespan variable is set to the end time of the last job.
- $(7)$ constraint the variable $z$ to be binary.

If you find this complicated, don't worry. Coming up with these formulation 
is far from trivial and require some experience with the subject. For now, you can just
trust me (or better, \cite{manne}) that this formulation is correct. The important 
thing to notice now is that all equations are fully linear, ie. no exponentiation or 
cross-variable multiplication is allowed. As shown in $(4)$ and $(5)$ one requires 
clever tricks to express some non-trivial logic requirements.

Now comes the "easy" part, writing this formulation in Julia leveraging an existing
MILP solver.

## Writing a Julia MILP model with JuMP

While solvers come with their own (APIs) for building the model, pratictioners also
find it useful to use general purpose modelling languages or libraries that are 
somewhat agnostic of the underlying solver. Here we'll pick [JuMP][jump], a Julia package
that, in my opinion, is one of the best modeling interfaces available. Nothing 
I've ever used in Python or C++ comes even close to the expressiveness of JuMP.

JuMP support [many solvers][solvers] and for this exercise, we'll pick the 
open-source [Coin-OR's branch-and-cut solver (Cbc)][cbc]. Without further ado, let's 
get to the code.

@@quote
The source code is available at blog repo in 
[`blog/code/jssp/jump.jl`]({{blog_repo}}/blog/code/jssp/jump.jl)
@@

\literate{/code/jssp/jump.jl}


## References

- \biblabel{beck}{Ku, Beck (2016)} Ku, Wen-Yang, and J. Christopher Beck. "Mixed 
  integer programming models for job shop scheduling: A computational analysis." 
  Computers & Operations Research 73 (2016): 165-173. [PDF][beck]

- \biblabel{manne}{Manne (1960)} A. S. Manne, On the job-shop scheduling problem, 
  Operations Research (1960) 219–223.


[solvers]: https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers
[milp]: https://en.wikipedia.org/wiki/Integer_programming 
[simplex]: https://en.wikipedia.org/wiki/Simplex_algorithm
[barrier]: https://en.wikipedia.org/wiki/Interior-point_method
[pascal]: https://www.isye.gatech.edu/users/pascal-van-hentenryck
[coursera]: (https://www.coursera.org/learn/discrete-optimization)
[beck]: https://tidel.mie.utoronto.ca/pubs/JSP_CandOR_2016.pdf
[jump]: https://jump.dev/JuMP.jl/stable/
[cbc]: https://github.com/coin-or/Cbc