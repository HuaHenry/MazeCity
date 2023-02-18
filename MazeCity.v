`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/16 22:14:10
// Design Name: 
// Module Name: MazeCity
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

module MazeCity(
    input CLK,
    input RST,
    //VGA显示器部分
    output HSYNC,           //帧同步信号
    output VSYNC,           //行同步信号
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE,
    //键盘
    input usbCLK,               //F4
    input usbDATA,              //usb数据 B2
    output click,               //检测信号
    //mp3
    input DREQ,//数据请求
    output wire XRSET,          //硬件复位
    output wire XCS,            //低电平有效片选输兿
    output wire XDCS,           //数据片字节同步
    output wire SI,             //串行数据输入    
    output wire SCLK,           //SPI时钟
    //七段数码管
    output wire [6:0] oData
    );
    
    wire keyup;
    wire [11:0] CSEL;
    wire [9:0] HCOORD,VCOORD;
    wire [3:0] hex1,hex0;
    wire [5:0] ballX,ballY;
    wire [15:0] adjusted_vol;
    wire [3:0] vol_class;
    wire [3:0] tune;
    wire kbstrobe_i;        //去抖信号
    
    Keyboard KB(.CLK(usbCLK), .SDATA(usbDATA), .ARST_L(RST), .HEX1(hex1), .HEX0(hex0), .KEYUP(keyup));
    SwitchDB switch_DB(CLK,keyup,RST,kbstrobe_i);
    VGA vga_Display(.CLK(CLK),.CSEL(CSEL),.ARST_L(RST),.HSYNC(HSYNC),.VSYNC(VSYNC),.RED(RED),.GREEN(GREEN),.BLUE(BLUE),.HCOORD(HCOORD),.VCOORD(VCOORD));
    VGA_controller vga_control(CLK,kbstrobe_i,{hex1,hex0},HCOORD,VCOORD,RST,ballX,ballY,ballX,ballY,CSEL,click);
    VolAdjust vol_adj(CLK,hex1,hex0,keyup,vol_class,adjusted_vol,click,kbstrobe_i);
    MP3 mp3(CLK,kbstrobe_i,DREQ,XRSET,XCS,XDCS,SI,SCLK,RST,hex1,hex0,adjusted_vol,keyup,tune,click);
    display7 Display(vol_class,oData);
    
endmodule
