<div id="-english-project"></div>

#### 🏆 Project Spotlight: FPGA-based OTA System (EmbarcaTech)

As the capstone project for my **Embedded Systems Residency at EmbarcaTech**, I am architecting and implementing a hybrid hardware solution that allows remote updates (Over-the-Air) for FPGA logic.

* **The Architecture:** A Hybrid System involving an **RP2040 MCU** (Management & Network) and a **Lattice ECP5 FPGA** (Processing).
* **The Core:** I integrated a **PicoRV32 Soft-core (RISC-V)** inside the FPGA to handle internal logic.
* **My Contribution:**
    * Designed a custom **SPI Slave IP Core** in SystemVerilog to handle Clock Domain Crossing (CDC) between the MCU and FPGA.
    * Implemented the full **Open Source Flow** (Yosys, Nextpnr) to synthesize the design.
    * Developing the C firmware to boot the RISC-V core and control peripherals.

> *Status: Prototype functional (Phase 2 completed). Currently working on the Flash writing logic.*

---

<div id="-portugues-projeto"></div>

#### 🏆 Destaque: Sistema OTA baseado em FPGA (EmbarcaTech)

Como projeto final da minha **Residência em Sistemas Embarcados no EmbarcaTech**, estou arquitetando e implementando uma solução híbrida que permite atualizações remotas (Over-the-Air) para lógica programável.

* **A Arquitetura:** Um sistema híbrido envolvendo um **MCU RP2040** (Gestão e Rede) e uma **FPGA Lattice ECP5** (Processamento).
* **O Núcleo:** Integrei um processador **Soft-core PicoRV32 (RISC-V)** dentro da FPGA para gerenciar a lógica interna.
* **Minha Contribuição:**
    * Desenvolvi um **IP Core SPI Slave** customizado em SystemVerilog, tratando o Cruzamento de Domínios de Clock (CDC) entre o MCU e a FPGA.
    * Implementei todo o fluxo utilizando **Ferramentas Open Source** (Yosys, Nextpnr).
    * Desenvolvimento do firmware em C para inicializar o núcleo RISC-V e controlar periféricos.

> *Status: Protótipo funcional (Fase 2 concluída). Atualmente trabalhando na lógica de gravação da Flash.*
