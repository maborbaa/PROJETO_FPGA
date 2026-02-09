#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "FreeRTOS.h"
#include "task.h"
#include "hardware/i2c.h"

// --- CONFIGURAÇÃO DE PINAGEM (BitDogLab) ---
#define SPI_PORT spi0
#define PIN_MISO 16
#define PIN_CS   17
#define PIN_SCK  18
#define PIN_MOSI 19
#define LED_PIN_RP2040 11 

// Função de leitura simulada (Padrão 25°C - 35°C)
uint8_t read_aht10_temp() {
    static uint8_t t = 25;
    t++; 
    if(t > 35) t = 25;
    return t;
}

void hardware_spi_init() {
    spi_init(SPI_PORT, 10 * 1000); // 10kHz para máxima estabilidade inicial
    gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_CS);
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1);
}

// --- TAREFA: AUDITORIA COM VERIFICAÇÃO DE RETORNO ---
void vSensorFpgaTask(void *pvParameters) {
    hardware_spi_init();
    uint8_t dado_recebido = 0;

    printf("\n--- TESTE 1: AUDITORIA DE INTEGRIDADE + LOOPBACK ---\n");
    
    for(;;) {
        uint8_t temp_enviada = read_aht10_temp();
        
        // Início da Transação
        gpio_put(PIN_CS, 0); 
        vTaskDelay(pdMS_TO_TICKS(50)); // Setup time para estabilidade
        
        // Envia a temperatura e lê o retorno (Loopback físico na FPGA)
        spi_write_read_blocking(SPI_PORT, &temp_enviada, &dado_recebido, 1);
        
        vTaskDelay(pdMS_TO_TICKS(50)); 
        gpio_put(PIN_CS, 1); // Fim da transação (Gatilho da Auditoria na FPGA)

        // --- RELATÓRIO DE DIAGNÓSTICO NO TERMINAL ---
        printf("[RP2040] Enviado: %d C | Recebido: %d ", temp_enviada, dado_recebido);

        if (temp_enviada == dado_recebido) {
            printf("[LINK OK]\n");
        } else {
            // Se os dados forem diferentes, há ruído alterando os bits no percurso
            printf("[ERRO DE BIT]\n");
        }
        
        printf("-> Observe na FPGA: LED Verde (Integridade) e Vermelho (Limite >30)\n\n");
        
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

// --- TAREFA: STATUS LOCAL (BLINK) ---
void vBlinkLocalTask(void *pvParameters) {
    gpio_init(LED_PIN_RP2040);
    gpio_set_dir(LED_PIN_RP2040, GPIO_OUT);
    for(;;) {
        gpio_put(LED_PIN_RP2040, 1);
        vTaskDelay(pdMS_TO_TICKS(100));
        gpio_put(LED_PIN_RP2040, 0);
        vTaskDelay(pdMS_TO_TICKS(900));
    }
}

int main() {
    stdio_init_all();
    sleep_ms(3000); 

    printf("=========================================\n");
    printf("   ESTRATEGIA 1: AUDITORIA DE BARRAMENTO \n");
    printf("=========================================\n");

    xTaskCreate(vBlinkLocalTask, "LocalBlink", 128, NULL, 1, NULL);
    xTaskCreate(vSensorFpgaTask, "SensorFPGA", 256, NULL, 2, NULL);

    vTaskStartScheduler();
    while (1);
}