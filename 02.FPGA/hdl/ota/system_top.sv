module system_top (
    input  wire clk,        // 25 MHz
    input  wire spi_sck, spi_mosi, spi_cs, // SPI vindo do RP2040
    output reg  led_verde,
    output reg  led_verm
);

    // --- 1. Sinal Visual de "Menu/Bootloader" ---
    // Pisca os dois LEDs JUNTOS e RÁPIDO (Visual de "Aguardando Comando")
    reg [23:0] timer;
    
    always @(posedge clk) begin
        timer <= timer + 1;
        // 8 milhões de ciclos ~= 0.3 segundos (Pisca rápido)
        if (timer == 24'd8_000_000) begin
            timer <= 0;
            led_verde <= ~led_verde;
            led_verm  <= ~led_verm; 
        end
    end

    // Inicialização (Começa apagado)
    initial begin
        led_verde = 0;
        led_verm  = 0;
    end

    // --- 2. Receptor SPI (Ouvidos do Menu) ---
    // Instancia o escravo SPI para receber comandos futuros do RP2040
    wire [7:0] cmd_byte;
    wire       cmd_valid;

    spi_slave u_spi (
        .clk(clk), .sck(spi_sck), .mosi(spi_mosi), .cs(spi_cs),
        .rx_data(cmd_byte), .rx_valid(cmd_valid)
    );

    // --- 3. Futuro: Lógica de Reboot ---
    // Por enquanto, ele só fica piscando e ouvindo.
    // O comando de troca virá do RP2040 reiniciando a placa.

endmodule