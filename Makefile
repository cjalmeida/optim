SHELL=/bin/bash

setup-julia:
	curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.2-linux-x86_64.tar.gz -o julia.tgz
	tar zxf julia.tgz

html: setup-julia
	export PATH="$$PWD/julia-1.7.1/bin:$$PATH" && \
	cd blog && \
	julia build.jl

	mv blog/__site out