#!/bin/bash

cd blog
julia build.jl
cd ..
cp -ar blog/__site out