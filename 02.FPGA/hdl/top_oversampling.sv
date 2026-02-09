module top_oversampling (
    input  logic clk_in, spi_cs, spi_sck, spi_mosi, rst,
    output logic spi_miso,
    output logic [1:0] led
);
    // 1. FILTRO DE MAIORIA (Herdado do Teste 2)
    logic [3:0] sck_hist, cs_hist, mosi_hist;
    logic sck_f, cs_f, mosi_f;

    always_ff @(posedge clk_in) begin
        sck_hist  <= {sck_hist[2:0], spi_sck};
        cs_hist   <= {cs_hist[2:0],  spi_cs};
        mosi_hist <= {mosi_hist[2:0], spi_mosi};

        if (sck_hist == 4'b1111) sck_f <= 1'b1; else if (sck_hist == 4'b0000) sck_f <= 1'b0;
        if (cs_hist  == 4'b1111) cs_f  <= 1'b1; else if (cs_hist  == 4'b0000) cs_f  <= 1'b0;
        if (mosi_hist == 4'b1111) mosi_f <= 1'b1; else if (mosi_hist == 4'b0000) mosi_f <= 1'b0;
    end

    // 2. DETECÇÃO DE BORDA E ATRASO DE AMOSTRAGEM (Oversampling)
    logic sck_f_prev, cs_f_prev;
    logic [2:0] sample_delay_cnt;
    always_ff @(posedge clk_in) begin
        sck_f_prev <= sck_f;
        cs_f_prev  <= cs_f;
    end

    wire sck_posedge = (sck_f && !sck_f_prev);
    wire cs_end      = (cs_f && !cs_f_prev);

    // 3. LÓGICA DE CAPTURA COM ATRASO
    logic [3:0] bit_cnt;
    logic [7:0] shift_reg, data_latch;
    logic integrity_ok;

    always_ff @(posedge clk_in) begin
        if (cs_f) begin
            bit_cnt <= 0;
            sample_delay_cnt <= 0;
        end else begin
            // Quando detecta a subida do clock, inicia contagem de atraso
            if (sck_posedge) begin
                sample_delay_cnt <= 3'd1;
            end 
            // Após 4 ciclos de clock da FPGA (160ns), captura o bit MOSI
            else if (sample_delay_cnt > 0 && sample_delay_cnt < 3'd5) begin
                sample_delay_cnt <= sample_delay_cnt + 3'd1;
            end

            // MOMENTO DA CAPTURA REAL (Amostragem Retardada)
            if (sample_delay_cnt == 3'd4) begin
                bit_cnt <= bit_cnt + 1;
                shift_reg <= {shift_reg[6:0], mosi_f};
                sample_delay_cnt <= 0; // Reseta para o próximo bit
            end
        end

        if (cs_end) begin
            integrity_ok <= (bit_cnt == 4'd8);
            if (bit_cnt == 4'd8) data_latch <= shift_reg;
        end
    end

    assign led[1] = !integrity_ok; 
    assign led[0] = (data_latch > 8'd30) ? 1'b0 : 1'b1;
    assign spi_miso = spi_mosi;
endmodule