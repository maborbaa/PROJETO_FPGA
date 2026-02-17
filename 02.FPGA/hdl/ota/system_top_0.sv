module system_top (
    input  wire clk,        // 25 MHz
    input  wire spi_sck, spi_mosi, spi_cs, // SPI RP2040
    output reg  led_verde,  // Indicador visual
    output reg  led_verm    
);

    // --- 1. Receptor SPI (Ouvindo o RP2040) ---
    wire [7:0] cmd_byte;
    wire       cmd_valid;

    spi_slave u_spi (
        .clk(clk), .sck(spi_sck), .mosi(spi_mosi), .cs(spi_cs),
        .rx_data(cmd_byte), .rx_valid(cmd_valid)
    );

    // --- 2. Lógica de Boot (Rebooter) ---
    reg trigger_boot;
    reg [31:0] boot_address;

    // COMANDOS DO MENU:
    // A (0xA1) -> Carrega App 1 (ota_led) em 0x100000
    // B (0xB2) -> Carrega App 2 (ota_btled) em 0x200000
    
    always @(posedge clk) begin
        trigger_boot <= 0; // Padrão: não fazer nada
        
        // Pisca rápido para mostrar que é o MENU rodando
        // (Lógica simples de piscar omitida para focar no boot)
        led_verde <= 1; 
        led_verm  <= 0;

        if (cmd_valid) begin
            if (cmd_byte == 8'hA1) begin
                boot_address <= 32'h00100000; // Endereço App 1
                trigger_boot <= 1;
            end else if (cmd_byte == 8'hB2) begin
                boot_address <= 32'h00200000; // Endereço App 2
                trigger_boot <= 1;
            end
        end
    end

    // --- 3. O Módulo Mágico de Reboot (ECP5) ---
    ecp5_multiboot u_boot (
        .clk(clk),
        .trigger(trigger_boot),
        .address(boot_address)
    );

endmodule