#include <stdio.h>
#include "pico/stdlib.h"
#include "FreeRTOS.h"
#include "task.h"
#include "usb_task.h"

void vUsbTask(void *pvParameters) {
    int ch;

    
    for (;;){
        // Tenta ler um caractrere da USB com timeout de 0 (não bloqueia)
        // Se não tiver nada, ele retorna PICO_ERROR_TIMEOUT
        ch = getchar_timeout_us(0);

        // Se recebeu algo válida (diferente de erro)
        if(ch != PICO_ERROR_TIMEOUT){
            printf("Recebi na USB: %c (ASCII: %d)\n", ch, ch);

            //será adicionado os dados do bitstream no buffer
        }

        //Ele fica verificando constantemente a CPU
        //Parar 10ms para não sobrecarregar a CPU
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

