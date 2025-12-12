#include <stdio.h>
#include "pico/stdlib.h"
#include "FreeRTOS.h"
#include "task.h"
#include "usb_task.h"

#define LED_PIN_GREEN 11 //Pino do LED RGB Verde no Bitdoglab

void vBlinkTask(void *pvParameters){
    gpio_init(LED_PIN_GREEN);
    gpio_set_dir(LED_PIN_GREEN, GPIO_OUT);

    for(;;){
        gpio_put(LED_PIN_GREEN,1);
        vTaskDelay(pdMS_TO_TICKS(100)); //pisca rapido 100 ms
        gpio_put(LED_PIN_GREEN,0);
        vTaskDelay(pdMS_TO_TICKS(900)); //espera ~1s
    }
}

int main(){
    //1. Iniciar USB e serial
    stdio_init_all(); //inicializa

    //adionar uma pequena pausa e printa
    sleep_ms(2000);
    printf("--- INICIANDO SISTEMA FREERTOS ---\n");
    printf("--- Aguardando dados na USB... ---\n");

    //2. Criar as tarefas
    //LED
    xTaskCreate(vBlinkTask,"Blink", 128, NULL, 1, NULL);    

    //USB
    xTaskCreate(vUsbTask, "USB_talk", 256, NULL, 1, NULL);

    //3. Iniciar o scheduler - FreeRTOS assume o controle com as tarefas
    vTaskStartScheduler();

    //4. Erro de memoria (FreeRTOS) caso a execução chegue aqui
    while (1);    
}


// #include "hardware/spi.h"
// #include "hardware/i2c.h"
// #include "hardware/dma.h"

// // SPI Defines
// // We are going to use SPI 0, and allocate it to the following GPIO pins
// // Pins can be changed, see the GPIO function select table in the datasheet for information on GPIO assignments
// #define SPI_PORT spi0
// #define PIN_MISO 16
// #define PIN_CS   17
// #define PIN_SCK  18
// #define PIN_MOSI 19

// // I2C defines
// // This example will use I2C0 on GPIO8 (SDA) and GPIO9 (SCL) running at 400KHz.
// // Pins can be changed, see the GPIO function select table in the datasheet for information on GPIO assignments
// #define I2C_PORT i2c0
// #define I2C_SDA 8
// #define I2C_SCL 9

// // Data will be copied from src to dst
// const char src[] = "Hello, world! (from DMA)";
// char dst[count_of(src)];



// int main()
// {
//     stdio_init_all();

//     // SPI initialisation. This example will use SPI at 1MHz.
//     spi_init(SPI_PORT, 1000*1000);
//     gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
//     gpio_set_function(PIN_CS,   GPIO_FUNC_SIO);
//     gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
//     gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    
//     // Chip select is active-low, so we'll initialise it to a driven-high state
//     gpio_set_dir(PIN_CS, GPIO_OUT);
//     gpio_put(PIN_CS, 1);
//     // For more examples of SPI use see https://github.com/raspberrypi/pico-examples/tree/master/spi

//     // I2C Initialisation. Using it at 400Khz.
//     i2c_init(I2C_PORT, 400*1000);
    
//     gpio_set_function(I2C_SDA, GPIO_FUNC_I2C);
//     gpio_set_function(I2C_SCL, GPIO_FUNC_I2C);
//     gpio_pull_up(I2C_SDA);
//     gpio_pull_up(I2C_SCL);
//     // For more examples of I2C use see https://github.com/raspberrypi/pico-examples/tree/master/i2c

//     // Get a free channel, panic() if there are none
//     int chan = dma_claim_unused_channel(true);
    
//     // 8 bit transfers. Both read and write address increment after each
//     // transfer (each pointing to a location in src or dst respectively).
//     // No DREQ is selected, so the DMA transfers as fast as it can.
    
//     dma_channel_config c = dma_channel_get_default_config(chan);
//     channel_config_set_transfer_data_size(&c, DMA_SIZE_8);
//     channel_config_set_read_increment(&c, true);
//     channel_config_set_write_increment(&c, true);
    
//     dma_channel_configure(
//         chan,          // Channel to be configured
//         &c,            // The configuration we just created
//         dst,           // The initial write address
//         src,           // The initial read address
//         count_of(src), // Number of transfers; in this case each is 1 byte.
//         true           // Start immediately.
//     );
    
//     // We could choose to go and do something else whilst the DMA is doing its
//     // thing. In this case the processor has nothing else to do, so we just
//     // wait for the DMA to finish.
//     dma_channel_wait_for_finish_blocking(chan);
    
//     // The DMA has now copied our text from the transmit buffer (src) to the
//     // receive buffer (dst), so we can print it out from there.
//     puts(dst);

//     while (true) {
//         printf("Hello, world!\n");
//         sleep_ms(1000);
//     }
// }
