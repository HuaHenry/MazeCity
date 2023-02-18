`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/08 15:27:35
// Design Name: 
// Module Name: VGA
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

//����ͬ������״̬�������ض�����ɫ���
//ͨ��VGA���¡�����ˮƽ�ʹ�ֱ������ȷ�����ĸ�����
//��������"��ɫ"����ÿһ��֮����һ����"��ɫ��"����������������
//ȡ�������ź�HSYNC�������ж���ɫ�����������ƶ���0,0��
//��ʾ����С�����أ�800*525

module VGA(
    input CLK,              //ϵͳʱ��
    input [11:0] CSEL,      //��ɫr,g,bֵ
    input ARST_L,           //�����ź�
    output HSYNC,           //֡ͬ���ź�
    output VSYNC,           //��ͬ���ź�
    output reg [3:0] RED,
    output reg [3:0] GREEN,
    output reg [3:0] BLUE,
    output reg [9:0] HCOORD,    //������
    output reg [9:0] VCOORD     //������
    );

wire aclr_i;
wire Hrollover_i, Vrollover_i;  //��ת�ź�
    
assign aclr_i = ~ARST_L;    //��������ź�

reg SREG;   
reg CLKOUT; 

//��ˮƽ�ﵽ���Ҷ˻��ߴ�ֱ�������¶�ʱ�źŷ�ת��800,525��
//�첽��ת���ʿ��Ե����ٽ�ֵ
assign Hrollover_i = (HCOORD[9] & HCOORD[8] & HCOORD[5]) ? 1'b1 : 1'b0;                 //800 D = 001100100000 B
assign Vrollover_i = (VCOORD[9] & VCOORD[3] & VCOORD[2] & VCOORD[0]) ? 1'b1 : 1'b0;     //525 D = 001000001101 B


/* part1 ������� */
//HCOORD��ÿ��ʱ�����ڼ���������Ϊ0
always @(posedge CLKOUT or posedge aclr_i) begin
    if(aclr_i) begin
        HCOORD <= 10'b0000000000;   //�����ź�
    end              
    else if(Hrollover_i)
        HCOORD <= 10'b0000000000;   //����ת�ź���Ч
    else
        HCOORD <= HCOORD + 1;
end

//ÿ��Hrollover_i������������Ϊ0ʱ��HCOORD�������
always @(posedge CLKOUT or posedge aclr_i) begin
    if(aclr_i) begin
        VCOORD <= 10'b0000000000; 
    end              
    else if(Vrollover_i)
        VCOORD <= 10'b0000000000;
    else if(Hrollover_i)
        VCOORD <= VCOORD + 1;
end

assign HSYNC = ((HCOORD < 756) && (HCOORD > 658)) ? 1'b0 : 1'b1;
assign VSYNC = ((VCOORD < 495) && (VCOORD > 492)) ? 1'b0 : 1'b1;

/* part 3 ��ɫ���� */
always @(posedge CLKOUT or posedge aclr_i) begin
    if (aclr_i) begin
        RED = 4'h0;
        GREEN = 4'h0;    
        BLUE = 4'h0;
    end
    else if((HCOORD > 640) || (VCOORD > 480)) begin
        RED = 4'h0;
        GREEN = 4'h0;    
        BLUE = 4'h0;
    end
    else begin
        // rgbֵ��vgacontroller����
        RED <= CSEL[11:8];
        GREEN <= CSEL[7:4];
        BLUE <= CSEL[3:0];
    end  
end

/* part 4 ʱ�ӷ�Ƶ */
//25mhz���У����򱨴��źŸ�ʽ��Ч��

//2��Ƶ
always @(posedge CLK or posedge aclr_i) begin
    if(aclr_i) begin
        SREG <= 1'b0;
    end
    else begin
        SREG <= ~SREG;
    end
end

//4��Ƶ
always @(posedge CLK or posedge aclr_i) begin
    if(aclr_i) begin
        CLKOUT <= 1'b0;
    end
    else if(SREG) begin
        CLKOUT <= ~CLKOUT;
    end
end
endmodule

