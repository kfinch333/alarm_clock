//physical validation
module alarm_clock_pv(input CLK,SW5,SW4,SW3,SW2,SW1,SW0,KEY1,KEY0, output logic [6:0] SEC_LSB,SEC_MSB,MIN_LSB, MIN_MSB,HR_LSB,HR_MSB, output logic LED7,LED5,LED4,LED3,LED2,LED1,LED0);
	logic  clkout, alrm;
	logic [7:0] sec, min, hrs, min_alrm, hrs_alrm, secmsb, seclsb, minmsb, minlsb, hrsmsb, hrslsb;

	pmcntr #(25) p1 (CLK, SW0, 25'd6250000, count, clkout);
	fdivby2_ #(25) d1 (clkout, reset, clk);
	alarm_clock c1 (clk, SW0, SW1, SW2, SW3, SW4, SW5, ~KEY0|SW0, ~KEY1, sec, min, hrs, min_alrm, hrs_alrm, alrm);
	ASCII27Seg disp0 (seclsb, SEC_LSB);
	ASCII27Seg disp1 (secmsb, SEC_MSB);
	ASCII27Seg disp2 (minlsb, MIN_LSB);
	ASCII27Seg disp3 (minmsb, MIN_MSB);
	ASCII27Seg disp4 (hrslsb, HR_LSB);
	ASCII27Seg disp5 (hrsmsb, HR_MSB);

	function [7:0] msb;
		input [7:0] A;
		integer i;
		msb=0;
		for (i=0;i<=9;i=i+1)
			if (A>(msb*8'd10+8'd9))
				msb = msb + 8'd1;
	endfunction

	always_ff @ (*) begin
		if (SW2) begin
			secmsb = 8'd12;
			seclsb = 8'd42;
			minmsb = msb(min_alrm);
			minlsb = min_alrm - minmsb*10;
			hrsmsb = msb(hrs_alrm);
			hrslsb = hrs_alrm - hrsmsb*10;
		end
		else begin
			secmsb = msb(sec);
			seclsb = sec - secmsb*10;
			minmsb = msb(min);
			minlsb = min - minmsb*10;
			hrsmsb = msb(hrs);
			hrslsb = hrs - hrsmsb*10;
		end
		LED5 = SW5;
		LED4 = SW4;
		LED3 = SW3;
		LED2 = SW2;
		LED1 = SW1;
		LED0 = SW0;
	end

		always_ff @ (posedge clkout)
			if (alrm)
				LED7 = ~LED7;
			else
				LED7 = 1'b0;
endmodule

//Ascii Test
module testdisp();
	logic [7:0] value0, value1, value2, value3, value4, value5;
	wire [6:0] Hex1, Hex2, Hex4, Hex5;
	ASCII27Seg test1 (value1, Hex1);
	ASCII27Seg test2 (value2, Hex2);
	ASCII27Seg test4 (value4, Hex4);
	ASCII27Seg test5 (value5, Hex5);
	function [7:0] msb;
		input [7:0] A;
		integer i;
		msb=0;
		for (i=0;i<=9;i=i+1)
			if (A>(msb*8'd10+8'd9))
				msb = msb + 8'd1;
	endfunction

	initial begin
		value0 = 8'd59; #10;
		value1 = msb(value0); value2 = value0 - value1*10; #10;
		value3 = 8'd42; #10;
		value4 = msb(value3); value5 = value3 - value4*10; #10;
	end
endmodule

//msb function test
module msb_test(input [7:0] H, output reg [7:0] Hh, H1);
	function [7:0] msb;
		input [7:0] A;
		integer i;
		msb=0;
		for (i=0;i<=9;i=i+1)
			if (A>(msb*8'd10+8'd9))
				msb = msb + 8'd1;
	endfunction

	always @ (*) begin
		Hh = msb(H);
		H1 = H - Hh*10;
	end
endmodule

//ASCII
module ASCII27Seg (input [7:0] AsciiCode, output logic [6:0] HexSeg);
	always @ (*) begin
		HexSeg = 8'd0;
		$display ("AsciiCode %d", AsciiCode);
		case (AsciiCode)
//			0
			8'h0 : HexSeg[6] = 1;
//			1
			8'h1 : begin
				HexSeg[0] = 1; HexSeg[3] = 1; HexSeg[4] = 1; HexSeg[5] = 1; HexSeg[6] = 1;
			end
//			2
			8'h2 : begin
				HexSeg[2] = 1; HexSeg[5] = 1;
			end
//			3
			8'h3 : begin
				HexSeg[4] = 1; HexSeg[5] = 1;
			end
//			4
			8'h4 : begin
				HexSeg[0] = 1; HexSeg[3] = 1; HexSeg[4] = 1;
			end
//			5
			8'h5 : begin
				HexSeg[1] = 1; HexSeg[4] = 1;
			end
//			6
			8'h6 : HexSeg[1] = 1;
//			7
			8'h7 : begin
				HexSeg[3] = 1; HexSeg[4] = 1; HexSeg[5] = 1; HexSeg[6] = 1;
			end
//			8
			8'h8 : HexSeg = 8'd0;
//			9
			8'h9 : HexSeg[4] = 1;
			default : HexSeg = 8'b11111111;
		endcase
	end
endmodule		

