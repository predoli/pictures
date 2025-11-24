cmake_minimum_required(VERSION 3.16)

project(digital-photo-frame-qt VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.2 REQUIRED COMPONENTS Quick Network)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

qt_add_executable(appdigital-photo-frame-qt
    src/main.cpp
    src/BackendClient.cpp
    src/BackendClient.h
    src/ImageModel.cpp
    src/ImageModel.h
    resources/qml.qrc
)

target_link_libraries(appdigital-photo-frame-qt
    PRIVATE Qt6::Quick Qt6::Network
)

# Install rules
install(TARGETS appdigital-photo-frame-qt
    BUNDLE DESTINATION .
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
