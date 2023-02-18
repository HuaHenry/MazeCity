`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/10 11:35:33
// Design Name: 
// Module Name: VGA_controller
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

module VGA_controller(
    input CLK,              //系统时钟
    input kbstrobe_i,       //去抖信号
    input [7:0] KBCODE,     //按下键的键值
    input [9:0] HCOORD,     //当前横坐标
    input [9:0] VCOORD,     //当前纵坐标
    input ARST_L,           //控制信号
    input [5:0] ballX,
    input [5:0] ballY,
    output reg [5:0] ballX_now,
    output reg [5:0] ballY_now,
    output reg [11:0] CSEL,  //rgb值，可任意改
    output reg click
    );
    
    wire aclr_i;
    reg [7:0] Map[0:11][0:15];      // 1=墙体，0=走道, 2=起点和终点
    reg SREG, CLKOUT;               //用于时钟分频
    wire [4:0] row,col;             //当前绘制的像素所在的区域坐标（40px单位正方形块）

    parameter x_length = 15;     //地图右端点
    parameter y_height = 11;     //地图下端点
    
    assign aclr_i = ~ARST_L;    //反向控制信号 
    assign row = (VCOORD<40?0:(VCOORD-40<40?1:(VCOORD-80<40?2:(VCOORD-120<40?3:(VCOORD-160<40?4:(VCOORD-200<40?5:(VCOORD-240<40?6:(VCOORD-280<40?7:(VCOORD-320<40?8:(VCOORD-360<40?9:(VCOORD-400<40?10:(VCOORD-440<40?11:(VCOORD-480<40?12:(VCOORD-520<40?13:(VCOORD-560<40?14:(VCOORD-600<40?15:0))))))))))))))));     //当前像素所在Map中的行坐标
    assign col = (HCOORD<40?0:(HCOORD-40<40?1:(HCOORD-80<40?2:(HCOORD-120<40?3:(HCOORD-160<40?4:(HCOORD-200<40?5:(HCOORD-240<40?6:(HCOORD-280<40?7:(HCOORD-320<40?8:(HCOORD-360<40?9:(HCOORD-400<40?10:(HCOORD-440<40?11:(HCOORD-480<40?12:(HCOORD-520<40?13:(HCOORD-560<40?14:(HCOORD-600<40?15:0))))))))))))))));     //当前像素所在Map中的列坐标
    initial begin   //迷宫地图（走道和墙体使用二位数字定位）
        Map[0][0]=2; Map[0][1]=1; Map[0][2]=0; Map[0][3]=0; Map[0][4]=0; Map[0][5]=0; Map[0][6]=0; Map[0][7]=0; 
        Map[0][8]=1; Map[0][9]=1; Map[0][10]=1; Map[0][11]=0; Map[0][12]=0; Map[0][13]=0; Map[0][14]=0; Map[0][15]=0; 
        Map[1][0]=0; Map[1][1]=0; Map[1][2]=1; Map[1][3]=1; Map[1][4]=0; Map[1][5]=1; Map[1][6]=1; Map[1][7]=0; 
        Map[1][8]=0; Map[1][9]=0; Map[1][10]=0; Map[1][11]=0; Map[1][12]=1; Map[1][13]=0; Map[1][14]=1; Map[1][15]=0; 
        Map[2][0]=1; Map[2][1]=0; Map[2][2]=0; Map[2][3]=1; Map[2][4]=0; Map[2][5]=0; Map[2][6]=0; Map[2][7]=1; 
        Map[2][8]=1; Map[2][9]=1; Map[2][10]=0; Map[2][11]=1; Map[2][12]=0; Map[2][13]=0; Map[2][14]=1; Map[2][15]=0; 
        Map[3][0]=0; Map[3][1]=0; Map[3][2]=1; Map[3][3]=0; Map[3][4]=0; Map[3][5]=1; Map[3][6]=0; Map[3][7]=0; 
        Map[3][8]=0; Map[3][9]=0; Map[3][10]=1; Map[3][11]=1; Map[3][12]=1; Map[3][13]=0; Map[3][14]=1; Map[3][15]=0; 
        Map[4][0]=1; Map[4][1]=0; Map[4][2]=1; Map[4][3]=1; Map[4][4]=1; Map[4][5]=0; Map[4][6]=1; Map[4][7]=1; 
        Map[4][8]=1; Map[4][9]=0; Map[4][10]=1; Map[4][11]=0; Map[4][12]=0; Map[4][13]=0; Map[4][14]=1; Map[4][15]=0; 
        Map[5][0]=1; Map[5][1]=0; Map[5][2]=0; Map[5][3]=0; Map[5][4]=0; Map[5][5]=0; Map[5][6]=0; Map[5][7]=0; 
        Map[5][8]=1; Map[5][9]=0; Map[5][10]=1; Map[5][11]=0; Map[5][12]=1; Map[5][13]=1; Map[5][14]=0; Map[5][15]=1; 
        Map[6][0]=1; Map[6][1]=0; Map[6][2]=1; Map[6][3]=0; Map[6][4]=1; Map[6][5]=1; Map[6][6]=0; Map[6][7]=1; 
        Map[6][8]=1; Map[6][9]=0; Map[6][10]=1; Map[6][11]=0; Map[6][12]=0; Map[6][13]=1; Map[6][14]=0; Map[6][15]=1; 
        Map[7][0]=1; Map[7][1]=0; Map[7][2]=1; Map[7][3]=1; Map[7][4]=0; Map[7][5]=1; Map[7][6]=0; Map[7][7]=1; 
        Map[7][8]=0; Map[7][9]=0; Map[7][10]=1; Map[7][11]=0; Map[7][12]=1; Map[7][13]=1; Map[7][14]=0; Map[7][15]=1; 
        Map[8][0]=0; Map[8][1]=0; Map[8][2]=0; Map[8][3]=1; Map[8][4]=0; Map[8][5]=0; Map[8][6]=0; Map[8][7]=0; 
        Map[8][8]=1; Map[8][9]=0; Map[8][10]=1; Map[8][11]=0; Map[8][12]=0; Map[8][13]=0; Map[8][14]=0; Map[8][15]=0; 
        Map[9][0]=0; Map[9][1]=1; Map[9][2]=0; Map[9][3]=1; Map[9][4]=0; Map[9][5]=1; Map[9][6]=1; Map[9][7]=1; 
        Map[9][8]=0; Map[9][9]=0; Map[9][10]=0; Map[9][11]=1; Map[9][12]=1; Map[9][13]=1; Map[9][14]=1; Map[9][15]=0; 
        Map[10][0]=1; Map[10][1]=1; Map[10][2]=0; Map[10][3]=1; Map[10][4]=0; Map[10][5]=1; Map[10][6]=0; Map[10][7]=1; 
        Map[10][8]=0; Map[10][9]=1; Map[10][10]=0; Map[10][11]=1; Map[10][12]=0; Map[10][13]=1; Map[10][14]=0; Map[10][15]=0; 
        Map[11][0]=0; Map[11][1]=0; Map[11][2]=0; Map[11][3]=1; Map[11][4]=0; Map[11][5]=0; Map[11][6]=0; Map[11][7]=0; 
        Map[11][8]=0; Map[11][9]=1; Map[11][10]=0; Map[11][11]=0; Map[11][12]=0; Map[11][13]=1; Map[11][14]=1; Map[11][15]=2;
    end
    
    //绘制迷宫地图
    //根据横纵坐标判断是否绘制墙体/走道/起点终点
    always @(posedge CLKOUT) begin
        if(VCOORD>=0&&VCOORD<=480&&HCOORD>=0&&HCOORD<=640) begin
            if(Map[row][col]==0) begin          // 走道
                if(row==ballX&&col==ballY&&((HCOORD-(2*col+1)*20)*(HCOORD-(2*col+1)*20)+(VCOORD-(2*row+1)*20)*(VCOORD-(2*row+1)*20)<13*13)) begin
                    if(VCOORD>=row*40+14&& VCOORD<=row*40+15 && HCOORD>=col*40+12 && HCOORD<=col*40+17)     //左眼
                        CSEL<=12'hFFF;
                    else if(VCOORD>=row*40+14&& VCOORD<=row*40+15 && HCOORD>=col*40+23 && HCOORD<=col*40+28)//右眼
                        CSEL<=12'hFFF;
                    else if(VCOORD>=row*40+24&& VCOORD<=row*40+25 && HCOORD>=col*40+15 && HCOORD<=col*40+25)
                        CSEL<=12'hFFF;
                    else
                        CSEL<=12'hF00;              // 小球
                end
                else CSEL<=12'h0F0;
            end
            else if(Map[row][col]==1) begin     // 墙体
                // 花纹效果
                if(((VCOORD+HCOORD)/8)%2==0) CSEL<=12'b1110_1011_0000;
                else CSEL<=12'b1110_0111_0000;
            end
            else if(Map[row][col]==2) begin     // 起点终点
                if(row==ballX&&col==ballY&&((HCOORD-(2*col+1)*20)*(HCOORD-(2*col+1)*20)+(VCOORD-(2*row+1)*20)*(VCOORD-(2*row+1)*20)<13*13)) begin
                    if(VCOORD>=row*40+14&& VCOORD<=row*40+15 && HCOORD>=col*40+12 && HCOORD<=col*40+17)     //左眼
                        CSEL<=12'hFFF;
                    else if(VCOORD>=row*40+14&& VCOORD<=row*40+15 && HCOORD>=col*40+23 && HCOORD<=col*40+28)//右眼
                        CSEL<=12'hFFF;
                    else if(VCOORD>=row*40+24&& VCOORD<=row*40+25 && HCOORD>=col*40+15 && HCOORD<=col*40+25)
                        CSEL<=12'hFFF;
                    else
                        CSEL<=12'hF00;              // 小球
                end
                else CSEL<=12'b0000_1100_1110;
            end
        end
    end
    
    //根据获取到的键码判断移动方向
    always @(posedge CLKOUT or posedge aclr_i) begin
        if(aclr_i) begin
            ballX_now <= 0;
            ballY_now <= 0;
        end 
        else if (kbstrobe_i) begin
                case(KBCODE)
                    // 根据输入的键码确定位置的改变
                    8'h1C : begin //左
                    //4'b1000: begin
                        if(ballY>=1) begin
                            if(Map[ballX][ballY-1]==0||Map[ballX][ballY-1]==2) begin
                                ballY_now<=ballY-1; ballX_now<=ballX;
                            end
                            else begin
                                //click<=1;
                                ballX_now=ballX; ballY_now=ballY;
                            end
                        end
                        else begin
                            ballX_now=ballX; ballY_now=ballY;
                        end
                        if(ballX==y_height && ballY==x_length) begin
                            ballX_now<=0; ballY_now<=0;
                        end
                    end                       
                    8'h23 : begin //右
                    //4'b0100: begin
                        if(ballY<=x_length-1) begin
                            if(Map[ballX][ballY+1]==0||Map[ballX][ballY+1]==2)begin
                            ballY_now<=ballY+1;  ballX_now<=ballX;
                            end
                            else begin
                                ballX_now=ballX; ballY_now=ballY;
                            end
                        end
                        else begin
                            ballX_now=ballX; ballY_now=ballY;
                        end
                        if(ballX==y_height && ballY==x_length) begin
                            ballX_now<=0; ballY_now<=0;
                        end
                    end
                    8'h1B : begin //下
                    //4'b0010: begin
                        if(ballX<=y_height-1) begin
                            if(Map[ballX+1][ballY]==0||Map[ballX+1][ballY]==2)begin
                            ballX_now=ballX+1; ballY_now=ballY; 
                            end
                            else begin
                                ballX_now=ballX; ballY_now=ballY;
                            end
                        end
                        else begin
                            ballX_now=ballX; ballY_now=ballY;
                        end
                        if(ballX==y_height && ballY==x_length) begin
                            ballX_now<=0; ballY_now<=0;
                        end
                    end
                    8'h1D : begin //上
                    //4'b0001: begin
                        if(ballX>=1) begin
                            if(Map[ballX-1][ballY]==0||Map[ballX-1][ballY]==2)begin
                            ballX_now=ballX-1; ballY_now=ballY;
                            end
                            else begin
                                ballX_now=ballX; ballY_now=ballY;
                            end
                        end
                        else begin
                            ballX_now=ballX; ballY_now=ballY;
                        end
                        if(ballX==y_height && ballY==x_length) begin
                            ballX_now=0; ballY_now=0;
                        end
                    end
                    default: begin
                        ballX_now=ballX; ballY_now=ballY;
                    end
                endcase
        end
    end
    
    //时钟分频
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
