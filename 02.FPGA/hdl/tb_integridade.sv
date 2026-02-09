`timescale 1ns/1ps

module tb_integridade;
    // Sinais de interface
    logic clk_in, spi_cs, spi_sck, spi_mosi, rst;
    logic spi_miso;
    logic [1:0] led;

    // Instanciação do Device Under Test (DUT)
    // Usando o nome que você definiu para o arquivo
    //top_integridade
    top dut (
        .clk_in(clk_in),
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .rst(rst),
        .spi_miso(spi_miso),
        .led(led)
    );

    // Gerador de Clock Principal (25MHz -> Período de 40ns)
    initial clk_in = 0;
    always #20 clk_in = ~clk_in;

    // Tarefa para simular o comportamento do mestre (RP2040)
    task enviar_byte(input [7:0] dado, input integer bits_para_enviar);
        integer i;
        $display("[SIM] Iniciando envio: 0x%h (%0d bits)", dado, bits_para_enviar);
        
        spi_cs = 0; // Ativa o Chip Select
        #200;       // Tempo de setup

        for (i = 7; i > 7 - bits_para_enviar; i = i - 1) begin
            spi_mosi = dado[i];
            #400; spi_sck = 1; // Borda de subida (FPGA amostra aqui)
            #400; spi_sck = 0; // Borda de descida
            #400;
        end

        #200;
        spi_cs = 1; // Desativa CS (Gatilho da Auditoria de Integridade)
        #1000;      // Espaço entre mensagens
    endtask

    // Procedimento de Teste
    initial begin
        // Configuração para visualização no VS Code (WaveTrace/GTKWave)
        $dumpfile("integridade.vcd");
        $dumpvars(0, tb_integridade);

        // 1. Reset do Sistema
        rst = 1; spi_cs = 1; spi_sck = 0; spi_mosi = 0;
        #100 rst = 0; 
        #200;

        // CENÁRIO A: Transação Válida (8 bits, Valor = 35)
        // O LED Vermelho deve acender (led[0]=0) pois 35 > 30
        // O LED Verde deve acender (led[1]=0) pois integridade é OK
        $display("Simulando: Envio válido de 8 bits (35C)");
        enviar_byte(8'd35, 8);

        // CENÁRIO B: Transação Válida (8 bits, Valor = 25)
        // O LED Vermelho deve apagar (led[0]=1) pois 25 < 30
        // O LED Verde deve continuar aceso (led[1]=0)
        $display("Simulando: Envio válido de 8 bits (25C)");
        enviar_byte(8'd25, 8);

        // CENÁRIO C: Falha de Integridade (Simulando ruído que "comeu" 1 bit)
        // Enviamos apenas 7 bits. O LED Verde DEVE APAGAR (led[1]=1)
        // O LED Vermelho não deve mudar, pois a transação foi descartada.
        $display("Simulando: ERRO - Apenas 7 bits detectados");
        enviar_byte(8'hFF, 7); 

        #2000;
        $display("[SIM] Simulação finalizada. Analise o arquivo .vcd");
        $finish;
    end
endmodule
