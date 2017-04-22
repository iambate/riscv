`define CACHEDEBUGXTRA
module Set_Associative_Cache
#(
	BUS_DATA_WIDTH = 64,
  	BUS_TAG_WIDTH = 13,
	STARTING_INDEX=0,
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
	SIZE=32,
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
	input [63:0] addr,//F
	input [1:0] rd_wr_evict_flag,//F
	output [1:0] Cache_block_invalidation,
	output [1:0] canWrite,
	output [SIZE-1:0] read_data,//F
	output [1:0] data_available,//F
	input [SIZE-1:0] write_data,
	output bus_reqcyc,
  	output bus_respack,
  	output [BUS_DATA_WIDTH-1:0] bus_req,
  	output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  	input  bus_respcyc,
  	input  bus_reqack,
  	input  [BUS_DATA_WIDTH-1:0] bus_resp,
  	input  [BUS_TAG_WIDTH-1:0] bus_resptag,
	
	input addr_data_abtr_grant,
	output addr_data_abtr_reqcyc,
	input store_data_abtr_grant,
	output store_data_abtr_reqcyc,
	output store_data_bus_busy,
	output addr_data_bus_busy
);
	logic [1:0] ff_data_available;
	logic [SIZE-1:0] ff_read_data;
	logic [1:0] flush_before_replacement;
	logic [1:0] ff_flush_before_replacement;
	logic [1:0] ff_Cache_block_invalidation;
	logic [SIZE-1:0] Data[2][512][64/(SIZE/8)];
	logic [48:0] Tag[2][512];
	logic [2:0] State[2][512];
	logic [48:0] tag;
	logic [8:0] index;
	logic [5:0] block_offset;
	logic [63:0] starting_addr_of_block;
	logic Wait_fr_mem_write;
	logic [1:0] CSet;
	logic [1:0] ff_CSet;
	logic [1:0] RSet;
        logic [1:0] ff_RSet;
	logic [1:0] WSet;
        logic [1:0] ff_WSet;
	logic Wait_fr_mem_read;
	logic [1:0] ff_canWrite;
	int i;
	logic [4095:0] flush_data;
	logic [511:0] data;
	//TODO: store_data_enable,store_data_at_addr,phy_addr,
	//store_data_ready,addr_data_ready,data,flush_data,addr_data_enable,
	//CHECK:~ sign works?
	addr_to_data addr_data(
            .clk(clk),
            .reset(reset),

            .enable(addr_data_enable),

            .abtr_grant(addr_data_abtr_grant),
            .abtr_reqcyc(addr_data_abtr_reqcyc),
            .main_bus_respcyc(bus_respcyc),
            .main_bus_respack(bus_respack),
            .main_bus_resp(bus_resp),
            .main_bus_req(bus_req),
            .main_bus_reqcyc(bus_reqcyc),
            .main_bus_reqtag(bus_reqtag),

            .addr(phy_addr),
            .data(data),
            .ready(addr_data_ready)
                       );

	store_data store_data_0(
            .clk(clk),
            .reset(reset),

            .enable(store_data_enable),

            .abtr_grant(store_data_abtr_grant),
            .abtr_reqcyc(store_data_abtr_reqcyc),
            .main_bus_respcyc(bus_respcyc),
            .main_bus_respack(bus_respack),
            .main_bus_resp(bus_resp),
            .main_bus_req(bus_req),
            .main_bus_reqcyc(bus_reqcyc),
            .main_bus_reqack(bus_reqack),
            .main_bus_reqtag(bus_reqtag),

            .addr(store_data_at_addr),
            .data(flush_data),
            .ready(store_data_ready)
                       );

	always_comb begin
		assign index = addr[STARTING_INDEX+14:STARTING_INDEX+6];
		assign tag = addr[63:STARTING_INDEX+15];
		assign block_offset = addr[STARTING_INDEX+5:STARTING_INDEX];
		assign starting_addr_of_block = addr[63:6]<<6;
		if(rd_wr_evict_flag == INVALIDATE_SIGNAL) begin
			if(Wait_fr_mem_write==SET_WAIT) begin
				assign CSet=ff_CSet;
                                assign Cache_block_invalidation=ff_Cache_block_invalidation;
				assign flush_before_replacement=WAIT_FOR_FLUSH_COMPLETION;
			end
			else if((Tag[SET1][index]==tag) && (State[SET1][index]&DIRTY==0)) begin
				assign CSet=SET1;
				assign Cache_block_invalidation =1;
				assign flush_before_replacement =FLUSHING_NOT_NEEDED;
			end
			else if ((Tag[SET1][index]==tag) && (State[SET1][index]&DIRTY==0)) begin
				assign CSet=SET2;
				assign Cache_block_invalidation =1;
				assign flush_before_replacement =FLUSHING_NOT_NEEDED;
                        end
			else begin//flushing needed
				if(Tag[SET1][index]==tag) begin
					assign CSet=SET1;
					assign Cache_block_invalidation =0;
					assign flush_before_replacement =FLUSHING_NEEDED;
				end
				else if (Tag[SET2][index]==tag) begin
					assign CSet=SET2;
                                        assign Cache_block_invalidation =0;
					assign flush_before_replacement =FLUSHING_NEEDED;
                                end
				else begin//TODO: not sure what to do in this case,throw error?
					assign Cache_block_invalidation =1;
				end
			end
		end
		else if(Wait_fr_mem_write==SET_WAIT) begin
			
			assign WSet=ff_WSet;
                        assign canWrite=ff_canWrite;
                        assign RSet=ff_RSet;
                        assign read_data=ff_read_data;
                        assign data_available = ff_data_available;
			assign flush_before_replacement = WAIT_FOR_FLUSH_COMPLETION;
		end
		else if(Wait_fr_mem_read == SET_WAIT) begin
			
			assign WSet=ff_WSet;
			assign RSet=ff_RSet;
			assign read_data=ff_read_data;
			assign flush_before_replacement = ff_flush_before_replacement;
			assign canWrite=WAITING_FOR_MEM_READ;	
			assign data_available = WAITING_FOR_MEM_READ;
		end
		else if((Tag[SET1][index] == tag) && State[SET1][index]&VALID) begin
`ifdef CACHEDEBUGXTRA
			$display("CACHE addr %d", addr);
			$display("CACHE index %d", index);
			$display("CACHE Tag1 %b", Tag[SET1][index]);
			$display("CACHE Tag1 %b", Tag[SET2][index]);
			$display("CACHE State1 %b",State[SET1][index]);
			$display("CACHE State2 %b",State[SET2][index]);
