// Arquivo: tbservo.sv
`timescale 1ns/1ps

module tbservo;

    logic clk;
    logic servo_pin;
    logic led_verde, led_verm;

    // Conecta com o módulo principal
    servo uut (
        .clk(clk),
        .servo_pin(servo_pin),
        .led_verde(led_verde),
        .led_verm(led_verm)
    );

    // Gera um clock falso de 25MHz
    initial begin
        clk = 0;
        forever #20 clk = ~clk; // Oscila a cada 20ns
    end

    // Configura a gravação do arquivo de onda
    initial begin
        $dumpfile("ondas_servo.vcd"); // Nome do arquivo que o GTKWave vai ler
        $dumpvars(0, tbservo);
        
        // Roda por tempo suficiente para ver alguns ciclos
        #60000000; // Espera 60ms (3 ciclos de PWM)
        $finish;
    end
endmodule