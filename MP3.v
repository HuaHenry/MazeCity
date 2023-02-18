`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/17 16:18:46
// Design Name: 
// Module Name: MP3
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

module MP3(
	input CLK,         //ϵͳʱ��
	input kbstrobe_i,  //ȥ���ź�
	input DREQ,        //��������
	output reg XRSET,  //Ӳ����λ
	output reg XCS,    //�͵�ƽ��ЧƬѡ���
	output reg XDCS,   //����Ƭ�ֽ�ͬ��
	output reg SI,     //������������	
	output reg SCLK,   //SPIʱ��
	input init,        //��ʼ��
	input [3:0] hex1,  //16���Ƽ����λ
    input [3:0] hex0,  //16���Ƽ����λ
    input [15:0] adjusted_vol,  //ʵʱ����
    input keyup,
    output reg [3:0] tune=0,     //��ǰ����ָ���Ӧ��ʾ������
    output reg click=0
);
    parameter  CMD_START=0;     //��ʼдָ��
    parameter  WRITE_CMD=1;     //��һ��ָ��ȫ��д��
    parameter  DATA_START=2;    //��ʼд����
    parameter  WRITE_DATA=3;    //��һ������ȫ��д��
    parameter  DELAY=4;         //��ʱ  
    parameter VOL_CMD_START=5;  //�������
    parameter SEND_VOL_CMD=6;   //CMD����

	reg [31:0] volcmd;
    reg [20:0]addr;
    wire CLK_1M; //��Ƶ1MHz
    Divider #(.N(100)) CLKDIV1(CLK,1,CLK_1M);
    
    reg  [15:0] Data;
    wire [15:0] D_do;
    wire [15:0] D_re;
    wire [15:0] D_mi;
    wire [15:0] D_fa;
    
    reg [3:0] pretune=0;  
    reg [15:0] _Data;
    
    //ѡ����ʾ��
    blk_mem_gen_0 your_instance_name0(.clka(CLK),.addra(addr),.douta(D_do));
    blk_mem_gen_1 your_instance_name1(.clka(CLK),.addra(addr),.douta(D_re));
    blk_mem_gen_2 your_instance_name2(.clka(CLK),.addra(addr),.douta(D_mi));
    blk_mem_gen_3 your_instance_name3(.clka(CLK),.addra(addr),.douta(D_fa));
    
    integer tune_delay=0;       //��ʱ50000��λ
	always @(posedge CLK_1M)
	begin
	   if(tune_delay==0) 
	   begin
            if(keyup)   
            begin
               tune_delay<=50000;
               case({hex1,hex0})    //���ݲ�ͬ�ļ��뷢����ͬ����
               8'h1C:
               begin
                   tune<=4'b0001;   // A->����
                   //click=1;
               end
               8'h1B:
               begin
                    tune<=4'b0010;  // S->����
               end
               8'h23:
               begin
                    tune<=4'b0011;  // D->����
               end
               8'h1D:
               begin
                    tune<=4'b0100;  // W->����
               end
               default:
               begin
                    tune<=0;
               end
               endcase
             end
       end
       else 
       begin
            tune_delay<=tune_delay-1;   //��ʱ��ȡָ��
       end

	   case(tune)
	   4'b0001:
	   begin
	       Data<=D_do;
//	       click=1;
	   end
	   4'b0010:
	   begin
	       Data<=D_re;
	   end
	   4'b0011:
	   begin
	       Data<=D_mi;
	   end
	   4'b0100:
	   begin
	       Data<=D_fa;
	   end
	   default:
	   begin
	       Data<=D_do;
	   end
	   endcase
	end
	
	reg [63:0] cmd={32'h02000804,32'h020B0000};
	//00�ǿ���ģʽ 0B������ 08 ����ģʽ 04 �����λ��ÿ�׸�֮�������λ��
    //��ʼдָ��
    integer status=CMD_START;
    integer cnt=0;      //λ����
    integer cmd_cnt=0;  //�������
	
    always @(posedge CLK_1M) 
	begin
	    pretune<=tune; //�洢tune������ͬ��������һ��tune
        if(~init||pretune!=tune||!keyup)    
        //�����������λ����ܳ��ִ��󣩻ص���ʼ״̬
	    begin
            XCS<=1;
            XDCS<=1;
            XRSET<=0;
            cmd_cnt<=0;
            status<=DELAY;  // �տ���ʱ��delay,�ȴ�DREQ
            SCLK<=0;
            cnt<=0;
            addr<=0;
        end
        else if((tune<4'b0101&&addr<10000))
	    begin
	     
            case(status)
            CMD_START: // �ȴ���������
		    begin
                SCLK<=0;//SPIʱ���½������룬�����ض�ȡ�������½���
                if(cmd_cnt>=2) // ��ǰ2��Ԥ�����mode ���� ��������Ϻ� ��ʼ��������
                begin
					status<=DATA_START; //click=1;
                end
                else if(DREQ) // DREQ��Чʱ �������� si���Խ���32��bit���ź�
                begin  
//                    click=1;
                    XCS<=0;//XCS���ͱ�ʾ����ָ��
                    status<=WRITE_CMD;  // ��ʼ����ָ��
                    SI<=cmd[63];
                    cmd<={cmd[62:0],cmd[63]}; //��λ������
                    cnt<=1;
                end
            end
            WRITE_CMD://д��ָ��
            begin
                if(DREQ) 
                begin
                    if(SCLK) 
                    begin
                        if(cnt>=32)     //λ����
                        begin
                            XCS<=1;  // ȡ����λ
                            cnt<=0;
                            cmd_cnt<=cmd_cnt+1; //����������cmdָ��
                            status<=CMD_START;  // ��ת������ִ��
                            
                        end
                        else 
                        begin
                            SCLK<=0;
                            SI<=cmd[63]; // ������ʮ��λдָ�дָ��0200����MODE�Ĵ����� 0804��MODE��ʮ��λ ����ֻ���ĵ�11��2λ ������λ��
                            cmd<={cmd[62:0],cmd[63]}; //ѭ������
                            cnt<=cnt+1; 
                        end
                    end
                    SCLK<=~SCLK;
                end
            end
            DATA_START://д������
            begin
                if(adjusted_vol[15:0]!=cmd[15:0])  // cmd[47:32] ��洢���ǵ�ǰ���� ��ʼֵΪ0000
                begin//��������
                    click=1;
                    cnt<=0;
                    volcmd<={16'h020B,adjusted_vol}; // ������������ 0B�Ĵ���������������  �üĴ����洢���ݱ�ʾ������С
                    status<=VOL_CMD_START;			// ת����������
                end
                else if(DREQ) // �ȴ��������� ֮��ÿ������32ʹ ��DREQ�´α�߽������� vs1003B���Զ����ղ�����
                begin   //����Ҫ����������ֱ��ת����Ƶ���ݴ���
//                    click=1;
                    XDCS<=0;
                    SCLK<=0;
                    SI<=Data[15];
                    _Data<={Data[14:0],Data[15]};
                    cnt<=1;    
                    status<=WRITE_DATA;  // �����ź�
                end
                cmd[15:0]<=adjusted_vol; // ����cmd�д洢������
            end
            
            WRITE_DATA:
            begin  
                if(SCLK)
                begin
                    if(cnt>=16)
                    begin
                        
                        XDCS<=1;
                        addr<=addr+1; // ����ʮ��λ���ַ����1λ
                        status<=DATA_START;
                    end
                    else 
                    begin  // ѭ������ ����ʮ��λ
                        SCLK<=0;
                        cnt<=cnt+1;
                        _Data<={_Data[14:0],_Data[15]};
                        SI<=_Data[15];
                    end
                end
                SCLK<=~SCLK;
            end
          
            DELAY:
            begin
                if(cnt<50000)   // �ȴ�100��ʱ���ܖc
                    cnt<=cnt+1;
                else 
                begin
                    cnt<=0;
                    status<=CMD_START; 
                    XRSET<=1;
                end
            end
            
            VOL_CMD_START:
            begin
                if(DREQ) 
                begin  // �ȴ�DREQ�ź�
                    XCS<=0; 
                    status<=SEND_VOL_CMD;   // ����������������
                    SI<=volcmd[31];
                    volcmd<={volcmd[30:0],volcmd[31]}; 
                    cnt<=1;
                end
            end
            SEND_VOL_CMD:
            begin
                if(DREQ) 
                begin
                     if(SCLK) 
                     begin
                        if(cnt<32)  //ѭ����ֵ
                        begin
                            SI<=volcmd[31];
                            volcmd<={volcmd[30:0],volcmd[31]}; 
                            cnt<=cnt+1; 
                        end
                        else 
                        begin 
                            XCS<=1; // ��������
                            cnt<=0;
                            status<=DATA_START; // ����֮ǰ�����
                        end
                    end
                    SCLK<=~SCLK;
                end
            end
		default:;
        endcase
    end
end
endmodule