`endif
			assign WSet=SET1;//write
			assign canWrite=CACHE_HIT;//write
			assign RSet=SET1;
			assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
			assign data_available = CACHE_HIT;
		end
		else if((Tag[SET2][index] == tag) && State[SET2][index]&VALID) begin
`ifdef CACHEDEBUGXTRA
			$display("CACHE addr %d", addr);
			$display("CACHE index %d", index);
			$display("CACHE Tag1 %b", Tag[SET1][index]);
			$display("CACHE Tag1 %b", Tag[SET2][index]);
			$display("CACHE State1 %b",State[SET1][index]);
			$display("CACHE State2 %b",State[SET2][index]);
`endif
			assign WSet=SET2;//write
			assign canWrite=CACHE_HIT;//write
                        assign RSet=SET2;
			assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
			assign data_available = CACHE_HIT;
                end
		else begin//pick least recently used set to be replaced
`ifdef CACHEDEBUGXTRA
			$display("CACHE addr %d", addr);
			$display("CACHE index %d", index);
			$display("CACHE Tag1 %b", Tag[SET1][index]);
			$display("CACHE Tag1 %b", Tag[SET2][index]);
			$display("CACHE State1 %b",State[SET1][index]);
			$display("CACHE State2 %b",State[SET2][index]);
