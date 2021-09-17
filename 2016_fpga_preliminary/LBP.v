
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [7:0] 	lbp_data;
output  	finish;
//====================================================================
reg  [13:0] gray_addr;
reg         gray_req;
reg  [13:0] lbp_addr;
reg  	    lbp_valid;
reg  [7:0] 	lbp_data;
reg  	    finish;

reg [2:0] state;
reg [6:0] x_count, y_count;
reg [7:0] gc, i;
reg [7:0] gray_mem1 [127:0];
reg [7:0] gray_mem2 [127:0];
reg [7:0] gray_mem3 [127:0];

parameter readmem1 = 3'b000, readmem2 = 3'b001, readmem3 = 3'b010, readmemX = 3'b011;
parameter writemem = 3'b100, ready = 3'b101;
//====================================================================
always@(posedge clk or posedge reset)
begin
    if(reset)
    begin
        gray_req = 0; lbp_valid = 0; finish = 0;
        state = ready;
    end
    else begin
        case(state) //synopsys full_case
            ready:begin
                if(gray_ready) begin
                    gray_addr = 0; gray_req = 1; state = readmem1;
                    x_count = 0; y_count = 0;
                end
            end
            readmem1:begin
                gray_req = 1;
                gray_mem1[y_count] = gray_data;
                gray_addr = gray_addr + 1;
                y_count = y_count + 1;
                if(y_count == 0) begin
                    x_count = x_count + 1;
                    state = readmem2;
                end else state = readmem1;
            end
            readmem2:begin
                gray_req = 1;
                gray_mem2[y_count] = gray_data;
                gray_addr = gray_addr + 1;
                y_count = y_count + 1;
                if(y_count == 0) begin
                    x_count = x_count + 1;
                    state = readmem3;
                end else state = readmem2;
            end
            readmem3:begin
                gray_req = 1;
                gray_mem3[y_count] = gray_data;
                gray_addr = gray_addr + 1;
                y_count = y_count + 1;
                if(y_count == 0) begin
                    gray_req = 0;
                    lbp_valid = 1;
                    x_count = 0;
                    state = writemem;
                end else state = readmem3;
            end
            readmemX:begin
                gray_mem3[y_count] = gray_data;
                gray_addr = gray_addr + 1;
                y_count = y_count + 1;
                if(y_count == 0) begin
                    gray_req = 0;
                    lbp_valid = 1;
                    state = writemem;
                end else state = readmemX;
            end
            writemem:begin
                lbp_addr = x_count * 128 + y_count;
                if(x_count == 0 || x_count == 127 || y_count == 0 || y_count == 127)
                begin
                    lbp_data = 0;
                end
                else begin
                    gc[0] = (gray_mem1[y_count - 1] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[1] = (gray_mem1[y_count] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[2] = (gray_mem1[y_count + 1] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[3] = (gray_mem2[y_count - 1] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[4] = (gray_mem2[y_count + 1] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[5] = (gray_mem3[y_count - 1] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[6] = (gray_mem3[y_count] >= gray_mem2[y_count]) ? 1 : 0;
                    gc[7] = (gray_mem3[y_count + 1] >= gray_mem2[y_count]) ? 1 : 0;
                    lbp_data = gc;
                end
                y_count = y_count + 1;
                if(y_count == 0) x_count = x_count + 1;
                else x_count = x_count;
                if(x_count >= 2 && x_count <= 127 && y_count == 0) begin
                    lbp_valid = 0;
                    for(i = 0; i <= 127; i = i +1) begin
                        gray_mem1[i] = gray_mem2[i];
                    end
                    for(i = 0; i <= 127; i = i +1) begin
                        gray_mem2[i] = gray_mem3[i];
                    end
                    gray_req = 1;
                    lbp_valid = 0;
                    state = readmemX;
                end else if(x_count == 127 && y_count == 127) begin
                    finish = 1;
                    gray_req = 0;
                    lbp_valid = 0;
                end else state = writemem;
            end
            default: begin end
        endcase
    end
end
//====================================================================
endmodule
