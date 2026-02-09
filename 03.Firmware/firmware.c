/* Arquivo: firmware.c */
/* Objetivo: Lógica principal de controle do SoC (System on Chip) */

#include <stdint.h>

/* --- MAPEAMENTO DE HARDWARE (MMIO) --- */
/* Estes endereços DEVEM bater exatamente com o top.sv */

/* Endereço do Registrador SPI (Apenas Leitura no nosso IP) */
#define REG_SPI   (*((volatile uint32_t *)0x00010000))

/* Endereço do Registrador de LEDs (Apenas Escrita) */
#define REG_LEDS  (*((volatile uint32_t *)0x00020000))

/* Endereço de Registrador Teclado Matricial */
#define REG_KEYBOARD (*((volatile uint32_t *)0x00030000))

/* --- FUNÇÕES AUXILIARES --- */

/* Função de delay simples (Gastando ciclos de CPU) */
/* Não temos Timer Hardware, loop forçado */
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
   // uint32_t contador = 0;
   // uint32_t dados_spi = 0;
   // uint32_t dados_teclado = 0;

    /* Loop Infinito (Super Loop) */
   // while (1) {
        /* 1. Ler dados vindos do RP2040 via SPI */
        /* O IP Core SPI Slave atualiza esse endereço quando recebe algo */
   //     dados_spi = REG_SPI;
        // 2. Lemos o teclado e o SPI
  //      dados_teclado = REG_KEYBOARD;

        /* 2. Lógica de Visualização */
        /* Se recebermos zero do SPI, mostramos um contador automático (modo demo) */
        /* Se recebermos algo do SPI, mostramos o dado recebido nos LEDs */
        
        //if (dados_spi == 0) {
        //    REG_LEDS = contador; /* Escreve contador nos LEDs */
        //    contador++;          /* Incrementa contador interno */
        //} else {
        //    REG_LEDS = dados_spi; /* Mostra o byte recebido do RP2040 */
        //}

        // 2. Prioridade de Visualização no LED Verde:
        // Se houver tecla pressionada, mostra o código da tecla.
        // Se não, mostra o que veio do RP2040 via SPI.
   //     if (dados_teclado != 0) {
   //         REG_LEDS = dados_teclado; 
   //     } else {
   //         REG_LEDS = dados_spi;
   //     }

        /* 3. Atraso para o olho humano perceber a mudança */
        /* Clock 25MHz -> delay 500000 gera aprox 100-200ms */
        //delay(500000);
      //  delay(100000); // Delay menor para resposta mais rápida do teclado

      // Sinalização de boot: Acende o LED Verde (bit 0) com 0xAA (binario 10101010)
    // Como é Active Low, o LED verde ligado ao bit 0 acenderá.
    REG_LEDS = 0xAA; 
    
    while (1) {
        uint32_t dados_teclado = REG_KEYBOARD;
        uint32_t dados_spi = REG_SPI;

        if (dados_teclado != 0) {
            REG_LEDS = dados_teclado; // Teclado assume o controle
        } else {
            REG_LEDS = dados_spi;     // Mostra dados do RP2040
        }
        delay(100000); 
    }
}
//}