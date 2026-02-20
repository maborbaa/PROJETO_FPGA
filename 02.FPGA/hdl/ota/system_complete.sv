module system_complete (
    input  wire clk,        // 25 MHz
    input  wire rst,    // Botão Vermelho da Protoboard (Se quiser usar)
    // Interface SPI RP2040
    input  wire spi_sck, spi_mosi, spi_cs,
    // Saídas
    output reg  led_verde,
    output reg  led_verm
);

    // --- 1. COMUNICAÇÃO SPI (Ouvindo o RP2040) ---
    wire [7:0] rx_byte;
    wire       rx_valid;
    
    // Variável de MODO:
    // 0 = Menu (Pisca Junto)
    // 1 = App LED (Pisca Alternado)
    // 2 = App Botão (Espera Botão Físico)
    reg [1:0] modo_atual = 0; 

    spi_slave u_spi (
        .clk(clk), .sck(spi_sck), .mosi(spi_mosi), .cs(spi_cs),
        .rx_data(rx_byte), .rx_valid(rx_valid)
    );

    // Atualiza o modo baseado no que o RP2040 mandou
    always @(posedge clk) begin
        if (rx_valid) begin
            if (rx_byte == 8'h00) modo_atual <= 0; // Comando 0x00 -> Menu
            if (rx_byte == 8'hA1) modo_atual <= 1; // Comando 0xA1 -> LED Auto
            if (rx_byte == 8'hB2) modo_atual <= 2; // Comando 0xB2 -> LED Botão
        end
    end

    // --- 2. LÓGICAS DOS SISTEMAS (Tudo rodando junto) ---
    
    reg [24:0] cnt;
    always @(posedge clk) cnt <= cnt + 1;

    // Lógica A: MENU (Pisca Rápido e Junto)
    // Bit 22 do contador muda a cada ~0.3s
    wire led_g_menu = cnt[22]; 
    wire led_r_menu = cnt[22];

    // Lógica B: APP 1 (Pisca Lento e Alternado - Automático)
    // Bit 24 muda a cada ~1.3s
    wire led_g_app1 = cnt[24];
    wire led_r_app1 = ~cnt[24];

    // Lógica C: APP 2 (Controlado pelo Botão Vermelho da Protoboard)
    // Se apertar rst_btn, acende. Senão apaga.
    wire led_g_app2 = rst_btn; // Botão pressionado (assumindo Pull-Down ou Up conforme sua placa)
    wire led_r_app2 = !rst_btn;

    // --- 3. O SELETOR (MULTIPLEXADOR) ---
    // Aqui acontece a mágica. Decidimos quem controla o pino físico.
    always @(*) begin
        case (modo_atual)
            0: begin // Menu
                led_verde = led_g_menu;
                led_verm  = led_r_menu;
            end
            1: begin // App 1
                led_verde = led_g_app1;
                led_verm  = led_r_app1;
            end
            2: begin // App 2
                led_verde = led_g_app2;
                led_verm  = led_r_app2;
            end
            default: begin
                led_verde = 0;
                led_verm  = 0;
            end
        endcase
    end

endmodule