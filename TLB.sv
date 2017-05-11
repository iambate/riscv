//`define TLBDEBUG
`define ENABLE_TLB
module Trans_Lookaside_Buff
#(
	BUS_DATA_WIDTH = 64,
  	BUS_TAG_WIDTH = 13,
	STARTING_INDEX=12,
	INVALIDATE_SIGNAL=3,
	SET_WAIT=1,
	UNSET_WAIT=0,
	WAIT_FOR_FLUSH_COMPLETION=1,
	SET1=0,
	DIRTY='b001,
	FLUSHING_NOT_NEEDED=2,
	SET2=1,
	FLUSHING_NEEDED=3,
	WAITING_FOR_MEM_READ=1,
	CACHE_HIT=2,
	VALID='b100,
	SIZE=64,
	CACHE_MISS=3,
	LRU='b010,
	READ_SIGNAL=1,
	WRITE_SIGNAL=2,
	DIRTY_BIT=0,
	LRU_BIT=1,
	VALID_BIT=2
)
(	
	input clk,//F
	input reset,//F
	input [63:0] v_addr,//F
	
	output [SIZE-1:0] p_addr,//F
	output [1:0] addr_available,//F
	
	output bus_reqcyc,
  	output bus_respack,
  	output [BUS_DATA_WIDTH-1:0] bus_req,
  	output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  	input  bus_respcyc,
  	input  bus_reqack,
  	input  [BUS_DATA_WIDTH-1:0] bus_resp,
  	input  [BUS_TAG_WIDTH-1:0] bus_resptag,
	input rd_signal,
	input va_pa_abtr_grant,
	output va_pa_abtr_reqcyc,
	output va_pa_bus_busy,
	input [63:0] ptbr
);
	logic [1:0] ff_addr_available;
	logic [SIZE-1:0] ff_p_addr;
	logic [SIZE-1:0] Data[2][512];
	logic [SIZE-1:0] Tag[2][512];
	logic [2:0] State[2][512];
	logic [63:0] tag;
	logic [8:0] index;
	logic [5:0] block_offset_index;
	logic [1:0] RSet;
        logic [1:0] ff_RSet;
	logic Wait_fr_mem_read;
	logic [SIZE-1:0] data;
	logic va_pa_enable;
	logic va_pa_ready;

	va_to_pa va_to_pa1   (.clk(clk),
            .reset(reset),
            .ptbr(ptbr),
            .enable(va_pa_enable),

            .abtr_grant(va_pa_abtr_grant),
            .abtr_reqcyc(va_pa_abtr_reqcyc),
            .main_bus_respcyc(bus_respcyc),
            .main_bus_respack(bus_respack),
            .main_bus_resp(bus_resp),
            .main_bus_req(bus_req),
            .main_bus_reqcyc(bus_reqcyc),
	    .main_bus_resptag(bus_resptag),
            .main_bus_reqtag(bus_reqtag),
	    .bus_busy(va_pa_bus_busy),
            .virt_addr(v_addr),//direct input in case of miss
            .phy_addr(data),//64 bytes data to put in tlb
            .ready(va_pa_ready)
                       );

	always_comb begin
`ifdef ENABLE_TLB
        	if(rd_signal) begin
			assign index = v_addr[STARTING_INDEX+8:STARTING_INDEX];
			assign tag = v_addr[63:STARTING_INDEX+9];
			if(Wait_fr_mem_read == SET_WAIT) begin
				assign RSet=ff_RSet;
				assign p_addr=ff_p_addr;
				assign addr_available = WAITING_FOR_MEM_READ;
			end
			else if((Tag[SET1][index] == tag) && State[SET1][index]&VALID) begin
				assign RSet=SET1;
				assign p_addr = (Data[RSet][index][63:10] << 12)+v_addr[11:0];
				assign addr_available = CACHE_HIT;
			end
			else if((Tag[SET2][index] == tag) && State[SET2][index]&VALID) begin
				assign RSet=SET2;
				assign p_addr = (Data[RSet][index][63:10] <<12)+v_addr[11:0];
				assign addr_available = CACHE_HIT;
			end
			else begin//pick least recently used set to be replaced
				assign addr_available = CACHE_MISS;
				if(Tag[SET1][index]&LRU) begin
					assign RSet = SET1;
					assign p_addr=0;
				end
				else begin
					assign RSet=SET2;
					assign p_addr = 0;
				end
			end
		end
		else begin
			assign addr_available = CACHE_MISS;
			assign RSet=0;
			assign p_addr=0;
		end
`else
		assign p_addr=v_addr;
		if(rd_signal) begin
			assign addr_available=CACHE_HIT;
		end else begin
			assign addr_available=CACHE_MISS;
		end
`endif
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			Wait_fr_mem_read <= UNSET_WAIT;
		end
		else begin
`ifdef ENABLE_TLB
			if(rd_signal) begin
`ifdef TLBDEBUG
				$display("TLB: new cycle\n");
`endif
				if(addr_available == CACHE_HIT) begin//not a miss
`ifdef TLBDEBUG
					$display("TLB :cache hit, returning v addr %d p addr %d",v_addr,p_addr);
					$display("TLB :cache hit, index %d",index);
					$display("TLB :cache hit, tag %d",tag);
`endif
					Wait_fr_mem_read <= UNSET_WAIT;
					State[RSet][index][LRU_BIT]<= 0;
					State[~RSet][index][LRU_BIT]<= 1;
				end
				else if(addr_available == CACHE_MISS) begin//miss
`ifdef TLBDEBUG
						$display("TLB : cache miss for virt addr %d",v_addr);
`endif
						va_pa_enable <= 1;
						Wait_fr_mem_read <= SET_WAIT;
						ff_RSet<=RSet;
						ff_p_addr<=p_addr;
				end
				else if(addr_available == WAITING_FOR_MEM_READ) begin
					if(va_pa_ready) begin
`ifdef TLBDEBUG
						$display("TLB : data arrived for block which contains virt addr %d",v_addr);
						$display("TLB : data arrived %x",data);
`endif
						Wait_fr_mem_read <= UNSET_WAIT;
						Data[RSet][index] <= data;
						Tag[RSet][index] <= tag;
						State[RSet][index][VALID_BIT] <= 1;
						State[RSet][index][LRU_BIT] <= 0;
						State[~RSet][index][LRU_BIT] <= 1;
					end
					else begin
`ifdef TLBDEBUGEXTRA
						$display("TLB :Waiting for va to pa to fetch block at %d",v_addr);
`endif
						va_pa_enable <= 0;
						ff_RSet<=RSet;
                                                ff_p_addr<=p_addr;
						Wait_fr_mem_read <= SET_WAIT;
					end
				end
			end
			else begin
			end
`endif
		end
	end
endmodule
