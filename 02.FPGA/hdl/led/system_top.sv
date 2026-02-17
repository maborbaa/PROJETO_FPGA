module system_top (
    input  wire clk,        // 25 MHz
    // Pinos Físicos SPI (Ligar no RP2040)
    input  wire spi_sck,
    input  wire spi_mosi,
    input  wire spi_cs,
    // Pinos Físicos de Saída
    output wire servo_pin,
    output wire led_verde,
    output wire led_verm
);

    // Fios internos para comunicação
    wire [7:0] byte_recebido;
    wire       byte_valido;
    reg        trigger_sinal; // Esse será o nosso "rst" virtual

    // ------------------------------------------------
    // 1. Instância do Receptor SPI
    // ------------------------------------------------
    spi_slave u_spi (
        .clk(clk),
        .sck(spi_sck),
        .mosi(spi_mosi),
        .cs(spi_cs),
        .rx_data(byte_recebido),
        .rx_valid(byte_valido)
    );

    // ------------------------------------------------
    // 2. Lógica de Decodificação (A "Ponte")
    // ------------------------------------------------
    // Vamos combinar que o comando para ativar é a letra 'A' (código 0xA1)
    // Se receber 0xA1, segura o trigger por um instante.
    
    always @(posedge clk) begin
        if (byte_valido && byte_recebido == 8'hA1)
            trigger_sinal <= 1; // APERTA O BOTÃO VIRTUAL
        else
            trigger_sinal <= 0; // SOLTA O BOTÃO VIRTUAL
    end

    // ------------------------------------------------
    // 3. Instância do Seu Código de LED (O Operário)
    // ------------------------------------------------
    // Note que ligamos 'rst' no 'trigger_sinal'
    top_led u_leds (
        .clk(clk),
        .rst(trigger_sinal), // <--- O PULO DO GATO AQUI
        .servo_pin(servo_pin),
        .led_verde(led_verde),
        .led_verm(led_verm)
    );

endmodule