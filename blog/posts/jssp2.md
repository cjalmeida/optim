@def date = "2022-04-16T11:00:00"

# Discrete optimization problems with Julia. Part 2: Mixed Integer Linear Programming

In the [previous post](/posts/jssp1/) we introduced the job shop scheduling problem (JSSP) and built some infrastructure for us to visualize solutions. If you haven't read it, I recommend you do it first.Our naive solution to the example was quite poor. In this post we're going to use a technique called [Mixed Integer Linear Programming (MILP)][milp] to solve this particular instance to optimality. Beware, this is where things start to get math-heavy!

## Crash-course on Mixed Integer Linear Programming

Let's start with the _linear programming_ part. It's a technique that aims to minimize (or maximize) a **linear function**, subject to **constraints** presented as linear inequalities. The act of "modeling" a problem so it can be solvable via linear programming means turning it into a _standard form_ similar to the example below:

@@quote
A manufacturing plant have products **x** and **y**. The respective prices are **40** and **30**. The total manufacturing capacity is **12** tons combined. Product _x_ consumes **2** times the amount of raw resources compared to _y_, and we have **16** tons of such resources. We need to find the amount of _x_ and _y_ to produce that **maximize**
revenues.
@@

The problem above can be formulated in standard form as:

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

And the optimal solution to the above is $(x=4; y=5)$. Assuming the variables $x$ and $y$ can assume non-integer values, we can directly use algorithms such as [simplex] or [interior point methods][barrier] to efficiently solve such problems in polynomial time. But if we constrained any variable to integer-only values, the problem becomes "hard" (ie. NP complexity) and large instances will require more computing power.

Integer solutions are arguably a more limited domain than real solution. The fact it's harder to find integer solutions seems unintuitive. But in fact, we have many techniques to optimize continuous functions, many of them from _calculus_. And in particular when the solution space is [convex]. Integer problems are neither continuous or convex, but the algorithms for solving them can leverage information gained by **relaxing** the integer requirement.

Once we model the problem in the standard form, we can use a number of [commercial and open-source solvers][solvers] instead of writing the algorithms ourselves. Those implement a algorithms to reduce the search space and can still find solution to MILPs in a reasonable amount of time for some practical applications.

In this section we barely scratched the surface of (integer) linear programming. For those interested in digging deeper, [Prof. Pascal Van Hentenryck][pascal] gives a highly recommended [Coursera online course][coursera]. For BCG GAMMA employees, check our internal _Learning and Development_ offerings as frequently we have presential or online courses taught by Prof. Pascal himself.

## Formulating the JSSP as an Integer Linear Program

I'm no modeling expert, so I'll refer to \cite{beck} to guide us into a proper formulation. The paper compares a _Disjunctive Model_ to a _Time-indexed model_. You can refer to the paper for more details on their differences, but for this post we'll pick the _disjunctive model_ they present in section _3.1_ of the paper.

This model was formulated by \cite{manne} and requires the following set of parameters:

- $J_n$: representing the $n$-th job in job list $J$
- $M_m$: representing the $m$-th machine in machine list $M$
- $\sigma^j_h$: representing the machine of the $h$-th operation of job $j$
- $p_{ij}$: representing the processing time of job $j$ in machine $i$
- $V$: a large enough number, assigned to $\sum_{j \in J}\sum_{i \in M}{p_{ij}}$

And this set of decision variables:

- $x_{ij}$ is the integer start time of job $j$ on machine $i$.
- $z_{ijk}$ is binary and equal to 1 if job $j$ precedes job $k$ on machine $i$.
- $C_{\max}$ is the variable that stores the current makespan.

Thus, the models is formulated as:

$$
\begin{align}
\min. \quad         & C_{\max} \\
\textrm{s.t.} \quad & x_ij \ge 0 && \quad \forall j \in J, i \in M \\
                    & x_{\sigma^{j}_h,j} \ge x_{\sigma^{j}_{h-1},j} + p_{\sigma^{j}_{h-1},j}
                        && \quad \forall j \in J, h=2..m \\
                    & x_{ij} \ge x_{ik} + p_{ik} - V \cdot z_{ijk}
                        && \quad \forall j,k \in J, j \lt k, i \in M \\
                    & x_{ik} \ge x_{ij} + p_{ij} - V \cdot (1 - z_{ijk})
                        && \quad \forall j,k \in J, j \lt k, i \in M \\
                    & C_{\max} \ge x_{\sigma^{i}_m,j} + p_{\sigma^{i}_m,j}
                        && \quad \forall j,k \in J, i \in M  \\
                    & z_{ijk} \in \{0, 1\}
\end{align}
$$

where:

- $(1)$ we state our objective, to minimize the makespan,
- $(2)$ ensure times are non-negative,
- $(3)$ the _precedence constraint_ ensures jobs are executed in the correct order,
- $(4)$ is one of the _disjunctive constraints_ that ensure no two jobs are executed in the same machine
  at the same time,
- $(5)$ is the other _disjunctive constraint_,
- $(6)$ we ensure the makespan variable is set to the end time of the last job.
- $(7)$ constraint the variable $z$ to be binary.


