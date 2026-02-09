module top_integridade (
    input  logic clk_in, spi_cs, spi_sck, spi_mosi, rst,
    output logic spi_miso,
    output logic [1:0] led
);
    // 1. Sincronizadores de Entrada (Sutherland)
    logic [2:0] sck_sync, cs_sync;
    always_ff @(posedge clk_in) begin
        sck_sync <= {sck_sync[1:0], spi_sck};
        cs_sync  <= {cs_sync[1:0], spi_cs};
    end
    
    // 2. Detecção de Borda e Estado
    wire sck_posedge = (sck_sync[1] && !sck_sync[2]);
    wire cs_active   = !cs_sync[1]; // Ativo em nível baixo (0)
    wire cs_done     = (cs_sync[1] && !cs_sync[0]); // Borda de subida do CS (Fim)

    // 3. Auditoria de Integridade
    logic [3:0] bit_counter;
    logic [7:0] shift_reg;
    logic [7:0] data_latch;
    logic integrity_ok;

    always_ff @(posedge clk_in) begin
        if (!cs_active) begin
            bit_counter <= 0; // Reseta ao final/início da conversa
        end else if (sck_posedge) begin
            bit_counter <= bit_counter + 1;
            shift_reg   <= {shift_reg[6:0], spi_mosi};
        end

        // No momento em que o RP2040 sobe o CS, validamos a contagem
        if (cs_done) begin
            if (bit_counter == 4'd8) begin
                integrity_ok <= 1'b1;
                data_latch   <= shift_reg; // Dado salvo com sucesso
            end else begin
                integrity_ok <= 1'b0; // Erro detectado: transação inválida
            end
        end
    end

    // 4. Interface Visual (Lógica Ativa em Baixo)
    assign led[1] = !integrity_ok;  // LED Verde aceso = Comunicação íntegra
    assign led[0] = (data_latch > 8'd30) ? 1'b0 : 1'b1; // LED Vermelho aceso = Temp > 30
    assign spi_miso = spi_mosi; // Loopback físico para depuração
endmodule