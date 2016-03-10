cmake_minimum_required(VERSION 3.3)
project(latentmotif_v0_12)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
    SFMT-src-1.3.3/SFMT-alti.h
    SFMT-src-1.3.3/SFMT-params.h
    SFMT-src-1.3.3/SFMT-params11213.h
    SFMT-src-1.3.3/SFMT-params1279.h
    SFMT-src-1.3.3/SFMT-params132049.h
    SFMT-src-1.3.3/SFMT-params19937.h
    SFMT-src-1.3.3/SFMT-params216091.h
    SFMT-src-1.3.3/SFMT-params2281.h
    SFMT-src-1.3.3/SFMT-params4253.h
    SFMT-src-1.3.3/SFMT-params44497.h
    SFMT-src-1.3.3/SFMT-params607.h
    SFMT-src-1.3.3/SFMT-params86243.h
    SFMT-src-1.3.3/SFMT-sse2.h
    SFMT-src-1.3.3/SFMT.c
    SFMT-src-1.3.3/SFMT.h
    SFMT-src-1.3.3/test.c
    svm_light/kernel.h
    svm_light/svm_classify.c
    svm_light/svm_common.c
    svm_light/svm_common.h
    svm_light/svm_hideo.c
    svm_light/svm_learn.c
    svm_light/svm_learn.h
    svm_light/svm_learn_main.c
    svm_struct_latent_api.c
    svm_struct_latent_api.h
    svm_struct_latent_api_types.h
    svm_struct_latent_cccp.c
    svm_struct_latent_classify.c)

add_executable(latentmotif_v0_12 ${SOURCE_FILES})