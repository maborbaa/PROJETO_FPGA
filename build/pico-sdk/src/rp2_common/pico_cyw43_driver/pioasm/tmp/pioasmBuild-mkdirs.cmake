# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/home/tech03/pico/pico-sdk/tools/pioasm")
  file(MAKE_DIRECTORY "/home/tech03/pico/pico-sdk/tools/pioasm")
endif()
file(MAKE_DIRECTORY
  "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pioasm"
  "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pioasm-install"
  "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/tmp"
  "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp"
  "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src"
  "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/tech03/Documentos/2025/EMBARCATECH/RESIDENCIA/MATERIAL_AULA/U7-projeto/PROJETO_FPGA/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp${cfgdir}") # cfgdir has leading slash
endif()
