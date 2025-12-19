/* Arquivo: firmware.c */
/* Objetivo: Lógica principal de controle do SoC (System on Chip) */

#include <stdint.h>

/* --- MAPEAMENTO DE HARDWARE (MMIO) --- */
/* Estes endereços DEVEM bater exatamente com o top.sv */

/* Endereço do Registrador de LEDs (Apenas Escrita) */
#define REG_LEDS  (*((volatile uint32_t *)0x00020000))

/* Endereço do Registrador SPI (Apenas Leitura no nosso IP) */
#define REG_SPI   (*((volatile uint32_t *)0x00010000))

/* --- FUNÇÕES AUXILIARES --- */

/* Função de delay simples (Gastando ciclos de CPU) */
/* Como não temos Timer Hardware ainda, usamos loop forçado */
void delay(uint32_t count) {
    while (count > 0) {
        /* 'volatile' aqui impede o compilador de remover este loop vazio */
        volatile uint32_t dummy = 0;
        count--;
    }
}

/* --- FUNÇÃO PRINCIPAL --- */
/* O bootloader.s pula para cá */
void main() {
    uint32_t contador = 0;
    uint32_t dados_spi = 0;

    /* Loop Infinito (Super Loop) */
    while (1) {
        /* 1. Ler dados vindos do RP2040 via SPI */
        /* O IP Core SPI Slave atualiza esse endereço quando recebe algo */
        dados_spi = REG_SPI;

        /* 2. Lógica de Visualização */
        /* Se recebermos zero do SPI, mostramos um contador automático (modo demo) */
        /* Se recebermos algo do SPI, mostramos o dado recebido nos LEDs */
        
        if (dados_spi == 0) {
            REG_LEDS = contador; /* Escreve contador nos LEDs */
            contador++;          /* Incrementa contador interno */
        } else {
            REG_LEDS = dados_spi; /* Mostra o byte recebido do RP2040 */
        }

        /* 3. Atraso para o olho humano perceber a mudança */
        /* Clock 25MHz -> delay 500000 gera aprox 100-200ms */
        delay(500000);
    }
}