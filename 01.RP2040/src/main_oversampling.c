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

// Função de leitura mantendo o padrão (25°C - 35°C)
uint8_t read_aht10_temp() {
    static uint8_t t = 25;
    t++; 
    if(t > 35) t = 25;
    return t;
}

void hardware_spi_init() {
    // Mantemos 10kHz para garantir que o "meio do bit" seja bem largo para a FPGA amostrar
    spi_init(SPI_PORT, 10 * 1000); 
    gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_CS);
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1);
}

// --- TAREFA: VALIDAÇÃO DE PRECISÃO DE DADOS (OVERSAMPLING) ---
void vSensorFpgaTask(void *pvParameters) {
    hardware_spi_init();
    uint8_t dado_recebido = 0;

    printf("\n--- TESTE 3: PRECISÃO VIA AMOSTRAGEM NO CENTRO DO BIT ---\n");
    printf("Objetivo: Garantir que o LED Vermelho siga a regra > 30 com perfeição.\n");
    
    for(;;) {
        uint8_t temp_enviada = read_aht10_temp();
        
        gpio_put(PIN_CS, 0); 
        // Delay proposital para garantir estabilidade elétrica antes do primeiro bit
        vTaskDelay(pdMS_TO_TICKS(50)); 
        
        // Transmissão Full-Duplex
        spi_write_read_blocking(SPI_PORT, &temp_enviada, &dado_recebido, 1);
        
        vTaskDelay(pdMS_TO_TICKS(50)); 
        gpio_put(PIN_CS, 1); 

        // --- RELATÓRIO TÉCNICO NO TERMINAL ---
        printf("[RP2040] Temp Enviada: %d C | Retorno FPGA: %d ", temp_enviada, dado_recebido);

        if (temp_enviada == dado_recebido) {
            printf("[DADO ÍNTEGRO]\n");
        } else {
            // Se falhar aqui no Teste 3, indica que o deslocamento (skew) entre Clock e Dado 
            // ainda é maior que a janela de compensação do oversampling.
            printf("[ERRO DE SINCRONISMO]\n");
        }
        
        // Dica visual para o usuário
        if (temp_enviada > 30) {
            printf(">> Esperado na FPGA: LED Vermelho ACESO (Alerta)\n");
        } else {
            printf(">> Esperado na FPGA: LED Vermelho APAGADO\n");
        }
        printf("--------------------------------------------------\n");
        
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

// --- TAREFA: STATUS (BLINK) ---
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
    printf("   ESTRATEGIA 3: OVERSAMPLING & SKEW     \n");
    printf("=========================================\n");

    xTaskCreate(vBlinkLocalTask, "LocalBlink", 128, NULL, 1, NULL);
    xTaskCreate(vSensorFpgaTask, "SensorFPGA", 256, NULL, 2, NULL);

    vTaskStartScheduler();
    while (1);
}