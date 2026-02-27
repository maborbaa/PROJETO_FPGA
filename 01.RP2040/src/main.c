/*
* Apertar o botão A e muda o Menu OTA da FPGA com SPI
*/

#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"

#define SPI_PORT    spi0
#define PIN_SCK     18
#define PIN_MOSI    19
#define PIN_CS      17
#define BUTTON_A    5  // Controla os LEDs
#define BUTTON_B    6  // Controla o Servo

void send_spi_cmd(uint8_t cmd) {
    gpio_put(PIN_CS, 0);
    sleep_us(10);
    spi_write_blocking(SPI_PORT, &cmd, 1);
    sleep_us(10);
    gpio_put(PIN_CS, 1);
    printf("Comando SPI enviado: 0x%02X\n", cmd);
}

int main() {
    stdio_init_all();
    
    // SPI Init
    spi_init(SPI_PORT, 1000 * 1000);
    gpio_set_function(PIN_SCK, GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_CS); 
    gpio_set_dir(PIN_CS, GPIO_OUT); 
    gpio_put(PIN_CS, 1);

    // Button Init
    gpio_init(BUTTON_A); gpio_set_dir(BUTTON_A, GPIO_IN); gpio_pull_up(BUTTON_A);
    gpio_init(BUTTON_B); gpio_set_dir(BUTTON_B, GPIO_IN); gpio_pull_up(BUTTON_B);

    int modo = 0; // 0=Menu, 1=LED, 2=Botão
    int modo_servo = 0; // 0=Parado (Centro), 1=Varredura (Movendo)

    while (true) {
        //controle botao A
        if (!gpio_get(BUTTON_A)) {
            // Ciclo: 0 -> 1 -> 2 -> 0 ...
            modo++;
            if (modo > 2) modo = 0;

            if (modo == 0) send_spi_cmd(0x00); // Volta pro Menu
            if (modo == 1) send_spi_cmd(0xA1); // Ativa LED Auto
            if (modo == 2) send_spi_cmd(0xB2); // Ativa LED Botão

            sleep_ms(300); // Debounce
        }
         // --- CONTROLE DO SERVO (BOTÃO B) ---
        if (!gpio_get(BUTTON_B)) {
            modo_servo++;
            if (modo_servo > 1) modo_servo = 0;

            if (modo_servo == 0) send_spi_cmd(0xC3); // Comando Servo Parado
            if (modo_servo == 1) send_spi_cmd(0xD4); // Comando Servo Movendo

            sleep_ms(300); // Debounce
        }

        sleep_ms(10);
    }   
        
    return 0;
}