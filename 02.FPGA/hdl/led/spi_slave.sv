module spi_slave (
    input  wire clk,        // Clock do Sistema (25MHz)
    input  wire sck,        // SPI Clock (Vem do RP2040)
    input  wire mosi,       // SPI Data In (Vem do RP2040)
    input  wire cs,         // Chip Select (Vem do RP2040)
    output reg  [7:0] rx_data,  // O byte recebido
    output reg  rx_valid        // Pulso de 1 clock avisando "Chegou!"
);

    // Sincronização de sinais (evita falhas por domínios de clock diferentes)
    reg [2:0] sck_r, cs_r, mosi_r;
    always @(posedge clk) begin
        sck_r  <= {sck_r[1:0], sck};
        cs_r   <= {cs_r[1:0], cs};
        mosi_r <= {mosi_r[1:0], mosi};
    end

    // Detecção de borda do SCK (Subida)
    wire sck_rising = (sck_r[2:1] == 2'b01);

    // Registradores
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        rx_valid <= 0; // Padrão: validade é zero

        if (cs_r[2]) begin // Se CS está ALTO (Desativado)
            bit_cnt <= 0;
        end else if (sck_rising) begin // Borda de subida do SCK
            shift_reg <= {shift_reg[6:0], mosi_r[2]}; // Desloca bit
            bit_cnt <= bit_cnt + 1;
            
            if (bit_cnt == 7) begin // Recebeu 8 bits?
                rx_data <= {shift_reg[6:0], mosi_r[2]};
                rx_valid <= 1; // Avisa o sistema!
            end
        end
    end
endmodule