`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2023 01:21:20 PM
// Design Name: 
// Module Name: lfsr_div
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


module lfsr_div(clk, div);
	input clk;
	output div;

	reg tog;
	reg [26:0] lfsr;
	reg [4:0] comp_p1;
	reg comp_p2;
	wire fb;

	assign div = tog;
	assign fb = (lfsr[26] ^ ~(lfsr[4] ^ ~(lfsr[1] ^ ~lfsr[0])));
	always @(posedge clk) begin
		lfsr <= {lfsr[25:0], fb};
		comp_p1[0] <=| lfsr[5:0];
		comp_p1[1] <=| lfsr[11:6];
		comp_p1[2] <=| lfsr[17:12];
		comp_p1[3] <=| lfsr[23:18];
		comp_p1[4] <=| lfsr[26:24];
		comp_p2 <=| comp_p1;
		if (comp_p2 == 0) begin
			$display("tog");
			tog <= ~tog;
		end
	end
endmodule

