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

// --- CONFIGURAÇÃO I2C ---
#define I2C_PORT i2c0
#define AHT10_ADDR 0x38
#define PIN_SDA 8
#define PIN_SCL 9

// --- COMANDOS AHT10 ---
uint8_t init_cmd[] = {0xE1, 0x08, 0x00};
uint8_t measure_cmd[] = {0xAC, 0x33, 0x00};

// Função para inicializar o sensor real
void aht10_init() {
    i2c_init(I2C_PORT, 100 * 1000); // 100kHz standard mode
    gpio_set_function(PIN_SDA, GPIO_FUNC_I2C);
    gpio_set_function(PIN_SCL, GPIO_FUNC_I2C);
    gpio_pull_up(PIN_SDA);
    gpio_pull_up(PIN_SCL);
    
    sleep_ms(40); // Aguarda o sensor estabilizar
    i2c_write_blocking(I2C_PORT, AHT10_ADDR, init_cmd, 3, false);
}

// // Função de leitura real para substituir a simulada
// uint8_t read_real_temp() {
//     uint8_t data[6];
//     // Solicita medição
//     i2c_write_blocking(I2C_PORT, AHT10_ADDR, measure_cmd, 3, false);
   
//     // IMPORTANTE: O AHT10 precisa de tempo para converter o sinal analógico em digital
//     vTaskDelay(pdMS_TO_TICKS(80));
    
//     // Lê 6 bytes de resposta
//     i2c_read_blocking(I2C_PORT, AHT10_ADDR, data, 6, false);
    
//     // Fórmula de conversão para temperatura (AHT10 Datasheet)
//     // Temperatura (°C) = ((Data[3] & 0x0F) << 16 | Data[4] << 8 | Data[5]) * 200 / 1048576 - 50
//     uint32_t temp_raw = ((uint32_t)(data[3] & 0x0F) << 16) | ((uint32_t)data[4] << 8) | data[5];
//     float temp_c = ((float)temp_raw * 200 / 1048576) - 50;
    
//     return (uint8_t)temp_c;
// }

uint8_t read_real_temp() {
    uint8_t data[6];
    int ret;

    // 1. Envia comando de medição e verifica se o sensor respondeu (ACK)
    //ret = i2c_write_blocking(I2C_PORT, AHT10_ADDR, measure_cmd, 3, false);
    
    // O timeout de 50000us (50ms) garante que se o sensor travar, a tarefa continua
    ret = i2c_write_timeout_us(I2C_PORT, AHT10_ADDR, measure_cmd, 3, false, 50000);

    if (ret < 0) {
        printf("[I2C] Erro de Escrita: Sensor ausente ou barramento travado!\n");
        return 0; 
    }

    if (ret == PICO_ERROR_GENERIC) {
        printf("[I2C ERR] Sensor nao respondeu ao comando de medicao!\n");
        return 0;
    }

    vTaskDelay(pdMS_TO_TICKS(80)); // Essencial aguardar a conversão
    
    // 2. Tenta ler os dados
    //ret = i2c_read_blocking(I2C_PORT, AHT10_ADDR, data, 6, false);
     ret = i2c_read_timeout_us(I2C_PORT, AHT10_ADDR, data, 6, false, 50000);

    if (ret == PICO_ERROR_GENERIC) {
        printf("[I2C ERR] Falha ao ler dados do sensor!\n");
        return 0;
    }

    if (ret < 0) {
        printf("[I2C] Erro de Leitura: Falha na resposta!\n");
        return 0;
    }

    // 3. Verifica o byte de status (Bit 7: 0 = Livre, 1 = Ocupado)
    if (data[0] & 0x80) {
        printf("[AHT10] Sensor ocupado...\n");
    }

    // Conversão (Mantenha o resto igual)
    uint32_t temp_raw = ((uint32_t)(data[3] & 0x0F) << 16) | ((uint32_t)data[4] << 8) | data[5];
    float temp_c = ((float)temp_raw * 200 / 1048576) - 50;
    
    return (uint8_t)temp_c;
}

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

// --- TAREFA ATUALIZADA COM LEITURA REAL ---
// void vSensorFpgaTask(void *pvParameters) {
//     hardware_spi_init();
//     aht10_init(); // AJUSTE 1: Inicializa o I2C e o Sensor AHT10
    
//     uint8_t dado_recebido = 0;

//     printf("\n--- EXECUÇÃO FINAL: LEITURA REAL AHT10 -> FPGA ---\n");
    
//     for(;;) {
//         // AJUSTE 2: Agora usamos a função que lê o sensor físico via I2C
//         uint8_t temp_enviada = read_real_temp(); 
        
//         gpio_put(PIN_CS, 0); 
//         vTaskDelay(pdMS_TO_TICKS(50)); 
        
//         // Envia valor real e recebe confirmação via Loopback da FPGA
//         spi_write_read_blocking(SPI_PORT, &temp_enviada, &dado_recebido, 1);
        
//         vTaskDelay(pdMS_TO_TICKS(50)); 
//         gpio_put(PIN_CS, 1); 

//         // --- MONITORAMENTO ---
//         printf("[RP2040] Sensor Real: %d C | Retorno FPGA: %d ", temp_enviada, dado_recebido);

//         if (temp_enviada == dado_recebido) {
//             printf("[LINK OK]\n");
//         } else {
//             printf("[ERRO DE COMUNICAÇÃO]\n");
//         }
        
//         // Verificação do Alerta Térmico configurado no Teste 3 da FPGA
//         if (temp_enviada > 30) {
//             printf(">> ALERTA: Temperatura acima do limite (LED Vermelho na FPGA)\n");
//         }
        
//         printf("--------------------------------------------------\n");
//         vTaskDelay(pdMS_TO_TICKS(2000));
//     }
// }

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