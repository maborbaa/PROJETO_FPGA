/* * Arquivo: top_soc.sv
 * Objetivo: Wrapper principal do SoC integrando PicoRV32, RAM e Periféricos (SPI/LEDs)
 * Autor: Márcio Barbosa (Mentoría Técnica)
 */

module top_soc (
    input  logic clk_in,   // Clock de 25MHz (BitDogLab)
    input  logic rst_in,   // Reset Ativo Baixo (Vem do tb_bootloader)
    input  logic spi_cs, 
    input  logic spi_sck, 
    input  logic spi_mosi,
    output logic spi_miso,
    output logic [7:0] led // LEDs de diagnóstico (8 bits)
);

    // --- 1. SUBSISTEMA SPI (Lógica de Robustez do Teste 3) ---
    logic [3:0] sck_hist, cs_hist, mosi_hist;
    logic sck_f, cs_f, mosi_f;
    logic sck_f_prev;
    logic [2:0] sample_delay_cnt;
    logic [3:0] bit_cnt;
    logic [7:0] shift_reg;
    logic [7:0] data_latch_spi; 

    // Filtro de Maioria (Majority Filter)
    always_ff @(posedge clk_in) begin
        sck_hist  <= {sck_hist[2:0], spi_sck};
        cs_hist   <= {cs_hist[2:0],  spi_cs};
        mosi_hist <= {mosi_hist[2:0], spi_mosi};

        if (sck_hist == 4'b1111) sck_f <= 1'b1; else if (sck_hist == 4'b0000) sck_f <= 1'b0;
        if (cs_hist  == 4'b1111) cs_f  <= 1'b1; else if (cs_hist  == 4'b0000) cs_f  <= 1'b0;
        if (mosi_hist == 4'b1111) mosi_f <= 1'b1; else if (mosi_hist == 4'b0000) mosi_f <= 1'b0;
    end

    // Detecção de Borda e Captura com Oversampling
    always_ff @(posedge clk_in) sck_f_prev <= sck_f;
    wire sck_posedge = (sck_f && !sck_f_prev);
    wire cs_active   = !cs_f;

    always_ff @(posedge clk_in) begin
        if (!cs_active) begin
            bit_cnt <= 0;
            sample_delay_cnt <= 0;
        end else begin
            if (sck_posedge) sample_delay_cnt <= 3'd1;
            else if (sample_delay_cnt > 0 && sample_delay_cnt < 3'd5)
                sample_delay_cnt <= sample_delay_cnt + 3'd1;

            if (sample_delay_cnt == 3'd4) begin
                bit_cnt   <= bit_cnt + 1;
                shift_reg <= {shift_reg[6:0], mosi_f};
                sample_delay_cnt <= 0;
            end
        end
        // Atualiza o registrador quando o CS sobe (Fim da transação)
        if (cs_f && !cs_hist[1]) begin
            if (bit_cnt == 4'd8) data_latch_spi <= shift_reg;
        end
    end
    assign spi_miso = spi_mosi; // Loopback de diagnóstico

    // --- 2. BARRAMENTO DO PROCESSADOR RISC-V ---
    logic        mem_valid;
    logic        mem_ready;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [ 3:0] mem_wstrb;
    logic [31:0] mem_rdata;

    // --- 3. INSTANCIAÇÃO DO PICORV32 ---
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_REGS_16_31(1),
        .PROGADDR_RESET(32'h 0000_0000), // Início da RAM
        .STACKADDR(32'h 0000_0F00)      // Fim da RAM (4KB)
    ) cpu (
        .clk         (clk_in),
        .resetn      (rst_in),
        .mem_valid   (mem_valid),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata)
    );

    // --- 4. DECODIFICADOR DE ENDEREÇOS (Memory Map) ---
    logic [7:0] led_reg;
    logic ram_ready;
    logic [31:0] ram_rdata;
    logic [31:0] keyboard_dummy = 32'hCAFE_BABE; // Placeholder Teclado

    // Sinais de Seleção baseados no firmware.c
    wire sel_ram = (mem_addr[31:16] == 16'h0000); // 0x00000000
    wire sel_spi = (mem_addr == 32'h0001_0000);   // REG_SPI
    wire sel_led = (mem_addr == 32'h0002_0000);   // REG_LEDS
    wire sel_kbd = (mem_addr == 32'h0003_0000);   // REG_KEYBOARD

    always_comb begin
        mem_ready = 1'b0;
        mem_rdata = 32'h0;
        if (sel_ram) begin
            mem_ready = ram_ready;
            mem_rdata = ram_rdata;
        end else if (sel_spi) begin
            mem_ready = 1'b1;
            mem_rdata = {24'd0, data_latch_spi};
        end else if (sel_led) begin
            mem_ready = 1'b1;
            mem_rdata = {24'd0, led_reg};
        end else if (sel_kbd) begin
            mem_ready = 1'b1;
            mem_rdata = keyboard_dummy;
        end
    end

    // Registro de Saída (Escrita nos LEDs)
    always_ff @(posedge clk_in) begin
        if (!rst_in) led_reg <= 8'h00;
        else if (mem_valid && sel_led && mem_wstrb[0]) 
            led_reg <= mem_wdata[7:0];
    end

    assign led = led_reg;

    // --- 5. INSTANCIAÇÃO DA MEMÓRIA (IP CORE INFERIDO) ---
    soc_memory ram_inst (
        .clk(clk_in),
        .valid(mem_valid && sel_ram),
        .ready(ram_ready),
        .addr(mem_addr[11:2]), // Endereço de palavra (4KB = 1024 words)
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .rdata(ram_rdata)
    );

endmodule