`endif
			assign canWrite=CACHE_MISS;//write
			assign data_available = CACHE_MISS;
			if(Tag[SET1][index]&LRU) begin
				assign WSet= SET1;//write
				assign RSet = SET1;
				assign read_data = 0;
				if(State[RSet][index]&DIRTY == 1) begin
					//use for write
					assign flush_before_replacement = FLUSHING_NEEDED;//flush before rewriting
				end
				else begin
					//use for write
					assign flush_before_replacement = FLUSHING_NOT_NEEDED;//no need to flush
				end
			end
			else begin
				assign WSet=1;
				assign RSet = 1;
                                assign read_data = 0;
				if(State[RSet][index]&DIRTY == 1) begin
                                        assign flush_before_replacement = FLUSHING_NEEDED;
                                end
                                else begin
                                        assign flush_before_replacement = FLUSHING_NOT_NEEDED;
                                end
			end
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			Wait_fr_mem_read <= UNSET_WAIT;
			Wait_fr_mem_write <= UNSET_WAIT;
//			for(i=0;i<512;i++) begin
			//	State[SET1][i][VALID_BIT]<=0;
			//	State[SET2][i][VALID_BIT]<=0;
//				$display("valid bit %d %d\n",State[SET1][i][VALID_BIT],State[SET2][i][VALID_BIT]);
//			end
			//TODO:init valid bit
		end
		else begin
			$display("new cycle\n");
			$display("addr ready", addr_data_ready);
			if(rd_wr_evict_flag == READ_SIGNAL) begin //read
			//	$display("READ SIGNAL\n");
				if(data_available == CACHE_HIT) begin//not a miss
					$display("cache hit\n");
					State[RSet][index][LRU_BIT]<= 0;
					State[~RSet][index][LRU_BIT]<= 1;
				end
				else if(data_available == CACHE_MISS) begin//miss
					if(flush_before_replacement == FLUSHING_NEEDED) begin
						//TODO:change variables
						
                                                ff_RSet<=RSet;
                                                ff_WSet<=WSet;
                                                ff_read_data<=read_data;
                                                ff_canWrite<=canWrite;
                                                ff_data_available<=data_available;
						ff_flush_before_replacement <=flush_before_replacement;
						
						store_data_enable <= 1;
						//TODO:move to always_comb
						store_data_at_addr <= ((Tag[RSet][index]<<15)+(index<<6));
						if(SIZE == 32) begin
                                                        flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[RSet][index][0][31:0];
                                                        flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[RSet][index][1];
                                                        flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[RSet][index][2];
                                                        flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[RSet][index][3];
                                                        flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[RSet][index][4];
                                                        flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[RSet][index][5];
                                                        flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[RSet][index][6];
                                                        flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[RSet][index][7];
                                                        flush_data[(SIZE*8)+(SIZE-1):(SIZE*8)] <= Data[RSet][index][8];
                                                        flush_data[(SIZE*9)+(SIZE-1):(SIZE*9)] <= Data[RSet][index][9];
                                                        flush_data[(SIZE*10)+(SIZE-1):(SIZE*10)] <= Data[RSet][index][10];
                                                        flush_data[(SIZE*11)+(SIZE-1):(SIZE*11)] <= Data[RSet][index][11];
                                                        flush_data[(SIZE*12)+(SIZE-1):(SIZE*12)] <= Data[RSet][index][12];
                                                        flush_data[(SIZE*13)+(SIZE-1):(SIZE*13)] <= Data[RSet][index][13];
                                                        flush_data[(SIZE*14)+(SIZE-1):(SIZE*14)] <= Data[RSet][index][14];
                                                        flush_data[(SIZE*15)+(SIZE-1):(SIZE*15)] <= Data[RSet][index][15];
                                                end
                                                else begin
                                                        flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[RSet][index][0];
                                                        flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[RSet][index][1];
                                                        flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[RSet][index][2];
                                                        flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[RSet][index][3];
                                                        flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[RSet][index][4];
                                                        flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[RSet][index][5];
                                                        flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[RSet][index][6];
                                                        flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[RSet][index][7];
                                                end
						Wait_fr_mem_write<=SET_WAIT;
						Wait_fr_mem_read <=UNSET_WAIT;
					end
					else if(flush_before_replacement == FLUSHING_NOT_NEEDED) begin
						$display("FLUSHING_NOT_NEEDED Requesting %d:\n ", starting_addr_of_block);
						addr_data_enable <= 1;
						phy_addr <= starting_addr_of_block;
						Wait_fr_mem_read <= SET_WAIT;
						Wait_fr_mem_write <=UNSET_WAIT;
	
						ff_RSet<=RSet;
						ff_WSet<=WSet;
						ff_read_data<=read_data;
						ff_flush_before_replacement<=flush_before_replacement;
					end
					else if(flush_before_replacement ==  WAIT_FOR_FLUSH_COMPLETION) begin
						ff_WSet <= WSet;
                                                ff_canWrite <= canWrite;
                                                ff_RSet <=RSet;
                                                ff_read_data <=read_data;
                                                ff_data_available<=data_available;
						if(store_data_ready) begin//TODO:we are done writing to mem
							Wait_fr_mem_write <=UNSET_WAIT;
							Wait_fr_mem_read<=UNSET_WAIT;
							State[RSet][index][DIRTY_BIT]<=0;
						end
						else begin
							Wait_fr_mem_write <=SET_WAIT;
							Wait_fr_mem_read<=UNSET_WAIT;
							store_data_enable <= 0;
						end
					end
				end
				else if(data_available == WAITING_FOR_MEM_READ) begin
					if(addr_data_ready) begin
						$display("GSAHA data is ready %d %d\n",Wait_fr_mem_read,Wait_fr_mem_write);
						$display("GSAHA %x", phy_addr);
						$display("GSAHA %x %x\n",addr, Tag[RSet][index]);
						$display("data arrived %x\n",data);
						Wait_fr_mem_read <= UNSET_WAIT;
						Wait_fr_mem_write<=UNSET_WAIT;
						if(SIZE == 32) begin
							Data[RSet][index][0][31:0] <= data[(SIZE*0)+(SIZE-1):(SIZE*0)];
                                                        Data[RSet][index][1][31:0] <= data[(SIZE*1)+(SIZE-1):(SIZE*1)];
                                                        Data[RSet][index][2][31:0] <= data[(SIZE*2)+(SIZE-1):(SIZE*2)];
                                                        Data[RSet][index][3][31:0] <= data[(SIZE*3)+(SIZE-1):(SIZE*3)];
                                                        Data[RSet][index][4] <= data[(SIZE*4)+(SIZE-1):(SIZE*4)];
                                                        Data[RSet][index][5] <= data[(SIZE*5)+(SIZE-1):(SIZE*5)];
                                                        Data[RSet][index][6] <= data[(SIZE*6)+(SIZE-1):(SIZE*6)];
                                                        Data[RSet][index][7] <= data[(SIZE*7)+(SIZE-1):(SIZE*7)];
							Data[RSet][index][8] <= data[(SIZE*8)+(SIZE-1):(SIZE*8)];
                                                        Data[RSet][index][9] <= data[(SIZE*9)+(SIZE-1):(SIZE*9)];
                                                        Data[RSet][index][10] <= data[(SIZE*10)+(SIZE-1):(SIZE*10)];
                                                        Data[RSet][index][11] <= data[(SIZE*11)+(SIZE-1):(SIZE*11)];
                                                        Data[RSet][index][12] <= data[(SIZE*12)+(SIZE-1):(SIZE*12)];
                                                        Data[RSet][index][13] <= data[(SIZE*13)+(SIZE-1):(SIZE*13)];
                                                        Data[RSet][index][14] <= data[(SIZE*14)+(SIZE-1):(SIZE*14)];
                                                        Data[RSet][index][15] <= data[(SIZE*15)+(SIZE-1):(SIZE*15)];
						end
						else begin
							Data[RSet][index][0] <= data[(SIZE*0)+(SIZE-1):(SIZE*0)];
							Data[RSet][index][1] <= data[(SIZE*1)+(SIZE-1):(SIZE*1)];
							Data[RSet][index][2] <= data[(SIZE*2)+(SIZE-1):(SIZE*2)];
							Data[RSet][index][3] <= data[(SIZE*3)+(SIZE-1):(SIZE*3)];
							Data[RSet][index][4] <= data[(SIZE*4)+(SIZE-1):(SIZE*4)];
							Data[RSet][index][5] <= data[(SIZE*5)+(SIZE-1):(SIZE*5)];
							Data[RSet][index][6] <= data[(SIZE*6)+(SIZE-1):(SIZE*6)];
							Data[RSet][index][7] <= data[(SIZE*7)+(SIZE-1):(SIZE*7)];
						end	
						Tag[RSet][index] <= tag;
						State[RSet][index][VALID_BIT] <= 1;
						State[RSet][index][DIRTY_BIT] <= 0;
						State[RSet][index][LRU_BIT] <= 0;
						State[~RSet][index][LRU_BIT] <= 1;
					end
					else begin
						addr_data_enable <= 0;
`ifdef CACHEDEBUGXTRA
						$display("setting wait 1\n");
