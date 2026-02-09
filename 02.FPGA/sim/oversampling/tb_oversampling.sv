`timescale 1ns/1ps

module tb_oversampling;
    // Declaração de sinais
    logic clk_in, spi_cs, spi_sck, spi_mosi, rst, spi_miso;
    logic [1:0] led;

    // Instanciação do módulo com Amostragem Retardada
    top dut (.*);

    // Gerador de Clock Principal (25MHz -> 40ns)
    initial clk_in = 0;
    always #20 clk_in = ~clk_in;

    initial begin
        // Configuração dos arquivos de onda para VS Code
        $dumpfile("oversampling.vcd");
        $dumpvars(0, tb_oversampling);
        
        // --- ESTADO INICIAL ---
        $display("\n[SIM] --- INICIANDO TESTE 3: OVERSAMPLING (AMOSTRAGEM NO CENTRO DO BIT) ---");
        rst = 1; spi_cs = 1; spi_sck = 0; spi_mosi = 0;
        #100 rst = 0; 
        #200;

        // --- CENÁRIO: SIMULAÇÃO DE SKEW (ATRASO CRÍTICO) ---
        $display("[SIM] Passo 1: Iniciando transação com atraso proposital de sinal (Skew)");
        spi_cs = 0; 
        #200;

        // Simulando um problema físico real: O dado MOSI demora a subir
        // Em um sistema comum, isso causaria erro. No Teste 3, a FPGA deve esperar.
        $display("[SIM] Passo 2: Subindo o Clock (SCK), mas mantendo o Dado (MOSI) instável por 20ns");
        spi_sck = 1; 
        #20;          
        spi_mosi = 1; // O dado só fica correto 20ns APÓS o clock subir
        #380;
        
        $display("[SIM] Passo 3: Clock desce. A FPGA deve ter capturado o dado apenas no 4o ciclo de clk_in.");
        spi_sck = 0; 

        // --- FINALIZAÇÃO E ANÁLISE ---
        #500;
        spi_cs = 1; // Gatilho de auditoria
        
        $display("[SIM] Passo 4: Verificando integridade final.");
        #100;
        
        $display("[SIM] Analise no Waveform:");
        $display("      - O contador 'sample_delay_cnt' deve subir após a borda do SCK.");
        $display("      - A captura no 'shift_reg' deve ocorrer exatamente quando o contador atingir 4.");
        $display("      - Isso prova que ignoramos a instabilidade dos primeiros 20ns.");

        #1000;
        $display("[SIM] --- FIM DO TESTE 3 --- \n");
        $finish;
    end
endmodule