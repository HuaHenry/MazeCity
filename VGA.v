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

//采用同步开关状态来驱动特定的颜色组合
//通过VGA电缆。创建水平和垂直坐标以确定在哪个像素
//接下来是"颜色"。在每一行之后，下一行是"有色的"。排完后进行行消隐
//取消激活信号HSYNC。所有行都着色后，坐标重新移动至0,0。
//显示屏大小（像素）800*525

module VGA(
    input CLK,              //系统时钟
    input [11:0] CSEL,      //颜色r,g,b值
    input ARST_L,           //控制信号
    output HSYNC,           //帧同步信号
    output VSYNC,           //行同步信号
    output reg [3:0] RED,
    output reg [3:0] GREEN,
    output reg [3:0] BLUE,
    output reg [9:0] HCOORD,    //横坐标
    output reg [9:0] VCOORD     //纵坐标
    );

wire aclr_i;
wire Hrollover_i, Vrollover_i;  //翻转信号
    
assign aclr_i = ~ARST_L;    //反向控制信号

reg SREG;   
reg CLKOUT; 

//当水平达到最右端或者垂直到达最下端时信号翻转（800,525）
//异步翻转，故可以到达临界值
assign Hrollover_i = (HCOORD[9] & HCOORD[8] & HCOORD[5]) ? 1'b1 : 1'b0;                 //800 D = 001100100000 B
assign Vrollover_i = (VCOORD[9] & VCOORD[3] & VCOORD[2] & VCOORD[0]) ? 1'b1 : 1'b0;     //525 D = 001000001101 B


/* part1 坐标控制 */
//HCOORD在每个时钟周期计数或重置为0
always @(posedge CLKOUT or posedge aclr_i) begin
    if(aclr_i) begin
        HCOORD <= 10'b0000000000;   //控制信号
    end              
    else if(Hrollover_i)
        HCOORD <= 10'b0000000000;   //横向翻转信号有效
    else
        HCOORD <= HCOORD + 1;
end

//每次Hrollover_i被声明或重置为0时，HCOORD都会计数
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

/* part 3 颜色绘制 */
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
        // rgb值由vgacontroller决定
        RED <= CSEL[11:8];
        GREEN <= CSEL[7:4];
        BLUE <= CSEL[3:0];
    end  
end

/* part 4 时钟分频 */
//25mhz运行（否则报错信号格式无效）

//2分频
always @(posedge CLK or posedge aclr_i) begin
    if(aclr_i) begin
        SREG <= 1'b0;
    end
    else begin
        SREG <= ~SREG;
    end
end

//4分频
always @(posedge CLK or posedge aclr_i) begin
    if(aclr_i) begin
        CLKOUT <= 1'b0;
    end
    else if(SREG) begin
        CLKOUT <= ~CLKOUT;
    end
end
endmodule

