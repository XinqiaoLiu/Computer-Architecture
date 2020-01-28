module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk, pm_error, sm_error, poison_inst;
logic pmem_resp;
logic [255:0] pmem_rdata; 
logic [31:0] pmem_addr;
logic pmem_read, pmem_write;
logic [255:0] pmem_wdata;


initial
begin
    clk = 0;
end

/* Clock generator */
always #5 clk = ~clk;


mp3 dut
(
	.*
);

physical_memory physical_memory
(
	.clk,
   .read(pmem_read),
   .write(pmem_write),
   .address(pmem_addr),
   .wdata(pmem_wdata),
   .resp(pmem_resp),
   .error(pm_error),
   .rdata(pmem_rdata)
);
/*
shadow_memory sm
(
	.clk,
	.imem_valid(dut.cpu_datapath.i_resp),
	.imem_addr(dut.cpu_datapath.i_addr),
	.imem_rdata(dut.cpu_datapath.i_rdata),
	.dmem_valid(dut.cpu_datapath.d_resp),
	.dmem_addr(dut.cpu_datapath.d_addr),
	.dmem_rdata(dut.cpu_datapath.d_rdata),
	.write(dut.cpu_datapath.d_write),
	.wmask(dut.cpu_datapath.mem_byte_enable),
	.wdata(dut.cpu_datapath.d_wdata),
	.error(sm_error),
	.poison_inst
);
*/

/*
magic_memory_dp memory
(
	 .clk,
    .read_a(pmem_read),
    .address_a(pmem_addr),
    .resp_a(pmem_resp),
    .rdata_a(pmem_rdata[31:0]),

    .read_b(),
    .write(),
    .wmask(),
    .address_b(),
    .wdata(),
    .resp_b(),
    .rdata_b()
);
*/
endmodule: mp3_tb