Let's inspect only the _disjunctive_ constraints $(4)$ and $(5)$ as they're the more interesting ones in this formulation. It basically says that jobs $j$ and $k$ must not occur at the same machine $i$ at the same time. As $x$ is our start time, this means $x_{ij}$ must come after $x_{ik}$ with by at least the processing time $p_{ik}$, **or vice-versa but not both**. This means we have to express the logical constraint:

$$
\begin{align}
&\text{either} \quad &x_{ij} - x_{ik} \ge p_{ik} \\
&\text{or else} \quad &x_{ik} - x_{ij} \ge p_{ij}
\end{align}
$$

Expressing this in linear terms require the transformation we see in $(4)$ and $(5)$ that involves the $V$ parameter (usually called **Big-M** and expressed as $M$) and the binary variable $z_{ijk}$. This trick is explained in detail in \cite{manne} original paper.

If you find this complicated, don't worry. Coming up with these formulation is far from trivial and require some experience with the subject matter. And becoming a modeler is not the goal of this article; for now, you can just trust me (or *Manne*) that this formulation is correct. The important thing to notice now is that all equations are fully linear, ie. no exponentiation or cross-variable multiplication is allowed.

Now comes the "easy" part, writing this formulation in Julia leveraging an existing
MILP solver.

## Writing a Julia MILP model with JuMP

While solvers come with their own (APIs) for building the model, practitioners also find it useful to use general purpose modelling languages or libraries that are somewhat agnostic of the underlying solver. As we'll see later posts, being able to easily swap solvers can be beneficial.

Here we'll pick [JuMP][jump], a Julia package that, in my opinion, is one of the best modeling interfaces available. IMO, nothing I've ever used in Python or C++ comes close to the expressiveness of JuMP. It support [many solvers][solvers] and for this exercise, we'll pick the open-source [Coin-OR's branch-and-cut solver (Cbc)][cbc]. Without further ado, let's get to the code.

@@quote
The source code is available at blog repo:
[link]({{fill blog_repo}}/code/jssp/jump.jl)
@@

\literate{/code/jssp/jump.jl}

When running the code below we get the following figure and output:

```julia:./code/jump1
span = run_jump1()
println("Solution makespan: $(span)")
```

\figalt{JuMP 1}{jump1.png}
\output{./code/jump1}

Nice! The MIP solver found the optimal solution we expected.

## A few remarks on modeling with Julia/JuMP.

Those with coding experience might be wondering about the $\sigma$ and $\in$ and $\ge$ symbols in the code. While Python do have support Unicode symbols, its use is definitely frowned upon. Julia, on the other hand, have first class support for mathematical symbols. They can be easily typed in Julia code editors (eg. VS Code) using $LaTeX$ commands. For instance, typing `\sigma<TAB>` will give you $\sigma$. Typing `\in<TAB>` gives you $\in$ and this is also an alias for the `in` infix operator

```julia
julia> 1 ∈ [1,2]
true

julia> 3 ∈ [1,2]
false
```

Arguably, judicial use of such symbols make it easier to write math-inspired code since, lowering the communication barrier between _coders_ and _scientists_. JuMP follows this philosophy by making formulating constraint in standard form straightforward. For instance check the similarities between the standard formulation of the "precedence constraint" (3):

$$
x_{\sigma^{j}_h,j} \ge x_{\sigma^{j}_{h-1},j} + p_{\sigma^{j}_{h-1},j}
\qquad \forall j \in J, h=2..m
$$

And the Julia code:

```julia
@constraint(model,
    [j ∈ J, h = 2:m],
    x[σ[j, h], j] ≥ x[σ[j, h-1], j] + p[σ[j, h-1], j]
)
```

## Next steps

"Hey Cloves, but this example is so simple I could solve it by brute-force". Indeed,
in the next post we'll do some benchmarking and explore a bit the scaling issues with
the job-shop problem.

## References

- \biblabel{beck}{Ku, Beck (2016)} Ku, Wen-Yang, and J. Christopher Beck. "Mixed
  integer programming models for job shop scheduling: A computational analysis."
  Computers & Operations Research 73 (2016): 165-173. [PDF][beck]

- \biblabel{manne}{Manne (1960)} A. S. Manne, On the job-shop scheduling problem,
  Operations Research (1960) 219–223. [PDF][manne]

[solvers]: https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers
[milp]: https://en.wikipedia.org/wiki/Integer_programming
[simplex]: https://en.wikipedia.org/wiki/Simplex_algorithm
[barrier]: https://en.wikipedia.org/wiki/Interior-point_method
[pascal]: https://www.isye.gatech.edu/users/pascal-van-hentenryck
[coursera]: (https://www.coursera.org/learn/discrete-optimization)
[beck]: https://tidel.mie.utoronto.ca/pubs/JSP_CandOR_2016.pdf
[jump]: https://jump.dev/JuMP.jl/stable/
[cbc]: https://github.com/coin-or/Cbc
[convex]: https://vitalflux.com/convex-optimization-explained-concepts-examples/
[manne]: https://cowles.yale.edu/sites/default/files/files/pub/d00/d0073.pdf