module top_servo_test (
    input  wire clk,          // Clock 25 MHz (P3)
    output reg  servo_pin,     // Pino do servo (L4)
    output reg  led_verde,     // LED verde (N4)
    output reg  led_verm       // LED vermelho (P16)
);

    // Contador simples para gerar atraso visível
    // 25 MHz -> 25.000.000 ciclos ≈ 1 segundo
    reg [24:0] counter;
    initial begin
        counter   = 0;
        servo_pin = 0;
        led_verde = 0;
        led_verm  = 1;
    end


    always @(posedge clk) begin
        counter <= counter + 1;

        if (counter == 25_000_000) begin
            counter   <= 0;
            servo_pin <= ~servo_pin;
            led_verde <= ~led_verde;
            led_verm  <= ~led_verm;
        end
    end

endmodule
