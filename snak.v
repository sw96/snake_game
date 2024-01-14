module snak(CLOCK_50, PS2_CLK, PS2_DAT, SW, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N, VGA_CLK);
	input CLOCK_50;
	input PS2_CLK, PS2_DAT;
	input [1:0] SW;
	
	output [9:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS;
	output VGA_SYNC_N, VGA_BLANK_N;
	output VGA_CLK; 	
	
	parameter MAX_LEN = 128;
	
	wire CLK25, updateCLK;
	wire [9:0] px, py, in_r, in_g, in_b;
	wire reset;		
	wire r, g, b;
	wire Edge;
	wire Head;
	wire EdgeOrBody;
	wire Rat;
	wire [2:0] dir;
	wire [9:0] RandomX;
	wire [8:0] RandomY;
	
	reg [9:0] SnakeX[MAX_LEN - 1:0];
	reg [8:0] SnakeY[MAX_LEN - 1:0];
	reg [9:0] SnakePrevX;
	reg [8:0] SnakePrevY;
	reg [6:0] SnakeLen;
	reg [9:0] RatX;
	reg [8:0] RatY;
	reg GameOver, EatRat, EatRatFlag, SnakeBody, SnakeBodyFlag, SnakeBodyCollision;
	
	integer i;
	
	initial begin
		
		EatRat = 1'b0;
		GameOver = 1'b0;
		
		SnakeLen = 1;
		
		SnakeX[0] = 150;
		SnakeY[0] = 150;
		
		RatX = 200;
		RatY = 200;
	
		for(i = 1; i < MAX_LEN; i = i + 1) begin
			SnakeX[i] <= 0;
			SnakeY[i] <= 0;
		end
	end
	
	assign reset = SW[0];
	
	assign Edge = (px >= 0 && px < 11) || (px >= 630 && px < 641) || (py >= 0 && py < 11) || (py >= 470 && py < 481);
	assign Head = (px > SnakeX[0] && px < SnakeX[0] + 10 && py > SnakeY[0] && py < SnakeY[0] + 10);
	assign Rat = (px > RatX && px < RatX + 10 && py > RatY && py < RatY + 10);
	assign EdgeOrBody = Edge;
	
	assign r = (~GameOver && (Edge || Rat)) || GameOver;
	assign g = (~GameOver && (Edge || SnakeBody));
	assign b = (~GameOver && Head);
	
	assign in_r = {8{r}};
	assign in_g = {8{g}};
	assign in_b = {8{b}};
	
	always @(negedge updateCLK) begin
		if(GameOver == 0) begin			
			
		end
	end
		
	always @(posedge updateCLK) begin
		if(GameOver == 0) begin	

			SnakePrevX = SnakeX[0];
			SnakePrevY = SnakeY[0];
			case(dir)
				3'b000 : SnakeY[0] = SnakeY[0] - 10;
				3'b001 : SnakeX[0] = SnakeX[0] - 10;
				3'b010 : SnakeY[0] = SnakeY[0] + 10;
				3'b011 : SnakeX[0] = SnakeX[0] + 10;	
				default : SnakeX[0] = SnakeX[0];
			endcase
			
			for(i = MAX_LEN; i >= 1; i = i - 1) begin
					if(i == 1) begin
						SnakeX[i] = SnakePrevX;
						SnakeY[i] = SnakePrevY;
					end
					else if(i < SnakeLen) begin
						SnakeX[i] = SnakeX[i - 1];
						SnakeY[i] = SnakeY[i - 1];	
					end
				end
			
			if(EatRat) begin	
				EatRatFlag = 1'b1;
				
				RatX = RandomX;
				RatY = RandomY;
			
				SnakeLen = SnakeLen + 1;				
			end
			else begin			
				EatRatFlag = 1'b0;								
			end
		end
		else if(GameOver) begin	
			
			SnakeLen = 1;
			
			EatRatFlag = 1'b0;
			
			SnakeBodyCollision = 1'b0;
			
			SnakeX[0] = 150;
			SnakeY[0] = 150;
			
			RatX = RandomX;
			RatY = RandomY;
		
			for(i = 1; i < MAX_LEN; i = i + 1) begin
				SnakeX[i] = 0;
				SnakeY[i] = 0;
			end			
		end		
	end
	
	always @(posedge VGA_CLK or posedge reset) begin
		if(reset) begin
			GameOver <= 1'b0;
		end
		else begin
			if(EdgeOrBody && Head)
				GameOver <= 1'b1;	
				
			if(EatRatFlag)
				EatRat <= 1'b0;
			else if(Rat && Head)
				EatRat <= 1'b1;
		end
	end
	
	always @(posedge VGA_CLK) begin		
		SnakeBodyFlag = 1'b0;
		
		for(i = 1; i < SnakeLen; i = i + 1) begin
			if(SnakeBodyFlag == 0) begin
				SnakeBody = (px > SnakeX[i] && px < SnakeX[i] + 10 && py > SnakeY[i] && py < SnakeY[i] + 10);
				SnakeBodyFlag = SnakeBody;
			end
		end		
	end
	
	ReduceToCLK25 u1 (CLOCK_50, reset, CLK25);
	VgaController u2 (CLK25, reset, in_r, in_g, in_b, px, py, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N, VGA_CLK);
	Ps2Controller u3 (PS2_CLK, reset, PS2_DAT, dir);
	ReduceToUpdate u4 (CLOCK_50, updateCLK);
	RandomXY u5 (CLOCK_50, updateCLK, RandomX, RandomY);
	
endmodule

module ReduceToCLK25(CLK50, reset, CLK25);
	input CLK50, reset;
	
	output reg CLK25;

	always @(posedge CLK50 or posedge reset) begin
		if(reset) CLK25 <= 0;
		else CLK25 <= ~CLK25;
	end
endmodule


module VgaController(CLK25, reset, in_r, in_g, in_b, px, py, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N, VGA_CLK);
	input CLK25;
	input reset;
	input [9:0] in_r, in_g, in_b;
	
	output reg [9:0] px, py;
	output [9:0] VGA_R, VGA_G, VGA_B;
	output reg VGA_HS, VGA_VS;
	output VGA_SYNC_N, VGA_BLANK_N;
	output VGA_CLK;
	
	reg video_on;
	reg [9:0] hCnt, vCnt;
	
	always @(posedge CLK25 or posedge reset) begin
		if(reset) hCnt <= 0;
		else begin
			if(hCnt == 799) hCnt <= 0;
			else hCnt <= hCnt + 1;
		end
	end
	
	always @(posedge CLK25) begin
		if((hCnt >= 659) && (hCnt <= 755)) VGA_HS <= 0;
		else VGA_HS <= 1;
	end
	
	always @(posedge CLK25 or posedge reset) begin
		if(reset)
			vCnt <= 0;
		else if(hCnt == 799) begin
			if(vCnt == 524) vCnt <= 0;
			else vCnt <= vCnt + 1;
		end
	end
	
	always @(posedge CLK25) begin
		if((vCnt >= 493) && (vCnt <= 494)) VGA_VS <= 0;
		else VGA_VS <= 1;
	end
	
	always @(posedge CLK25) begin
		video_on <= (hCnt <= 639) && (vCnt <= 479);
		px <= hCnt;
		py <= vCnt;
	end
	
	assign VGA_CLK = ~CLK25;
	assign VGA_BLANK_N = VGA_HS & VGA_VS;
	assign VGA_SYNC_N = 1'b0;
	
	assign VGA_R = video_on ? in_r : 10'h000;
	assign VGA_G = video_on ? in_g : 10'h000;
	assign VGA_B = video_on ? in_b : 10'h000;	

endmodule


module Ps2Controller(PS2_CLK, reset, PS2_DAT, dir);
	input PS2_CLK, reset, PS2_DAT;
	
	output reg [2:0] dir;
	
	initial begin
		dir = 3'b111;
	end
	
	reg [10:0] completedData, prevData;
	reg [7:0] KeyCode;
	reg [2:0] direction;
	
	integer Cnt = 0;
	
	always @(negedge PS2_CLK) begin
		completedData[Cnt] = PS2_DAT;
		Cnt = Cnt + 1;
		
		if(Cnt == 11) begin
			if(prevData == 8'hF0)
				KeyCode <= completedData[8:1];
			
			prevData = completedData[8:1];
			Cnt = 0;
		end		
	end
	
	always @(KeyCode) begin			
		case(KeyCode)
			8'h1D : direction <= 3'b000; // up
			8'h1C : direction <= 3'b001; // left
			8'h1B : direction <= 3'b010; // down
			8'h23 : direction <= 3'b011; // right
			default : direction <= 3'b111;
		endcase
	end
	
	always @(posedge PS2_CLK or posedge reset) begin
		if(reset)
			dir <= 3'b111;
		else
			dir <= direction;
	end

endmodule


module ReduceToUpdate(CLK, updateCLK);
	input CLK;
	
	output reg updateCLK;
	
	reg [21:0] Cnt;
	
	always @(posedge CLK) begin
		Cnt <= Cnt + 1;
		
		if(Cnt == 2000000) begin
			updateCLK <= ~updateCLK;
			Cnt <= 0;
		end
	end

endmodule


module RandomXY(CLK, CLK2, X, Y);
	input CLK, CLK2;
	
	output reg [9:0] X;
	output reg [8:0] Y;
	
	integer Cnt = 0, Cnt2 = 0;
	
	always @(posedge CLK) begin
		Cnt = Cnt + 1;
		
		X = Cnt % 600 + 20;
	end
	
	always @(posedge CLK2) begin
		Cnt2 = Cnt2 + 1;
		
		Y = Cnt2 % 430 + 20;
	end

endmodule

