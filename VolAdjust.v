`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/17 16:14:54
// Design Name: 
// Module Name: VolAdjust
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//通过键盘按键调节音量
module VolAdjust(
    input clk,
    input [3:0] hex1,
    input [3:0] hex0,
    input keyup,
    output reg [3:0] vol_class=9,  //音量等级 初始最大音量
    output reg [15:0]vol=16'h0000,   //音量数额
    output reg click,
    input kbstrobe_i
    );
    wire [15:0]adjusted_vol;        //调整后的音量
    
    wire clk_1M; //分频1MHz
    Divider #(.N(100)) CLKDIV1(clk,1,clk_1M);
    
    assign adjusted_vol=vol;        //实时存储原音量大小
    integer clk_cnt=0;              //时钟周期计数器，用于设置延时
    always @(posedge clk_1M) 
    begin
        if(clk_cnt==200000) begin
            clk_cnt<=0;
            if(!keyup) begin
                //click=1;
                case({hex1,hex0})
                8'h78:    //键盘F11
                begin
                    vol<=(vol==16'h0000)?16'h0000:(vol-16'h197f);   // 音量放大（vol值变小）
                end
                8'h07:    //键盘F1
                begin
                    vol<=(vol==16'hfef6)?16'hfefe:(vol+16'h197f);   //音量减小（vol值变大）
                end
                endcase
            end
        end
        else 
            clk_cnt<=clk_cnt+1;
    end
    //更新vol_class音量等级
    always @(posedge clk_1M)
    begin
        case(vol)
        16'he577:
        begin
            vol_class<=0;
        end
        16'hcbf8:
        begin
            vol_class<=1;
        end
        16'hb279:
        begin
            vol_class<=2;
        end
        16'h98fa:
        begin
            vol_class<=3;
        end
        16'h7f7b:
        begin
            vol_class<=4;
        end
        16'h65fc:
        begin
            vol_class<=5;
        end
        16'h4c7d:
        begin
            vol_class<=6;
        end
        16'h32fe:
        begin
            vol_class<=7;
        end
        16'h197f:
        begin
            vol_class<=8;
        end
        16'h0000:
        begin
            vol_class<=9;    
        end
        default:
        begin
            vol_class<=0;
        end
        endcase 
    end
endmodule 
