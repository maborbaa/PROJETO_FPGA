module top_servo_pwm (
    input  wire clk,          // 25 MHz (P3)
    output reg  servo_pin,     // L4
    output reg  led_verde,     // N4
    output reg  led_verm       // P16
);

    // -----------------------------
    // PWM do servo
    // -----------------------------
    reg [18:0] pwm_counter;    // até 500.000
    reg [18:0] duty;           // largura do pulso

    // -----------------------------
    // Contador lento (troca posição)
    // -----------------------------
    reg [25:0] slow_counter;   // ~2 segundos

    // -----------------------------
    // PWM de 20 ms
    // -----------------------------
    always @(posedge clk) begin
        if (pwm_counter == 19'd499_999)
            pwm_counter <= 0;
        else
            pwm_counter <= pwm_counter + 1;

        // gera PWM
        servo_pin <= (pwm_counter < duty);
    end

    // -----------------------------
    // Alterna posição do servo
    // -----------------------------
    always @(posedge clk) begin
        slow_counter <= slow_counter + 1;

        // ~2 segundos @25MHz
        if (slow_counter == 26'd50_000_000) begin
            slow_counter <= 0;

            // alterna posição
            if (duty == 19'd25_000) begin
                duty      <= 19'd50_000;  // ~2 ms
                led_verde <= 0;
                led_verm  <= 1;
            end else begin
                duty      <= 19'd25_000;  // ~1 ms
                led_verde <= 1;
                led_verm  <= 0;
            end
        end
    end

    // -----------------------------
    // Inicialização
    // -----------------------------
    initial begin
        pwm_counter  = 0;
        slow_counter = 0;
        duty         = 19'd25_000; // começa em 1 ms
        led_verde    = 1;
        led_verm     = 0;
        servo_pin    = 0;
    end

endmodule
