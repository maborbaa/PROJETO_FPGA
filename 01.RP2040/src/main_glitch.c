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

uint8_t read_aht10_temp() {
    static uint8_t t = 25;
    t++; 
    if(t > 35) t = 25;
    return t;
}

void hardware_spi_init() {
    spi_init(SPI_PORT, 10 * 1000); // 10kHz
    gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_CS);
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1);
}

// --- TAREFA: VALIDAÇÃO DE FILTRO VIA LOOPBACK ---
void vSensorFpgaTask(void *pvParameters) {
    hardware_spi_init();
    uint8_t dado_recebido = 0;

    printf("\n--- TESTE 2: ESTABILIZAÇÃO VIA FILTRO DE GLITCH ---\n");
    
    for(;;) {
        uint8_t temp_enviada = read_aht10_temp();
        
        gpio_put(PIN_CS, 0); 
        vTaskDelay(pdMS_TO_TICKS(50)); // Tempo para estabilização do filtro na FPGA
        
        // spi_write_read_blocking envia e recebe ao mesmo tempo (Full-Duplex)
        spi_write_read_blocking(SPI_PORT, &temp_enviada, &dado_recebido, 1);
        
        vTaskDelay(pdMS_TO_TICKS(50)); 
        gpio_put(PIN_CS, 1); 

        // --- PRINT DE TESTE ESPECÍFICO ---
        printf("[RP2040] TX: %d C | RX (Loopback): %d ", temp_enviada, dado_recebido);

        if (temp_enviada == dado_recebido) {
            printf("[OK - Sinal Limpo]\n");
        } else {
            // Se falhar aqui, o filtro na FPGA ainda não está vencendo o ruído físico
            printf("[ERRO - Ruído Detectado]\n");
        }
        
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

// --- TAREFA: BLINK LOCAL ---
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
    printf("   ESTRATEGIA 2: FILTRO DE GLITCH (VOTACAO) \n");
    printf("=========================================\n");

    xTaskCreate(vBlinkLocalTask, "LocalBlink", 128, NULL, 1, NULL);
    xTaskCreate(vSensorFpgaTask, "SensorFPGA", 256, NULL, 2, NULL);

    vTaskStartScheduler();
    while (1);
}