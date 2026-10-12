cmake_minimum_required(VERSION 3.10.2)
project(paddle_ocr_ncnn LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)

# Check if prebuilt NCNN is present
set(NCNN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ncnn-android-vulkan/${ANDROID_ABI}/lib/cmake/ncnn)

if(EXISTS ${NCNN_DIR})
    set(ncnn_DIR ${NCNN_DIR})
    find_package(ncnn REQUIRED)
    add_library(paddle_ocr_ncnn SHARED ocr_ncnn.cpp)
    target_link_libraries(paddle_ocr_ncnn ncnn jnigraphics log)
else()
    # Build fallback stub if NCNN SDK not yet unpacked
    add_library(paddle_ocr_ncnn SHARED ocr_ncnn.cpp)
    target_link_libraries(paddle_ocr_ncnn log)
endif()
