@def title = "Optimization articles"
@def pages = [string("posts/", p) for p in readdir("posts")]

# Optimization articles

This is a series of posts exploring practical solutions to combinatorial optimization problems. The articles are my take on learning, understanding and exploring this space, in particular using [Julia](https://julialang.org/) a modern programming language designed for high performance scientific computing. Also note that I'm a software engineer. I do have some experience in machine-learning and operations research but not an expert on the topics. So I'll focus more on the practical and engineering aspect of the problems, not so much on the theory.

I write most posts in a [literate programming] style meaning that you'll see **a lot of code**. All actual code should be available in my [personal GitHub repo](https://github.com/cjalmeida/optim).

In my job at BCG GAMMA, the data science arm of [BCG](https://bcg.com), we deal with a lot of practical business problems that can be modeled as [combinatorial optimization](https://en.wikipedia.org/wiki/Combinatorial_optimization) (CO) problems. In a very crude summary, those are the kind of are problems that can be solved by picking a solution from a discrete and finite (even if huge) set of options. 

Expressing and solving such optimization problems with "industrial" application has been the object of study of [Operations Research (OR)](https://en.wikipedia.org/wiki/Operations_research) discipline since the 1950s. And more recently mixed machine learning techniques have been applied. 

Such problems have a number of real world applications. Improving airline schedules, reallocating aircrafts during airport disruptions, improving yields in steelmaking operations, improving delivery routes of fuel trucks and finding optimal prices during markdown season in retail are some applications I've been personally involved.

And I do appreciate people pointing out issues in the articles. Feel free to contact me via

cjalmeida(at)gmail.com

Hope you enjoy it! :)


{{allposts}}

[literate programming]: https://en.wikipedia.org/wiki/Literate_programming