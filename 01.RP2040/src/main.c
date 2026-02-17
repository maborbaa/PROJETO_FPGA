#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"

// --- MAPEAMENTO DE PINOS (BitDogLab / Raspberry Pi Pico) ---
#define SPI_PORT    spi0
#define PIN_MISO    16   // (Não usado neste exemplo, mas configurado)
#define PIN_CS      17   // Chip Select
#define PIN_SCK     18   // Clock
#define PIN_MOSI    19   // Dados (Sai do RP2040 -> Vai pra FPGA)

#define BUTTON_A    5    // Botão A da BitDogLab

// Velocidade do SPI: 1 MHz (suficiente para FPGA detectar sem erros)
#define SPI_BAUDRATE 1000 * 1000 

int main() {
    // 1. Inicialização Padrão
    stdio_init_all();
    sleep_ms(2000); // Tempo para abrir o terminal serial se precisar
    printf("Iniciando Sistema de Controle FPGA via SPI...\n");

    // 2. Inicialização do SPI
    spi_init(SPI_PORT, SPI_BAUDRATE);
    
    // Configura os pinos para função SPI (SCK e MOSI)
    // Nota: CS faremos controle manual via GPIO para garantir o timing
    gpio_set_function(PIN_SCK, GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    
    // Configura o pino MISO (opcional, pois não estamos lendo volta da FPGA agora)
    gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);

    // 3. Configuração do Chip Select (CS) Manual
    gpio_init(PIN_CS);
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1); // CS começa em ALTO (Desativado)

    // 4. Configuração do Botão A
    gpio_init(BUTTON_A);
    gpio_set_dir(BUTTON_A, GPIO_IN);
    gpio_pull_up(BUTTON_A); // Botão pressionado vai para 0 (GND)

    // Loop Principal
    while (true) {
        // Verifica se o botão foi pressionado (Nível Baixo)
        if (!gpio_get(BUTTON_A)) {
            printf("Botão A pressionado. Enviando comando 0xA1...\n");

            // --- PROTOCOLO DE ENVIO ---
            
            // 1. Baixa o CS para acordar a FPGA
            gpio_put(PIN_CS, 0);
            sleep_us(10); // Pequeno delay de estabilização

            // 2. Envia o byte de comando (0xA1)
            uint8_t comando = 0xA1;
            spi_write_blocking(SPI_PORT, &comando, 1);

            // 3. Sobe o CS para encerrar a transação
            sleep_us(10);
            gpio_put(PIN_CS, 1);

            printf("Comando enviado!\n");

            // Debounce simples (espera o botão ser solto ou um tempo)
            sleep_ms(250); 
            while(!gpio_get(BUTTON_A)) {
                sleep_ms(10); // Espera soltar o botão
            }
        }

        sleep_ms(10); // Delay do loop
    }

    return 0;
}