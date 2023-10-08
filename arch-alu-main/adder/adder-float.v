module float_adder(
    input   clk,
    input   rst,
    input   [31:0]  x,
    input   [31:0]  y,
    output  reg [31:0]  z,
    output  reg [1:0]   overflow
    /*
        2'b00:没有溢出
        2'b01:上溢
        2'b10:下溢
        2'b11:输入不是规格数
    */
);
    reg [2:0]   current_state, next_state;
    /*
    000 开始
    001 检查0
    010 对齐
    011 相加
    100 标准化
    101 结束
    */
    reg sign_x, sign_y, sign_z;
    reg [7:0]   exp_x, exp_y, exp_z;
    reg [24:0]  mant_x, mant_y, mant_result;

    reg [24:0] out_x, out_y, mid_y, mid_x;
    reg [7:0] move_tot;
    reg [2:0] lastjudge;

    always @(posedge clk) begin
        if(rst)begin
            current_state <= 3'b000;
        end
        else begin
            // $display("%b\n",current_state);
            current_state <= next_state;
        end
    end

    always @(current_state, next_state, exp_x, exp_y, exp_z, mant_x, mant_y, mant_result, out_x, out_y, mid_x, mid_y) begin
        case(current_state)
            3'b000: begin//开始
                exp_x <= x[30:23];
                exp_y <= y[30:23];
                mant_x <= {1'b0, 1'b1, x[22:0]};
                mant_y <= {1'b0, 1'b1, y[22:0]};
                //以下为对齐用到的变量
                mid_y<={24'b0,1'b1};
                mid_x<={24'b0,1'b1};
                move_tot <= 8'b0;
                out_x <= 25'b0;
                out_y <= 25'b0;
                lastjudge <= 2'b00;
                if((exp_x == 8'd255 && mant_x[22:0] != 0) || (exp_y == 8'd255 && mant_y[22:0] != 0))begin//NaN
                    overflow <= 2'b11;
                    next_state <= 3'b101;
                    sign_z <= 1'b1;
                    exp_z <= 8'd255;
                    mant_result <= 23'b11111111111111111111111;
                end
                else if((exp_x == 8'd255 && mant_x[22:0] == 0) || (exp_y == 8'd255 && mant_y[22:0] == 0))begin//无穷大
                    overflow <= 2'b11;
                    next_state <= 3'b101;
                    sign_z <= 1'b0;
                    exp_z <= 8'd255;
                    mant_result <= 23'b0;
                end
                else begin
                    overflow <= 2'b00;
                    next_state <= 3'b001;
                end
            end
            3'b001: begin//检查0
                if(exp_x == 8'b0 && mant_x[22:0] != 23'b0)begin
                    mant_x <= {1'b0, 1'b0, x[22:0]};
                end    
                if(exp_y == 8'b0 && mant_y[22:0] != 23'b0)begin
                    mant_y <= {1'b0, 1'b0, y[22:0]};
                end
                if(exp_x == 8'b0 && mant_x[22:0] == 23'b0)begin
                    next_state <= 3'b101;
                    sign_z <= y[31];
                    exp_z <= exp_y;
                    mant_result <= mant_y;
                end
                else if(exp_y == 8'b0 && mant_y[22:0] == 23'b0)begin
                    next_state <= 3'b101;
                    sign_z <= x[31];
                    exp_z <= exp_x;
                    mant_result <= mant_x;
                end
                else begin
                    next_state <= 3'b010;
                end
            end
            3'b010: begin//对齐
                /*lastjudge为2'b00表示指数相等
                             2'b01表示x的指数小于y
                             2'b10表示y的指数小于x
                */
                if(exp_x == exp_y)begin
                    if(lastjudge == 2'b00)begin
                        next_state <= 3'b011;//指数对齐，进入尾数相加阶段
                    end
                    else if(lastjudge == 2'b01)begin//下面是四舍五入（比较对象是跟着一起移位的mid）
                        if(out_x > mid_x)begin
                            mant_x <= mant_x + 1'b1;
                        end
                        else if(out_x == mid_x)begin
                            if(mant_x[0] == 1)begin
                                mant_x <= mant_x + 1'b1;
                            end
                        end
                        next_state <= 3'b011;
                    end
                    else if(lastjudge == 2'b10)begin
                        if(out_y > mid_y)begin
                            mant_y <= mant_y + 1'b1;
                        end
                        else if(out_y == mid_y)begin
                            if(mant_y[0] == 1)begin
                                mant_y <= mant_y + 1'b1;
                            end
                        end
                        next_state <= 3'b011;
                    end
                    
                end
                else begin
                    if(exp_x > exp_y)begin
                        lastjudge <= 2'b01;
                        mid_y <= {mid_y[23:0], mid_y[24]};//把1往前过渡
                        out_y[move_tot] <= mant_y[0];
                        mant_y[23:0] <= {1'b0, mant_y[23:1]};
                        move_tot <= move_tot + 1'b1;
                        exp_y <= exp_y + 1'b1;
                        if(mant_y == 24'b0)begin
                            next_state <= 3'b101;
                            sign_z <= sign_x;
                            exp_z <= exp_x;
                            mant_result <= mant_x;
                        end
                        else begin
                            next_state <= 3'b010;
                        end
                    end
                    else begin
                        lastjudge <= 2'b10;
                        mid_x <= {mid_x[23:0], mid_x[24]};
                        out_x[move_tot] <= mant_x[0];
                        mant_x[23:0] <= {1'b0, mant_x[23:1]};
                        move_tot <= move_tot + 1'b1;
                        exp_x <= exp_x + 1'b1;
                        if(mant_x == 24'b0)begin
                            next_state <= 3'b101;
                            sign_z <= sign_y;
                            exp_z <= exp_y;
                            mant_result <= mant_y;
                        end
                        else begin
                            next_state <= 3'b010;
                        end
                    end
                end
            end
            3'b011: begin//相加
                if(x[31] ^ y[31] == 1'b0)begin//同号
                    next_state <= 3'b100;
                    exp_z <= exp_x;
                    sign_z <= x[31];
                    mant_result <= mant_x + mant_y;
                end 
                else begin//反号，大减小
                    if(mant_x > mant_y)begin
                        next_state <= 3'b100;
                        exp_z <= exp_x;
                        sign_z <= x[31];
                        mant_result <= mant_x - mant_y;
                    end
                    else if(mant_x < mant_y)begin
                        next_state <= 3'b100;
                        exp_z <= exp_y;
                        sign_z <= y[31];
                        mant_result <= mant_y - mant_x;
                    end
                    else if(mant_x == mant_y)begin
                        next_state <= 3'b101;
                        exp_z <= exp_x;
                        mant_result <= 23'b0;
                    end
                end
            end
            3'b100: begin//标准化
                if(mant_result[24] == 1'b1)begin
                    if(mant_result[0] == 1)begin
                        mant_result <= mant_result + 1'b1;
                        mant_result[0] <= 0;
                        next_state <= 3'b100;
                    end
                    else begin
                        mant_result <= {1'b0, mant_result[24:1]};
                        exp_z <= exp_z + 1'b1;
                        next_state <= 3'b101;
                    end
                end 
                else begin//mant_result不可能为0，因为只有可能是两个相减，而相减相同已经被讨论过
                    if(mant_result[23] == 1'b0 && exp_z >= 1)begin
                        mant_result <= {mant_result[23:1], 1'b0};
                        exp_z <= exp_z - 1'b1;
                        next_state <= 3'b100;
                    end 
                    else begin
                        next_state <= 3'b101;
                    end
                end
            end
            3'b101: begin//结束，确定overflow状态
                z <= {sign_z, exp_z[7:0], mant_result[22:0]};
                if(overflow)begin
                    overflow <= overflow;
                end
                else if(exp_z == 8'd255)begin
                    overflow <= 2'b01;
                end
                else if(exp_z == 8'd0 && mant_result[22:0] != 23'b0)begin
                    overflow <= 2'b10;
                end
                else begin
                    overflow <= 2'b0;
                end
                next_state <= 3'b000;
            end
            default: begin
                next_state <= 3'b000;
            end
        endcase    
    end
endmodule