//alarm clock
module alarm_clock_tb();
	logic clk, reset, time_set, alarm_set, sethrs1min0, run_clock, activatealarm, alarmreset, runset, alrm;
	logic [7:0] sec, min, hrs, min_alrm, hrs_alrm;
	alarm_clock c1 (clk, reset, time_set, alarm_set, sethrs1min0, run_clock, activatealarm, alarmreset, runset, sec, min, hrs, min_alrm, hrs_alrm, alrm);

	initial begin
		clk = 0; reset = 1; alarmreset = 1; time_set =0; alarm_set = 0; sethrs1min0 = 0; run_clock = 0; activatealarm = 0; runset = 0; #5;
		reset = 0; alarmreset = 0; alarm_set = 1; runset = 1; clk = 1; #5;
		repeat (29) begin
			clk = 0; #5;
			clk = 1; #5;
		end
		clk = 0; sethrs1min0 = 1; #5;
		repeat (5) begin
			clk = 1; #5;
			clk = 0; #5;
		end
		alarm_set = 0; time_set = 1; clk = 1; #5;
		repeat (4) begin
			clk = 0; #5;
			clk = 1; #5;
		end
		sethrs1min0 = 0; clk = 0; #5;
		repeat (29) begin
			clk = 1; #5;
			clk = 0; #5;
		end
		time_set = 0; runset = 1; activatealarm = 1; run_clock = 1; clk = 1; #5;
		repeat (120) begin
			clk = 0; #5;
			clk = 1; #5;
		end
		alarmreset = 1; clk = 0; #5;
		reset = 1; #5;
	end
endmodule

//alarm clock
module alarm_clock(input CLK_2Hz, reset, time_set, alarm_set, sethrs1min0, run_clock, activatealarm, alarmreset, runset, output logic [7:0] sec, min, hrs, min_alrm, hrs_alrm, output logic alrm);
	localparam fiftynine=8'd59, twentythree=8'd23;
	logic minutes_, hours_, minutes, hours, days, runsec, runmin, runhrs, sec_;
	logic aminutes_, ahours_, aminutes, ahours, adays, arunmin, arunhrs;
//clock
	clocktime #(8) SecClock (sec_, runsec, reset, fiftynine, sec, minutes);
	clocktime #(8) MinClock (minutes_, runmin, reset, fiftynine, min, hours);
	clocktime #(8) HrClock (hours_, runhrs, reset, twentythree, hrs, days);
//alarm
	clocktime #(8) AlarmMin (aminutes_, arunmin, alarmreset, fiftynine, min_alrm, ahours);
	clocktime #(8) AlarmHr (ahours_, arunhrs, alarmreset, twentythree, hrs_alrm, adays);

	fdivby2_ #(25) d1 (CLK_2Hz, reset, sec_);

	always_ff @ (*) begin
		if (run_clock) begin
			minutes_ = minutes;
			hours_ = hours;
			runsec = 1'b1; runmin = 1'b1; runhrs = 1'b1;
		end
		else if (runset) begin
			if (time_set) begin
				if (sethrs1min0) begin
					hours_ = CLK_2Hz;
					minutes_ = 1'b0;
					runsec = 1'b0; runmin = 1'b0; runhrs = 1'b1;
				end
				else begin
					minutes_ = CLK_2Hz;
					hours_ = 1'b0;
					runsec = 1'b0; runmin = 1'b1; runhrs = 1'b0;
				end
			end
			else if (alarm_set) begin
				if (sethrs1min0) begin
					ahours_ = CLK_2Hz;
					aminutes_ = 1'b0;
					arunmin = 1'b0; arunhrs = 1'b1;
				end
				else begin
					aminutes_ = CLK_2Hz;
					ahours_ = 1'b0;
					arunmin = 1'b1; arunhrs = 1'b0;
				end
			end
		end
		else begin
			minutes_ = minutes;
			hours_ = hours;
			runsec = 1'b0; runmin = 1'b0; runhrs = 1'b0;
		end
	end

	assign alrm = (activatealarm && ((hrs == hrs_alrm) && (min == min_alrm)));
endmodule

//clocktime
module clocktime #(parameter size=8) (input clk, freerun, reset, input [size-1:0] Maxval, output logic [size-1:0] Count, output logic clkout);
	always_ff @ (posedge clk or posedge reset) begin
		if (reset) begin
			Count <= {size{1'b0}};
			clkout <= 1'b0;
		end
		else
			if (freerun)
				if (Count < Maxval) begin
					Count <= Count + {{(size-1){1'b0}},1'b1};
				end
				else begin
					Count <= {size{1'b0}};
					clkout <= ~clkout;
				end
	end
endmodule

// divides clk freq by 2 giving clkout
module fdivby2_ #(parameter size=25) (input clk, reset, output logic clkout);
	always_ff @ (posedge clk or posedge reset) begin
		if (reset)
			clkout <= 1'b0;
		else
			clkout <= ~clkout;
	end
endmodule

// parameterized counter, frequency divider
module pmcntr #(parameter siz=25) (input clk, reset, input [siz-1:0] count_max, output logic [siz-1:0] count, output logic clkout);
	always_ff @ (posedge clk or posedge reset)
		if (reset) begin
			count <= {siz{1'b0}};
			clkout <= 1'b0;
		end
		else if (count<count_max)
			count <= count + {{(siz-1){1'b0}},1'b1};
		else begin
			count <= {siz{1'b0}};
			clkout <= ~clkout;
		end
endmodule
