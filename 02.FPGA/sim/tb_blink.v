`timescale 1ns/1ps
module tb_blink;

    //1. Sinais para ligar no modulo
    reg r_clk;
    wire w_led;

    //2. Instancia o modulo para o teste (Device Under Test - DUT)
    blink dut (
        .clk(r_clk),
        .led(w_led)
    );

    //3. Gerador de Clock falso
    initial begin
        r_clk = 0;
        //cria um loop infinito trocando o clock a cada 20ns (250MHz)
        forever #20 r_clk = ~r_clk;
    end

    //4. Controle da Simulação
    initial begin
        $dumpfile("blink_wave.vcd");
        $dumpvars(0, tb_blink);

        //testar a subida do contador
        #10000;
        $finish;
    end
endmodule