cmake_minimum_required(VERSION 3.16)

project(%{ProjectName} LANGUAGES CXX)

# Template used by Qt Creator MCU wizard.
# The exact package set depends on the selected SDK/toolchain.
find_package(Qul REQUIRED)

add_executable(${PROJECT_NAME}
    main.cpp
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        Qul::QuickUltralite
)
