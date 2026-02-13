// -------------------------------------------------------------------------
// Módulo: servo.sv
// Objetivo: Fazer um Servo Motor (SG90) ir de 0 a 180 graus e voltar.
// Plataforma: FPGA Colorlight i5 (Lattice ECP5)
// Clock Base: 25 MHz (25 milhões de pulsos por segundo)
// -------------------------------------------------------------------------

module servo (
    // --- ENTRADAS (O que entra na FPGA) ---
    input  logic clk,       // O coração da placa: bate 25.000.000 vezes/segundo
    
    // --- SAÍDAS (O que sai da FPGA para o mundo) ---
    output logic servo_pin, // O sinal PWM que vai para o fio Laranja do servo
    output logic led_verde, // Acenderá quando o motor estiver "indo" (0 -> 180)
    output logic led_verm   // Acenderá quando o motor estiver "voltando" (180 -> 0)
);

    // =========================================================================
    // BLOCO 1: A MATEMÁTICA DO TEMPO (CONSTANTES)
    // O Servo SG90 funciona com uma frequência de 50Hz (um ciclo a cada 20ms).
    // Como nosso clock é 25MHz, precisamos contar quantos "ticks" cabem em 20ms.
    // Cálculo: 20ms * 25.000.000Hz = 500.000 ticks.
    // =========================================================================
    
    localparam PERIODO = 500000;    // O tamanho total do ciclo (20ms)
    
    // O Servo decide o ângulo baseado no tempo que o sinal fica LIGADO (High):
    // 1ms = 0 Graus   -> 1ms * 25MHz = 25.000 ticks
    // 2ms = 180 Graus -> 2ms * 25MHz = 50.000 ticks
    localparam MIN_0G   = 25000;    // Posição mínima (0°)
    localparam MAX_180G = 50000;    // Posição máxima (180°)
    
    // =========================================================================
    // BLOCO 2: VARIÁVEIS DE MEMÓRIA (REGISTRADORES)
    // Aqui criamos as "caixinhas" onde a FPGA guarda os números enquanto trabalha.
    // =========================================================================

    // O cronômetro principal. Ele conta de 0 até 500.000 repetidamente.
    logic [19:0] contador_pwm = 0; 

    // A posição atual do servo. Começa em 0 graus (25.000) e vai mudar com o tempo.
    logic [19:0] largura_pulso = MIN_0G; 

    // O "GPS" do motor: 0 significa que estamos subindo o ângulo, 1 descendo.
    logic direcao = 0; 
    
    // Um freio de mão. A FPGA é muito rápida (nanosegundos). O motor é lento (milisegundos).
    // Usamos este contador para "esperar" um pouco antes de mudar o ângulo, 
    // senão o motor tenta ir de 0 a 180 instantaneamente.
    logic [15:0] divisor_velocidade = 0; 

    // =========================================================================
    // BLOCO 3: O MOTOR DE PROCESSAMENTO (EXECUTA A CADA CLOCK)
    // Tudo aqui dentro acontece 25 milhões de vezes por segundo!
    // =========================================================================
    always_ff @(posedge clk) begin
        
        // --- PARTE A: O CRONÔMETRO (Gera os 50Hz) ---
        // Se chegamos ao fim do período (20ms), zeramos o relógio.
        if (contador_pwm >= PERIODO) 
            contador_pwm <= 0;
        else 
            // Senão, continua contando: 1, 2, 3... até 500.000
            contador_pwm <= contador_pwm + 1;


        // --- PARTE B: O GERADOR DE SINAL (Cria a Onda Quadrada) ---
        // Aqui está a mágica do PWM.
        // Enquanto o cronômetro for MENOR que a posição desejada, o pino fica LIGADO (1).
        // Assim que o cronômetro passar da posição, o pino DESLIGA (0).
        // Exemplo: Se 'largura_pulso' é 25.000, o pino fica 1ms ligado e 19ms desligado.
        servo_pin <= (contador_pwm < largura_pulso);


        // --- PARTE C: A LÓGICA DE MOVIMENTO (O Sweep) ---
        // Só tomamos decisões de movimento quando o ciclo reinicia (contador == 0).
        // Isso evita "glitches" (falhas) no meio do pulso.
        if (contador_pwm == 0) begin 
            
            // Aqui usamos o "freio".
            // Se 'divisor_velocidade' chegar a 200 ciclos, nós movemos o motor um pouquinho.
            // Se não, apenas esperamos (incrementamos o divisor).

            // if (divisor_velocidade == 200) begin 
            //     divisor_velocidade <= 0; // Reinicia a espera
                
            //     // Se a direção é SUBIDA (0)
            //     if (direcao == 0) begin
            //         largura_pulso <= largura_pulso + 50; // Anda um passinho para a direita
                    
            //         // Se chegou no limite máximo (180°), mude a direção para DESCIDA
            //         if (largura_pulso >= MAX_180G) direcao <= 1;
            //     end 
            //     // Se a direção é DESCIDA (1)
            //     else begin
            //         largura_pulso <= largura_pulso - 50; // Anda um passinho para a esquerda
                    
            //         // Se chegou no limite mínimo (0°), mude a direção para SUBIDA
            //         if (largura_pulso <= MIN_0G) direcao <= 0;
            //     end
            // end else begin
            //     // Ainda não é hora de mover, conte mais um ciclo de espera.
            //     divisor_velocidade <= divisor_velocidade + 1;
            // end
            // Muda a cada 40ms (2 ciclos de 20ms) -> Velocidade normal de servo
            if (divisor_velocidade >= 2) begin 
                divisor_velocidade <= 0;
                
                if (direcao == 0) begin
                    largura_pulso <= largura_pulso + 250; // <-- Passo maior (100 passos totais)
                    if (largura_pulso >= MAX_180G) direcao <= 1;
                end else begin
                    largura_pulso <= largura_pulso - 250; // <-- Passo maior
                    if (largura_pulso <= MIN_0G) direcao <= 0;
                end
            end else begin
                divisor_velocidade <= divisor_velocidade + 1;
            end
        end
    end

    // =========================================================================
    // BLOCO 4: FEEDBACK VISUAL (LEDs)
    // =========================================================================
    // Conecta os LEDs à variável 'direcao'.
    // Se direcao == 0, LED verde acende. Se direcao == 1, LED vermelho acende.
    assign led_verde = (direcao == 0); 
    assign led_verm  = (direcao == 1); 

endmodule