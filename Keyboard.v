`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/08 11:29:15
// Design Name: 
// Module Name: Keyboard
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

module Keyboard(
    input CLK,//ͬ����usb�ź�
    input SDATA,//ͬ����usb����
    input ARST_L,//�����ź�
    output [3:0] HEX0,//16���Ƽ���
    output [3:0] HEX1,//16���Ƽ���
    output reg KEYUP//�����Ƿ��ȡ��������Ϣ��1Ϊ��ȡ��
    );
    
wire arst_i, rollover_i;
reg [21:0] Shift;

assign arst_i = ~ARST_L;
// ����λ�Ĵ����в�ͣȡֵ
assign HEX0[3:0] = Shift[15:12];
assign HEX1[3:0] = Shift[19:16];

// ����һ����Ҫ22��ͬ�����ʱ�����ڣ�������ſ���11������ϢΪFOXX,XXΪ���¼��ļ��룩
always @(negedge CLK or posedge arst_i) begin;
    if(arst_i)begin
        Shift <= 22'b0000000000000000000000;
    end
    else begin
        Shift <= {SDATA, Shift[21:1]}; //�����һλ����
    end
end

//�ҵ�F0�������ҵ���һ���룬����һ��1��ֵ
always @(posedge CLK) begin
    if(Shift[8:1] == 8'hF0) begin
        KEYUP <= 1'b1;
    end
    else begin
        KEYUP <= 1'b0;
    end    
end    
endmodule
