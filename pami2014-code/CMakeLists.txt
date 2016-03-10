cmake_minimum_required(VERSION 3.3)
project(pami2014_code)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
        maxflow-v3.03.src/block.h
        maxflow-v3.03.src/graph.cpp
        maxflow-v3.03.src/graph.h
        maxflow-v3.03.src/maxflow.cpp
        linEnvInf.cpp)
include_directories(
        "/home/spacegoing/MATLAB/R2015b/extern/include/"
)
add_executable(pami2014_code ${SOURCE_FILES})