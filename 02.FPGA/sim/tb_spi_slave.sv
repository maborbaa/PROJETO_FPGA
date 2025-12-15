`timescale 1ns/1ps

module tb_spi_slave;

    // 1. Sinais declarados (DUT - Device Under Test)
    logic clk_in;
    logic rst_in;
    logic sck_in;
    logic mosi_in;
    logic cs_in;
    
    // Saídas que vamos observar
    logic [7:0] data_out_o;
    logic data_valid_o;
    logic sck_rise_o; // Debug

    // 2. Instancias SPI Slave - conectar os fios
    spi_slave DUT (
        .clk(clk_in),
        .rst(rst_in),
        .sck(sck_in),
        .mosi(mosi_in),
        .cs(cs_in),
        .data_out(data_out_o),
        .data_valid(data_valid_o),
        .sck_rise(sck_rise_o)
    );

    // 3. Gerar clock da FPGA (25MHz)
    initial begin
        clk_in = 0;
        forever begin
             #20 clk_in = ~clk_in; //inverte a cada 20ns (total 40ns)
        end
    end

    // 4. Testar as conecções
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0,tb_spi_slave);

        // A. Estado Inicial
        rst_in = 0; // Reset apertado (ativo baixo)
        cs_in = 1;  // Desligado (ativo baixo)
        sck_in = 0;
        mosi_in = 0;
    
        #100; // Espera o sistema estabilizar
        rst_in = 1; // Solta o reset
        #100;

        // B. Começar Transmissão: RP2040 ativa o chip
        $display("Iniciando transmissao SPI...");
        cs_in = 0; 
        #200; // Pequena pausa

        // C. Enviar o byte 0xA5 (Binário: 10100101)
        // Vamos criar uma tarefa (função) para enviar bit a bit para não repetir código
        enviar_byte(8'hA5);

        // D. Finalizar
        #100;
        cs_in = 1; // Desativa o chip
        
        #200;
        $display("Teste finalizado. Verifique se data_out = A5 e data_valid pulsou.");
        $finish;
    end

        // --- Tarefa Auxiliar: Simula o envio de 1 Byte via SPI ---
    task enviar_byte(input logic [7:0] valor);
        integer i;
        begin
            // Loop para enviar 8 bits (do mais significativo 7 para o 0)
            for (i = 0; i <= 7; i = i + 1) begin
                // 1. Coloca o bit no fio MOSI
                // O protocolo SPI envia o Bit Mais Significativo (MSB) primeiro (Bit 7).
                // Quando i=0, queremos o bit 7. (7 - 0 = 7)
                // Quando i=1, queremos o bit 6. (7 - 1 = 6)
                mosi_in = valor[7 - i]; 
                #100; // aguarda a RP2040

                // 2. Sobe o Clock (SCK High) - A FPGA lê aqui!
                sck_in = 1; // subida - verifica o bit
                #100; //espero clock alto

                // 3. Desce o Clock (SCK Low)
                sck_in = 0; // descida - prepara o próximo
                #100; //espera para recomeçar o loop
            end
        end
    endtask

endmodule


