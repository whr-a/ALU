/* ACM Class System (I) Fall Assignment 1 
 *
 *
 * Implement your naive adder here
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put this file into `Sources'
 *   3. Put `test_adder.v' into `Simulation Sources'
 *   4. Run Behavioral Simulation
 *   5. Make sure to run at least 100 steps during the simulation (usually 100ns)
 *   6. You can see the results in `Tcl console'
 *  
 */
 //Notice: This is 32bit adder.
module cla(
	input  [3:0] g,
	input  [3:0] p,
	input  ci,
	output c1,
	output c2,
	output c3,
	output c4
);
	assign c1 = g[0] ^ (ci & p[0]);
	assign c2 = g[1] ^ (g[0] & p[1]) ^ (ci & p[1] & p[0]);
	assign c3 = g[2] ^ (g[1] & p[2]) ^ (g[0] & p[2] & p[1]) ^ (ci & p[2] & p[1] & p[0]);
	assign c4 = g[3] ^ (g[2] & p[3]) ^ (g[1] & p[3] & p[2]) ^ (g[0] & p[3] & p[2] & p[1]) ^ (ci & p[3] & p[2] & p[1] & p[0]);
endmodule
module adder(
  	input X,
  	input Y,
  	input Cin,
  	output F,
  	output Cout
);
  	assign F = X ^ Y ^ Cin;
  	assign Cout = (X ^ Y) & Cin | X & Y;
endmodule
module adder_4(
    input [4:1] x,
    input [4:1] y,
    input c0,
    output c4,
	output Gm,
	output Pm,
    output [4:1] F
);
	wire [4:1] g;
	wire [4:1] p;
    wire c1,c2,c3;
    adder adder1(.X(x[1]), .Y(y[1]), .Cin(c0), .F(F[1]), .Cout());
    adder adder2(.X(x[2]), .Y(y[2]), .Cin(c1), .F(F[2]), .Cout());  
    adder adder3(.X(x[3]), .Y(y[3]), .Cin(c2), .F(F[3]), .Cout());
    adder adder4(.X(x[4]), .Y(y[4]), .Cin(c3), .F(F[4]), .Cout());      
    cla CLA(.ci(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .p(p), .g(g));
  	assign  p[1] = x[1] ^ y[1],
           	p[2] = x[2] ^ y[2],
           	p[3] = x[3] ^ y[3],
           	p[4] = x[4] ^ y[4];

  	assign  g[1] = x[1] & y[1],
           	g[2] = x[2] & y[2],
           	g[3] = x[3] & y[3],
           	g[4] = x[4] & y[4];

  	assign  Pm = p[1] & p[2] & p[3] & p[4],
            Gm = g[4] ^ (p[4] & g[3]) ^ (p[4] & p[3] & g[2]) ^ (p[4] & p[3] & p[2] & g[1]);

endmodule

module adder_16bit(
    input [16:1] A,
    input [16:1] B,
    input c0,
    output gx,
	output px,
    output [16:1] S
);
    wire c4,c8,c12;
    wire Pm1,Gm1,Pm2,Gm2,Pm3,Gm3,Pm4,Gm4;

    adder_4 adder1(.x(A[4:1]), .y(B[4:1]), .c0(c0), .c4(), .F(S[4:1]), .Gm(Gm1), .Pm(Pm1));
    adder_4 adder2(.x(A[8:5]), .y(B[8:5]), .c0(c4), .c4(), .F(S[8:5]), .Gm(Gm2), .Pm(Pm2));
    adder_4 adder3(.x(A[12:9]), .y(B[12:9]), .c0(c8), .c4(), .F(S[12:9]), .Gm(Gm3), .Pm(Pm3));
    adder_4 adder4(.x(A[16:13]), .y(B[16:13]), .c0(c12), .c4(), .F(S[16:13]), .Gm(Gm4), .Pm(Pm4));
    assign  c4 = Gm1 ^ (Pm1 & c0),
            c8 = Gm2 ^ (Pm2 & Gm1) ^ (Pm2 & Pm1 & c0),
            c12 = Gm3 ^ (Pm3 & Gm2) ^ (Pm3 & Pm2 & Gm1) ^ (Pm3 & Pm2 & Pm1 & c0);

    assign  px = Pm1 & Pm2 & Pm3 & Pm4,
            gx = Gm4 ^ (Pm4 & Gm3) ^ (Pm4 & Pm3 & Gm2) ^ (Pm4 & Pm3 & Pm2 & Gm1);

endmodule

//32位并行进位加法器顶层模块
module adder_32bit(
    input [32:1] A,
    input [32:1] B,
    output [32:1] S,
    output C32
);
    wire px1,gx1,px2,gx2;
    wire c16;
  	adder_16bit adder1(.A(A[16:1]), .B(B[16:1]), .c0(0), .S(S[16:1]), .px(px1), .gx(gx1));
  	adder_16bit adder2(.A(A[32:17]), .B(B[32:17]), .c0(c16), .S(S[32:17]), .px(px2), .gx(gx2));
  	assign c16 = gx1 ^ (px1 && 0),
           C32 = gx2 ^ (px2 && c16);

endmodule

module Add(
	input [32:1] a,
	input [32:1] b,
	output reg [32:1] sum
);
	wire [32:1] answer;
	adder_32bit adder_inst(.A(a),.B(b),.S(answer),.C32());
	always @* begin
		sum <= answer;
	end
endmodule