`timescale 1ns/1ps

module tb_filtro;
    // Declaração de sinais
    logic clk_in, spi_cs, spi_sck, spi_mosi, rst, spi_miso;
    logic [1:0] led;

    // Instanciação do Módulo com Filtro Majoritário
    top dut (.*);

    // Gerador de Clock Principal (25MHz -> 40ns)
    initial clk_in = 0;
    always #20 clk_in = ~clk_in;

    initial begin
        // Configuração dos arquivos de onda para VS Code/GTKWave
        $dumpfile("filtro_glitch.vcd");
        $dumpvars(0, tb_filtro);
        
        // --- ESTADO INICIAL ---
        $display("\n[SIM] --- INICIANDO TESTE 2: FILTRO DE GLITCH (VOTACAO MAJORITARIA) ---");
        rst = 1; spi_cs = 1; spi_sck = 0; spi_mosi = 0;
        #100 rst = 0; 
        #200;

        // --- CENARIO A: ENVIO DE BIT VALIDO ---
        $display("[SIM] Passo 1: Enviando 1 bit normal (Pulso de clock estavel)");
        spi_cs = 0;   // Ativa comunicacao
        #200;
        spi_mosi = 1; // Dado
        #100;
        spi_sck = 1;  // Subida de clock valida (400ns)
        #400; 
        spi_sck = 0; 
        #100;

        // --- CENARIO B: INJECAO DE RUIDO (GLITCH) ---
        $display("[SIM] Passo 2: Injetando Glitch de 20ns no SCK (Ruido impulsivo)");
        // Este pulso dura apenas 20ns. Como o filtro exige 4 ciclos de 40ns (160ns), 
        // a FPGA DEVE ignorar este pulso.
        spi_sck = 1; 
        #20;           // Ruido muito rapido!
        spi_sck = 0; 
        #380;          // Espera para estabilizacao

        // --- VALIDACAO ---
        $display("[SIM] Passo 3: Finalizando transacao e verificando Auditoria");
        #200;
        spi_cs = 1;    // Sobe CS para disparar a contagem final
        
        #100;
        // Se o filtro funcionou, o contador interno da FPGA deve ser 1, não 2.
        // O LED Verde (led[1]) estara APAGADO (1) porque 1 bit != 8 bits (Erro de Integridade esperado)
        // Mas o importante aqui e ver se o bit_cnt no Waveform ignorou o ruido.
        $display("[SIM] Verificacao: O bit_counter no GTKWave deve marcar exatamente 1 bit.");
        $display("[SIM] Se marcar 2, o Filtro de Glitch falhou.");
        
        #1000;
        $display("[SIM] --- FIM DO TESTE 2 --- \n");
        $finish;
    end
endmodule