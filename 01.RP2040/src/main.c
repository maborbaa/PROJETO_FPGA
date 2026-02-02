#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "FreeRTOS.h"
#include "task.h"

// --- PINAGEM (BitDogLab SPI0) ---
#define SPI_PORT spi0
#define PIN_MISO 16
#define PIN_CS   17
#define PIN_SCK  18
#define PIN_MOSI 19

// LED Verde da BitDogLab para sabermos que o RP2040 não travou
#define LED_PIN_GREEN 11 

// --- Função: Configura o Hardware SPI ---
void hardware_spi_init() {
    // Inicializa SPI a 500kHz (Lento e seguro para fios soltos)
    spi_init(SPI_PORT, 500 * 1000);
    
    gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);

    // Controle manual do Chip Select (CS)
    gpio_init(PIN_CS);
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1); // 1 = Desabilitado (FPGA ignora)
}

// --- Função: Envia 1 byte para a FPGA ---
void send_fpga_command(uint8_t cmd) {
    gpio_put(PIN_CS, 0); // 0 = Baixa o CS (Ei FPGA, escuta aqui!)
    sleep_us(10);        // Dá um tempinho para a FPGA perceber
    
    spi_write_blocking(SPI_PORT, &cmd, 1); // Envia o dado
    
    sleep_us(10);
    gpio_put(PIN_CS, 1); // 1 = Sobe o CS (Acabou, executa aí!)
}

// --- TAREFA 1: O Maestro da FPGA ---
void vFpgaTestTask(void *pvParameters) {
    hardware_spi_init(); // Configura os pinos uma vez
    printf("--- Iniciando Comunicacao SPI com FPGA ---\n");

    for(;;) {
        // Passo 1: Manda LIGAR (A1)
        // A FPGA deve acender o LED Verde
        printf(">> RP2040 diz: LIGAR (0xA1)\n");
        send_fpga_command(0xA1);
        vTaskDelay(pdMS_TO_TICKS(1000)); // Espera 1 segundo

        // Passo 2: Manda DESLIGAR (B0)
        // A FPGA deve apagar o LED Verde
        printf(">> RP2040 diz: DESLIGAR (0xB0)\n");
        send_fpga_command(0xB0);
        vTaskDelay(pdMS_TO_TICKS(1000)); // Espera 1 segundo
    }
}

// --- TAREFA 2: O Coração da RP2040 ---
// Só pisca o LED da placa para mostrar que o FreeRTOS está rodando
void vBlinkLocalTask(void *pvParameters) {
    gpio_init(LED_PIN_GREEN);
    gpio_set_dir(LED_PIN_GREEN, GPIO_OUT);

    for(;;) {
        gpio_put(LED_PIN_GREEN, 1);
        vTaskDelay(pdMS_TO_TICKS(100)); // Pisca rápido
        gpio_put(LED_PIN_GREEN, 0);
        vTaskDelay(pdMS_TO_TICKS(900));
    }
}

// --- MAIN ---
int main() {
    stdio_init_all();
    sleep_ms(2000); // Espera você abrir o monitor serial

    printf("--- SISTEMA INTEGRADO ---\n");

    // Cria as tarefas do FreeRTOS
    xTaskCreate(vBlinkLocalTask, "LocalBlink", 128, NULL, 1, NULL);
    xTaskCreate(vFpgaTestTask,   "FpgaSPI",    256, NULL, 2, NULL);

    // Inicia o sistema operacional
    vTaskStartScheduler();

    // O código nunca deve chegar aqui
    while (1);
}