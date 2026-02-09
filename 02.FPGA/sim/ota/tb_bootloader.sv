`timescale 1ns/1ps

module tb_bootloader;
// Sinais
    logic clk;
    logic rst_n;
    logic [7:0] led;
    
    // Sinais SPI (Ligados em nada por enquanto, pull-up)
    logic spi_sck = 0;
    logic spi_mosi = 0;
    logic spi_cs = 1;

    // Instância do SoC Completo
    top_soc u_top (
        .clk_in   (clk),
        .rst_in   (rst_n),
        .led      (led),
        .spi_sck  (spi_sck),
        .spi_mosi (spi_mosi),
        .spi_cs   (spi_cs)
    );

    // Gerador de Clock (25MHz)
    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end

    // Controle da Simulação
    initial begin
        $dumpfile("sim/ota/soc_ondas.vcd");
        $dumpvars(0, tb_bootloader);

        // Sequência de Reset
        rst_n = 0; // Segura o reset
        #200;
        rst_n = 1; // Solta o reset (O processador deve acordar aqui!)

        // Deixa rodar por um tempo suficiente para ver o boot
       // #5000; 

        // Aumente de #5000 para #500000 (ou mais)
        // 500.000ns = 500us (tempo suficiente para o RISC-V dar o boot)
       // #500000;
        #1000000; // 1 milhão de ns = 1 milisegundo (tempo de sobra para o boot)
        
        $display("Simulação finalizada.");
        $finish;
    end

endmodule