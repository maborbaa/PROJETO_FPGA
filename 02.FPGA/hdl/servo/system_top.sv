module system_top (
    input  wire clk,        // 25 MHz
    // Interface SPI (Vem do RP2040)
    input  wire spi_sck,
    input  wire spi_mosi,
    input  wire spi_cs,
    // Saídas Físicas
    output wire servo_pin,  // L4 
    output wire led_verde,  // N4
    output wire led_verm    // P16
);

    // Fios internos
    wire [7:0] byte_recebido;
    wire       byte_valido;
    reg        trigger_sinal; 

    // 1. OUVINDO O RP2040 (SPI Slave)
    spi_slave u_spi (
        .clk(clk),
        .sck(spi_sck),
        .mosi(spi_mosi),
        .cs(spi_cs),
        .rx_data(byte_recebido),
        .rx_valid(byte_valido)
    );

    // 2. TRADUÇÃO (Se receber 0xA1, aperta o botão virtual)
    always @(posedge clk) begin
        // O pulso dura apenas 1 clock, suficiente para disparar a FSM
        if (byte_valido && byte_recebido == 8'hA1)
            trigger_sinal <= 1; 
        else
            trigger_sinal <= 0; 
    end

    // 3. O CONTROLADOR DE SERVO (Instanciado aqui!)
    top_servo_pwm u_servo (
        .clk(clk),
        .rst(trigger_sinal),   // O comando SPI aperta o reset!
        .servo_pin(servo_pin),
        .led_verde(led_verde),
        .led_verm(led_verm)
    );

endmodule