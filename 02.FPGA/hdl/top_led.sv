module servo (
    input clk,          // clock de 25 MHz
    input rst,
    input [19:0] duty,  // 19 bits é suficiente até ~500000
    output reg pwm_out
);

    reg [19:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            pwm_out <= 0;
        end else begin
            // Periodo ~20 ms @25 MHz = 500000
            if (counter >= 20'd500000)
                counter <= 0;
            else
                counter <= counter + 1;

            // PWM: alto quando counter < duty
            if (counter < duty)
                pwm_out <= 1;
            else
                pwm_out <= 0;
        end
    end

endmodule
