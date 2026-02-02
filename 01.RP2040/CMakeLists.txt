cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(projeto_integrado C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

# --- CONFIGURAÇÃO FREERTOS ---
# Caminhos Absolutos para não ter erro
set(FREERTOS_KERNEL_PATH "${CMAKE_CURRENT_LIST_DIR}/FreeRTOS-Kernel")
set(FREERTOS_CONFIG_PATH "${CMAKE_CURRENT_LIST_DIR}/freertos_config")

include(${FREERTOS_KERNEL_PATH}/portable/ThirdParty/GCC/RP2040/FreeRTOS_Kernel_import.cmake)

# --- EXECUTÁVEL ---
# Aqui estava o erro! Vamos usar o caminho absoluto do arquivo .c
add_executable(firmware_main
    "${CMAKE_CURRENT_LIST_DIR}/src/main.c"
    #"${CMAKE_CURRENT_LIST_DIR}/src/usb_task.c"
)

# Onde procurar arquivos .h
target_include_directories(firmware_main PRIVATE
    "${FREERTOS_CONFIG_PATH}"
    "${CMAKE_CURRENT_LIST_DIR}/src"
    "${CMAKE_CURRENT_LIST_DIR}/inc"
)

# --- BIBLIOTECAS ---
target_link_libraries(firmware_main 
    pico_stdlib
    hardware_spi
    hardware_i2c
    hardware_dma
    hardware_flash
    FreeRTOS-Kernel
    FreeRTOS-Kernel-Heap4
)

pico_enable_stdio_usb(firmware_main 1)
pico_enable_stdio_uart(firmware_main 0)

pico_add_extra_outputs(firmware_main)