`endif
						Wait_fr_mem_read <= SET_WAIT;
						Wait_fr_mem_write<=UNSET_WAIT;
					end
					//wait, request has been sent, check if data is available, if its
					// fill in this cycle and change Tag, State arrays 
				end
			end
	
//----------------------------------------------------------------------------------------------------------------
			//write signal
			else if(rd_wr_evict_flag == WRITE_SIGNAL) begin//write
				if(canWrite==CACHE_HIT)begin
					Data[WSet][index][block_offset/(SIZE/8)] <= write_data;
					State[WSet][index][LRU_BIT]<= 0;
					State[~WSet][index][LRU_BIT]<=1;
					State[WSet][index][DIRTY_BIT]<=1;
				end
				else if(canWrite ==CACHE_MISS) begin
					if(flush_before_replacement==FLUSHING_NEEDED) begin
						 ff_RSet<=RSet;
                                                ff_WSet<=WSet;
                                                ff_read_data<=read_data;
                                                ff_canWrite<=canWrite;
                                                ff_data_available<=data_available;
                                                ff_flush_before_replacement <=flush_before_replacement;

                                                store_data_enable <= 1;
                                                //TODO:move to always_comb
                                                store_data_at_addr <= ((Tag[RSet][index]<<15)+(index<<6));
                                                if(SIZE == 32) begin
                                                        flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[WSet][index][0];
                                                        flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[WSet][index][1];
                                                        flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[WSet][index][2];
                                                        flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[WSet][index][3];
                                                        flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[WSet][index][4];
                                                        flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[WSet][index][5];
                                                        flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[WSet][index][6];
                                                        flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[WSet][index][7];
                                                        flush_data[(SIZE*8)+(SIZE-1):(SIZE*8)] <= Data[WSet][index][8];
                                                        flush_data[(SIZE*9)+(SIZE-1):(SIZE*9)] <= Data[WSet][index][9];
                                                        flush_data[(SIZE*10)+(SIZE-1):(SIZE*10)] <= Data[WSet][index][10];
                                                        flush_data[(SIZE*11)+(SIZE-1):(SIZE*11)] <= Data[WSet][index][11];
                                                        flush_data[(SIZE*12)+(SIZE-1):(SIZE*12)] <= Data[WSet][index][12];
                                                        flush_data[(SIZE*13)+(SIZE-1):(SIZE*13)] <= Data[WSet][index][13];
                                                        flush_data[(SIZE*14)+(SIZE-1):(SIZE*14)] <= Data[WSet][index][14];
                                                        flush_data[(SIZE*15)+(SIZE-1):(SIZE*15)] <= Data[WSet][index][15];
                                                end
                                                else begin
                                                        flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[WSet][index][0];
                                                        flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[WSet][index][1];
                                                        flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[WSet][index][2];
                                                        flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[WSet][index][3];
                                                        flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[WSet][index][4];
                                                        flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[WSet][index][5];
                                                        flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[WSet][index][6];
                                                        flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[WSet][index][7];
						end
						Wait_fr_mem_write<=SET_WAIT;
                                                Wait_fr_mem_read <=UNSET_WAIT;
					end
					else if(flush_before_replacement == FLUSHING_NOT_NEEDED) begin
						addr_data_enable <= 1;
                                                phy_addr <= starting_addr_of_block;
`ifdef CACHEDEBUGXTRA
						$display("setting wait 2\n");
