`include "adder-float.v"
module float_adder_tb;

    reg clk;
    reg rst;
    reg [31:0] A, B;
    wire [31:0] Z;
    wire [1:0] overflow;

    float_adder uut (
        .clk(clk),
        .rst(rst),
        .x(A),
        .y(B),
        .z(Z),
        .overflow(overflow)
    );

    // 时钟信号生成
    always begin
        #5 clk = ~clk; // 10时间单位的周期
    end

    // 测试逻辑
    initial begin
        clk = 0;  // 初始化时钟为0
        rst = 1;  // 初始化复位为1
        A = 32'h3F800000;  // 浮点数 1.0
        B = 32'h40000000;  // 浮点数 2.0
        #10 rst = 0;
        // 等待加法器完成操作
        wait(uut.current_state == 3'b101);
        #10;
        $display("Result: %h Overflow: %b", Z, overflow); // 打印输出结果
        $finish;   // 结束仿真
    end
endmodule