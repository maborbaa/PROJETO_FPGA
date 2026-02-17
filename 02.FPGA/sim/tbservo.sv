`timescale 1ns/1ps  // A "Régua" do tempo. 1ns é a menor unidade que vamos usar.

module tbservo;

    // Fios virtuais para conectar no módulo "servo"
    logic clk;
    logic servo_pin;
    logic led_verde, led_verm;

    // INSTÂNCIA (UUT - Unit Under Test)
    // Aqui conectamos o seu módulo "servo.sv" a estes fios virtuais.
    servo uut (
        .clk(clk),
        .servo_pin(servo_pin),
        .led_verde(led_verde),
        .led_verm(led_verm)
    );

    // GERADOR DE CLOCK (O Coração Artificial)
    // Para ter 25MHz, o período é 40ns (1 / 25.000.000).
    // Então o sinal deve ficar 20ns ligado e 20ns desligado.
    initial begin
        clk = 0;
        // "forever" significa: faça isso para sempre enquanto a simulação rodar.
        forever #20 clk = ~clk; // A cada 20ns, inverte o sinal (0->1, 1->0).
    end

    // O DIRETOR DA SIMULAÇÃO
    initial begin
        // Liga o gravador. O arquivo "ondas_servo.vcd" será criado na pasta onde você rodar o comando.
        $dumpfile("ondas_servo.vcd"); 
        
        // Grava TUDO (nível 0) que estiver dentro do módulo "tbservo".
        $dumpvars(0, tbservo);
        
        // A DURAÇÃO DO FILME
        // 60.000.000 nanosegundos = 60 milissegundos.
        // Como o servo funciona a 50Hz (20ms), isso dará exatamente 3 CICLOS COMPLETOs.
        #60000000; 
        
        // Corta! Fim da simulação.
        $finish;