`endif
                                                Wait_fr_mem_read <= SET_WAIT;
                                                Wait_fr_mem_write <=UNSET_WAIT;

                                                ff_RSet<=RSet;
                                                ff_WSet<=WSet;
                                                ff_read_data<=read_data;
                                                ff_canWrite<=canWrite;
                                                ff_flush_before_replacement<=flush_before_replacement;
					end
					else if(flush_before_replacement == WAIT_FOR_FLUSH_COMPLETION) begin
						ff_WSet <= WSet;
                                                ff_canWrite <= canWrite;
                                                ff_RSet <=RSet;
                                                ff_read_data <=read_data;
                                                ff_data_available<=data_available;
						if(store_data_ready) begin//TODO:we are done writing to mem
							Wait_fr_mem_write <=UNSET_WAIT;
                                                        Wait_fr_mem_read<=UNSET_WAIT;
                                                        State[RSet][index][DIRTY_BIT]<=0;
                                                end
                                                else begin
							Wait_fr_mem_write <=SET_WAIT;
                                                        Wait_fr_mem_read<=UNSET_WAIT;
                                                        store_data_enable <= 0;
                                                end
					end
				end
				else if(canWrite==WAITING_FOR_MEM_READ) begin
                                        if(addr_data_ready) begin
						Wait_fr_mem_read <= UNSET_WAIT;
                                                Wait_fr_mem_write<=UNSET_WAIT;
                                                if(SIZE == 32) begin
                                                        Data[RSet][index][0] <= data[(SIZE*0)+(SIZE-1):(SIZE*0)];
                                                        Data[RSet][index][1] <= data[(SIZE*1)+(SIZE-1):(SIZE*1)];
                                                        Data[RSet][index][2] <= data[(SIZE*2)+(SIZE-1):(SIZE*2)];
                                                        Data[RSet][index][3] <= data[(SIZE*3)+(SIZE-1):(SIZE*3)];
                                                        Data[RSet][index][4] <= data[(SIZE*4)+(SIZE-1):(SIZE*4)];
                                                        Data[RSet][index][5] <= data[(SIZE*5)+(SIZE-1):(SIZE*5)];
                                                        Data[RSet][index][6] <= data[(SIZE*6)+(SIZE-1):(SIZE*6)];
                                                        Data[RSet][index][7] <= data[(SIZE*7)+(SIZE-1):(SIZE*7)];
                                                        Data[RSet][index][8] <= data[(SIZE*8)+(SIZE-1):(SIZE*8)];
                                                        Data[RSet][index][9] <= data[(SIZE*9)+(SIZE-1):(SIZE*9)];
                                                        Data[RSet][index][10] <= data[(SIZE*10)+(SIZE-1):(SIZE*10)];
                                                        Data[RSet][index][11] <= data[(SIZE*11)+(SIZE-1):(SIZE*11)];
                                                        Data[RSet][index][12] <= data[(SIZE*12)+(SIZE-1):(SIZE*12)];
                                                        Data[RSet][index][13] <= data[(SIZE*13)+(SIZE-1):(SIZE*13)];
                                                        Data[RSet][index][14] <= data[(SIZE*14)+(SIZE-1):(SIZE*14)];
                                                        Data[RSet][index][15] <= data[(SIZE*15)+(SIZE-1):(SIZE*15)];
                                                end
                                                else begin
                                                        Data[RSet][index][0] <= data[(SIZE*0)+(SIZE-1):(SIZE*0)];
                                                        Data[RSet][index][1] <= data[(SIZE*1)+(SIZE-1):(SIZE*1)];
                                                        Data[RSet][index][2] <= data[(SIZE*2)+(SIZE-1):(SIZE*2)];
                                                        Data[RSet][index][3] <= data[(SIZE*3)+(SIZE-1):(SIZE*3)];
                                                        Data[RSet][index][4] <= data[(SIZE*4)+(SIZE-1):(SIZE*4)];
                                                        Data[RSet][index][5] <= data[(SIZE*5)+(SIZE-1):(SIZE*5)];
                                                        Data[RSet][index][6] <= data[(SIZE*6)+(SIZE-1):(SIZE*6)];
							Data[RSet][index][7] <= data[(SIZE*7)+(SIZE-1):(SIZE*7)];
                                                end
						Tag[RSet][index] <= tag;
                                                State[RSet][index][VALID_BIT] <= 1;
                                                State[RSet][index][DIRTY_BIT] <= 0;
                                                State[RSet][index][LRU_BIT] <= 0;
                                                State[~RSet][index][LRU_BIT] <= 1;
                                        end
					else begin
                                                addr_data_enable <= 0;
                                                Wait_fr_mem_read <= SET_WAIT;
                                                Wait_fr_mem_write<=UNSET_WAIT;
                                        end
				end
			end
	
//----------------------------------------------------------------------------------------------------------------
                        //invalidation signal

			else if(rd_wr_evict_flag == INVALIDATE_SIGNAL) begin//cache eviction
				if(flush_before_replacement ==FLUSHING_NOT_NEEDED) begin
					State[CSet][index][VALID_BIT]<=0;
				end
				else if(flush_before_replacement ==FLUSHING_NEEDED) begin
					store_data_enable <= 1;
					 //TODO:move to always_comb
					store_data_at_addr <= ((Tag[CSet][index]<<15)+(index<<6));
					if(SIZE == 32) begin
						flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[CSet][index][0];
						flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[CSet][index][1];
						flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[CSet][index][2];
						flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[CSet][index][3];
						flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[CSet][index][4];
						flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[CSet][index][5];
						flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[CSet][index][6];
						flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[CSet][index][7];
						flush_data[(SIZE*8)+(SIZE-1):(SIZE*8)] <= Data[CSet][index][8];
						flush_data[(SIZE*9)+(SIZE-1):(SIZE*9)] <= Data[CSet][index][9];
						flush_data[(SIZE*10)+(SIZE-1):(SIZE*10)] <= Data[CSet][index][10];
						flush_data[(SIZE*11)+(SIZE-1):(SIZE*11)] <= Data[CSet][index][11];
						flush_data[(SIZE*12)+(SIZE-1):(SIZE*12)] <= Data[CSet][index][12];
						flush_data[(SIZE*13)+(SIZE-1):(SIZE*13)] <= Data[CSet][index][13];
						flush_data[(SIZE*14)+(SIZE-1):(SIZE*14)] <= Data[CSet][index][14];
						flush_data[(SIZE*15)+(SIZE-1):(SIZE*15)] <= Data[CSet][index][15];
					end
					else begin
						flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[CSet][index][0];
						flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[CSet][index][1];
						flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[CSet][index][2];
						flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[CSet][index][3];
						flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[CSet][index][4];
						flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[CSet][index][5];
						flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[CSet][index][6];
						flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[CSet][index][7];
					end
					
					Wait_fr_mem_write<=SET_WAIT;
					ff_CSet<=CSet;
					ff_Cache_block_invalidation<=Cache_block_invalidation;
				end
				else if(flush_before_replacement==WAIT_FOR_FLUSH_COMPLETION) begin
					if(store_data_ready) begin
						State[CSet][index][DIRTY_BIT]<=0;
						State[CSet][index][VALID_BIT]<=0;
						Wait_fr_mem_write<=UNSET_WAIT;
						
					end
					else begin
						store_data_enable <=0;
						Wait_fr_mem_write<=SET_WAIT;
						ff_CSet<=CSet;
						ff_Cache_block_invalidation<=Cache_block_invalidation;
					end
				end		
			end
		end
	end
endmodule
