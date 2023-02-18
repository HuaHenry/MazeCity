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

//ͨ�����̰�����������
module VolAdjust(
    input clk,
    input [3:0] hex1,
    input [3:0] hex0,
    input keyup,
    output reg [3:0] vol_class=9,  //�����ȼ� ��ʼ�������
    output reg [15:0]vol=16'h0000,   //��������
    output reg click,
    input kbstrobe_i
    );
    wire [15:0]adjusted_vol;        //�����������
    
    wire clk_1M; //��Ƶ1MHz
    Divider #(.N(100)) CLKDIV1(clk,1,clk_1M);
    
    assign adjusted_vol=vol;        //ʵʱ�洢ԭ������С
    integer clk_cnt=0;              //ʱ�����ڼ�����������������ʱ
    always @(posedge clk_1M) 
    begin
        if(clk_cnt==200000) begin
            clk_cnt<=0;
            if(!keyup) begin
                //click=1;
                case({hex1,hex0})
                8'h78:    //����F11
                begin
                    vol<=(vol==16'h0000)?16'h0000:(vol-16'h197f);   // �����Ŵ�volֵ��С��
                end
                8'h07:    //����F1
                begin
                    vol<=(vol==16'hfef6)?16'hfefe:(vol+16'h197f);   //������С��volֵ���
                end
                endcase
            end
        end
        else 
            clk_cnt<=clk_cnt+1;
    end
    //����vol_class�����ȼ�
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
