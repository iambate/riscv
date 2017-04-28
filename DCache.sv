`define CACHEDEBUGXTRA
module D_Set_Associative_Cache
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
	SIZE=64,
	CACHE_MISS=3,
	LRU='b010,
	READ_SIGNAL=1,
	WRITE_SIGNAL=2,
	DIRTY_BIT=0,
	LRU_BIT=1,
	VALID_BIT=2,
	INVAL_RESPTAG='b100000000000
)
(	
	input clk,//F
	input reset,//F
	input [63:0] addr,//F
	input [1:0] rd_wr_evict_flag,//F
	output [1:0] canWrite,
	output [SIZE-1:0] read_data,//F
	output [1:0] data_available,//F
	input [SIZE-1:0] write_data,
	input enable,
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
	logic [63:0] phy_addr;
	logic [63:0] store_data_at_addr;
	logic store_data_enable;
	logic store_data_ready;
	logic addr_data_enable;
	logic addr_data_ready;
	logic inval_signal;
	//TODO: store_data_enable,store_data_at_addr,phy_addr,
	//store_data_ready,addr_data_ready,data,flush_data,addr_data_enable,
	//CHECK:~ sign works?if im setting cache miss addr data and store dtaa should not work
	addr_to_data addr_data(
            .clk(clk),
            .reset(reset),
	    .bus_busy(addr_data_bus_busy),
            .enable(addr_data_enable),

            .abtr_grant(addr_data_abtr_grant),
            .abtr_reqcyc(addr_data_abtr_reqcyc),
            .main_bus_respcyc(bus_respcyc),
            .main_bus_respack(bus_respack),
            .main_bus_resp(bus_resp),
            .main_bus_req(bus_req),
            .main_bus_reqcyc(bus_reqcyc),
            .main_bus_reqtag(bus_reqtag),
	    .main_bus_resptag(bus_resptag),
            .addr(phy_addr),
            .data(data),
            .ready(addr_data_ready)
                       );

	store_data store_data_0(
            .clk(clk),
            .reset(reset),
	    .bus_busy(store_data_bus_busy),
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
	    .main_bus_resptag(bus_resptag),
            .addr(store_data_at_addr),
            .data(flush_data),
            .ready(store_data_ready)
                       );

	always_comb begin
		if(bus_resptag==INVAL_RESPTAG) begin
			assign index = bus_resp[STARTING_INDEX+14:STARTING_INDEX+6];
                	assign tag = bus_resp[63:STARTING_INDEX+15];
			if(Tag[SET1][index]==tag) begin
				assign CSet= SET1;
			end
			else if (Tag[SET2][index]==tag) begin
				assign CSet =SET2;
			end
			assign canWrite=CACHE_MISS;
			assign data_available=CACHE_MISS;
			assign inval_signal=1;
		end
		else if(enable) begin
			assign index = addr[STARTING_INDEX+14:STARTING_INDEX+6];
			assign tag = addr[63:STARTING_INDEX+15];
			assign block_offset = addr[STARTING_INDEX+5:STARTING_INDEX];
			assign starting_addr_of_block = addr[63:6]<<6;
			if(Wait_fr_mem_write==SET_WAIT) begin
				if(rd_wr_evict_flag==WRITE_SIGNAL) begin
					assign WSet=ff_WSet;
					assign canWrite=ff_canWrite;
				end
				else if(rd_wr_evict_flag==READ_SIGNAL) begin
					assign RSet=ff_RSet;
					assign read_data=ff_read_data;
					assign data_available = ff_data_available;
				end
				assign flush_before_replacement = WAIT_FOR_FLUSH_COMPLETION;
			end
			else if(Wait_fr_mem_read == SET_WAIT) begin
				if(rd_wr_evict_flag==WRITE_SIGNAL) begin
					assign WSet=ff_WSet;
					assign canWrite=WAITING_FOR_MEM_READ;
				end
				else if(rd_wr_evict_flag==READ_SIGNAL) begin
					assign RSet=ff_RSet;
					assign read_data=ff_read_data;
					assign data_available = WAITING_FOR_MEM_READ;
				end
				assign flush_before_replacement = ff_flush_before_replacement;
			end
			else if((Tag[SET1][index] == tag) && State[SET1][index]&VALID) begin
				if(rd_wr_evict_flag==WRITE_SIGNAL) begin
					assign WSet=SET1;//write
					assign canWrite=CACHE_HIT;//write
				end
				else if(rd_wr_evict_flag==READ_SIGNAL) begin
					assign RSet=SET1;
					assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
					assign data_available = CACHE_HIT;
				end
			end
			else if((Tag[SET2][index] == tag) && State[SET2][index]&VALID) begin
				if(rd_wr_evict_flag==WRITE_SIGNAL) begin
                                        assign WSet=SET2;//write
                                        assign canWrite=CACHE_HIT;//write
                                end
                                else if(rd_wr_evict_flag==READ_SIGNAL) begin
                                        assign RSet=SET2;
                                        assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
                                        assign data_available = CACHE_HIT;
                                end
			end
			else begin//pick least recently used set to be replaced
				if(rd_wr_evict_flag==WRITE_SIGNAL) begin
					assign canWrite=CACHE_MISS;//write
				end
				else if(rd_wr_evict_flag==READ_SIGNAL) begin
					assign data_available = CACHE_MISS;
				end
				if(State[SET1][index]&LRU) begin
					if(rd_wr_evict_flag==WRITE_SIGNAL) begin
						assign WSet= SET1;//write
					end
					else if(rd_wr_evict_flag==READ_SIGNAL) begin
						assign RSet = SET1;
						//assign read_data = 0;
					end
					if(State[SET1][index]&DIRTY == 1) begin
						assign flush_before_replacement = FLUSHING_NEEDED;//flush before rewriting
					end
					else begin
						assign flush_before_replacement = FLUSHING_NOT_NEEDED;//no need to flush
					end
				end
				else begin
					if(rd_wr_evict_flag==WRITE_SIGNAL) begin
                                                assign WSet= SET2;//write
                                        end
                                        else if(rd_wr_evict_flag==READ_SIGNAL) begin
                                                assign RSet = SET2;
                                                //assign read_data = 0;
                                        end
					if(State[SET2][index]&DIRTY == 1) begin
						assign flush_before_replacement = FLUSHING_NEEDED;
					end
					else begin
						assign flush_before_replacement = FLUSHING_NOT_NEEDED;
					end
				end
			end
		end
		else begin
			assign canWrite =CACHE_MISS;
			assign data_available =CACHE_MISS;
		end
	end
	always_ff @(posedge clk) begin
		//$display("DCACHE enable signal %d", enable);
		if(reset) begin
			Wait_fr_mem_read <= UNSET_WAIT;
			Wait_fr_mem_write <= UNSET_WAIT;
			//TODO:init valid bit
		end
		else begin
			if(inval_signal) begin
`ifdef CACHEDEBUGXTRA
				$display("DCACHE :Invalidation signal received for addr %d",bus_resp);
`endif
				State[CSet][index][VALID_BIT]<=0;
			end
			else if(enable) begin
	`ifdef CACHEDEBUGXTRA   
				$display("DCACHE: new cycle-flag val%d ",rd_wr_evict_flag);
	`endif
				if(rd_wr_evict_flag == READ_SIGNAL) begin //read
`ifdef CACHEDEBUGXTRA
					$display("DCACHE :read signal rcvd for addr %d",addr);
`endif
					if(data_available == CACHE_HIT) begin//not a miss
	`ifdef CACHEDEBUGXTRA
						$display("DCACHE :read data %d", Data[RSet][index][block_offset/(SIZE/8)]);
						$display("DCACHE :read -cache hit");
						$display("DCACHE :read -addr %d", addr);
						$display("DCACHE :read -starting addr of block %d", phy_addr);
						$display("DCACHE :read -index %d", index);
						$display("DCACHE :read -Tag1 %b", Tag[SET1][index]);
						$display("DCACHE :read -Tag2 %b", Tag[SET2][index]);
						$display("DCACHE :read -State1 %b",State[SET1][index]);
						$display("DCACHE :read -State2 %b",State[SET2][index]);
						$display("DCACHE :read -index %b",index);
	`endif
						State[RSet][index][LRU_BIT]<= 0;
						State[~RSet][index][LRU_BIT]<= 1;
					end
					else if(data_available == CACHE_MISS) begin//miss
`ifdef CACHEDEBUGXTRA
						$display("DCACHE: signal %d cache miss",rd_wr_evict_flag);
`endif
						if(flush_before_replacement == FLUSHING_NEEDED) begin
							//TODO:change variables
`ifdef CACHEDEBUGXTRA
							$display("DCACHE: signal %d flushing data at %d",rd_wr_evict_flag,((Tag[RSet][index]<<15)+(index<<6)));
`endif
							ff_RSet<=RSet;
							ff_read_data<=read_data;
							ff_data_available<=data_available;
							ff_flush_before_replacement <=flush_before_replacement;
							
							store_data_enable <= 1;
							//TODO:move to always_comb
							store_data_at_addr <= ((Tag[RSet][index]<<15)+(index<<6));
							flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[RSet][index][0];
							flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[RSet][index][1];
							flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[RSet][index][2];
							flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[RSet][index][3];
							flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[RSet][index][4];
							flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[RSet][index][5];
							flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[RSet][index][6];
							flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[RSet][index][7];
							Wait_fr_mem_write<=SET_WAIT;
							Wait_fr_mem_read <=UNSET_WAIT;
						end
						else if(flush_before_replacement == FLUSHING_NOT_NEEDED) begin
	`ifdef CACHEDEBUGXTRA
							$display("DCACHE :signal %d FLUSHING_NOT_NEEDED Requesting block at %d for miss at %d:\n ",rd_wr_evict_flag, starting_addr_of_block,addr);
	`endif
							addr_data_enable <= 1;
							phy_addr <= starting_addr_of_block;
							Wait_fr_mem_read <= SET_WAIT;
							Wait_fr_mem_write <=UNSET_WAIT;
							ff_data_available<=data_available;
							ff_RSet<=RSet;
							ff_read_data<=read_data;
							ff_flush_before_replacement<=flush_before_replacement;
						end
						else if(flush_before_replacement ==  WAIT_FOR_FLUSH_COMPLETION) begin
							ff_RSet <=RSet;
							ff_read_data <=read_data;
							ff_data_available<=data_available;
							ff_flush_before_replacement<=flush_before_replacement;
							if(store_data_ready) begin//TODO:we are done writing to mem
`ifdef CACHEDEBUGXTRA
                                                                $display("DCACHE :signal %d addr %d doen flushing dirty block at %d",rd_wr_evict_flag,addr,store_data_at_addr);
`endif		
								Wait_fr_mem_write <=UNSET_WAIT;
								Wait_fr_mem_read<=UNSET_WAIT;
								State[RSet][index][DIRTY_BIT]<=0;
							end
							else begin
`ifdef CACHEDEBUGXTRA
								$display("DCACHE :signal %d waiting for flush completion so we can load addr %d state %b",rd_wr_evict_flag,addr,State[RSet][index]);
`endif
								Wait_fr_mem_write <=SET_WAIT;
								Wait_fr_mem_read<=UNSET_WAIT;
								store_data_enable <= 0;
							end
						end
					end
					else if(data_available == WAITING_FOR_MEM_READ) begin
						ff_RSet<=RSet;
						ff_read_data<=read_data;
						ff_data_available<=data_available;
						ff_flush_before_replacement<=flush_before_replacement;
						if(addr_data_ready) begin
	`ifdef CACHEDEBUGXTRA
							$display("DCACHE: read-signal %d",rd_wr_evict_flag);
							$display("DCACHE: read-data is ready %d %d\n",Wait_fr_mem_read,Wait_fr_mem_write);
							$display("DCACHE: read-phy_addr %d", phy_addr);
							$display("DCACHE: read-start block addr %d", starting_addr_of_block);
							$display("DCACHE: read-addr %d tag %d\n",addr, Tag[RSet][index]);
							$display("DCACHE: read-data arrived %x\n",data);
	`endif
							Wait_fr_mem_read <= UNSET_WAIT;
							Wait_fr_mem_write<=UNSET_WAIT;
							Data[RSet][index][0] <= data[(SIZE*0)+(SIZE-1):(SIZE*0)];
							Data[RSet][index][1] <= data[(SIZE*1)+(SIZE-1):(SIZE*1)];
							Data[RSet][index][2] <= data[(SIZE*2)+(SIZE-1):(SIZE*2)];
							Data[RSet][index][3] <= data[(SIZE*3)+(SIZE-1):(SIZE*3)];
							Data[RSet][index][4] <= data[(SIZE*4)+(SIZE-1):(SIZE*4)];
							Data[RSet][index][5] <= data[(SIZE*5)+(SIZE-1):(SIZE*5)];
							Data[RSet][index][6] <= data[(SIZE*6)+(SIZE-1):(SIZE*6)];
							Data[RSet][index][7] <= data[(SIZE*7)+(SIZE-1):(SIZE*7)];
							Tag[RSet][index] <= tag;
							State[RSet][index][VALID_BIT] <= 1;
							State[RSet][index][DIRTY_BIT] <= 0;
							State[RSet][index][LRU_BIT] <= 0;
							State[~RSet][index][LRU_BIT] <= 1;
						end
						else begin
							addr_data_enable <= 0;
	`ifdef CACHEDEBUGXTRA
							$display("DCACHE :signal %d, waiting for data to be read for addr %d\n",rd_wr_evict_flag,addr);
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
`ifdef CACHEDEBUGXTRA
					$display("DCACHE :read signal rcvd for addr %d",addr);
`endif
					if(canWrite==CACHE_HIT)begin
`ifdef CACHEDEBUGXTRA
						$display("DCACHE :write data %d",write_data); 
						$display("DCACHE :write -cache hit");
                                                $display("DCACHE :write -addr %d", addr);
                                                $display("DCACHE :write -starting addr of block %d", phy_addr);
                                                $display("DCACHE :write -index %d", index);
                                                $display("DCACHE :write -Tag1 %b", Tag[SET1][index]);
                                                $display("DCACHE :write -Tag1 %b", Tag[SET2][index]);
                                                $display("DCACHE :write -State1 %b",State[SET1][index]);
                                                $display("DCACHE :write -State2 %b",State[SET2][index]);
						$display("DCACHE :write -index %b",index);
`endif			
						Data[WSet][index][block_offset/(SIZE/8)] <= write_data;
						State[WSet][index][LRU_BIT]<= 0;
						State[~WSet][index][LRU_BIT]<=1;
						State[WSet][index][DIRTY_BIT]<=1;
					end
					else if(canWrite ==CACHE_MISS) begin
`ifdef CACHEDEBUGXTRA
                                                $display("DCACHE: signal %d cache miss",rd_wr_evict_flag);
`endif
						if(flush_before_replacement==FLUSHING_NEEDED) begin
`ifdef CACHEDEBUGXTRA
                                                        $display("DCACHE: signal %d flushing data at %d",rd_wr_evict_flag,((Tag[WSet][index]<<15)+(index<<6)));
`endif
							ff_WSet<=WSet;
							ff_canWrite<=canWrite;
							ff_flush_before_replacement <=flush_before_replacement;

							store_data_enable <= 1;
							//TODO:move to always_comb
							store_data_at_addr <= ((Tag[WSet][index]<<15)+(index<<6));
							flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[WSet][index][0];
							flush_data[(SIZE*1)+(SIZE-1):(SIZE*1)] <= Data[WSet][index][1];
							flush_data[(SIZE*2)+(SIZE-1):(SIZE*2)] <= Data[WSet][index][2];
							flush_data[(SIZE*3)+(SIZE-1):(SIZE*3)] <= Data[WSet][index][3];
							flush_data[(SIZE*4)+(SIZE-1):(SIZE*4)] <= Data[WSet][index][4];
							flush_data[(SIZE*5)+(SIZE-1):(SIZE*5)] <= Data[WSet][index][5];
							flush_data[(SIZE*6)+(SIZE-1):(SIZE*6)] <= Data[WSet][index][6];
							flush_data[(SIZE*7)+(SIZE-1):(SIZE*7)] <= Data[WSet][index][7];
							Wait_fr_mem_write<=SET_WAIT;
							Wait_fr_mem_read <=UNSET_WAIT;
						end
						else if(flush_before_replacement == FLUSHING_NOT_NEEDED) begin
 `ifdef CACHEDEBUGXTRA
                                                        $display("DCACHE :signal %d FLUSHING_NOT_NEEDED Requesting block at %d for miss at %d:\n ",rd_wr_evict_flag, starting_addr_of_block,addr);
 `endif
							addr_data_enable <= 1;
							phy_addr <= starting_addr_of_block;
							Wait_fr_mem_read <= SET_WAIT;
							Wait_fr_mem_write <=UNSET_WAIT;

							ff_WSet<=WSet;
							ff_canWrite<=canWrite;
							ff_flush_before_replacement<=flush_before_replacement;
						end
						else if(flush_before_replacement == WAIT_FOR_FLUSH_COMPLETION) begin
							ff_WSet <= WSet;
							ff_canWrite <= canWrite;
							ff_flush_before_replacement<=flush_before_replacement;
							if(store_data_ready) begin//TODO:we are done writing to mem
`ifdef CACHEDEBUGXTRA
								$display("DCACHE :signal %d addr %d doen flushing dirty block at %d",rd_wr_evict_flag,addr,store_data_at_addr);
`endif
								Wait_fr_mem_write <=UNSET_WAIT;
								Wait_fr_mem_read<=UNSET_WAIT;
								State[WSet][index][DIRTY_BIT]<=0;
							end
							else begin
`ifdef CACHEDEBUGXTRA
                                                                $display("DCACHE :signal %d waiting for flush completion so we can load addr %d state %b",rd_wr_evict_flag,addr,State[WSet][index]);
`endif
								Wait_fr_mem_write <=SET_WAIT;
								Wait_fr_mem_read<=UNSET_WAIT;
								store_data_enable <= 0;
							end
						end
					end
					else if(canWrite==WAITING_FOR_MEM_READ) begin
						ff_WSet<=WSet;
                                                ff_canWrite<=canWrite;
                                                ff_flush_before_replacement<=flush_before_replacement;
						if(addr_data_ready) begin
 `ifdef CACHEDEBUGXTRA
                                                        $display("DCACHE:write- signal %d",rd_wr_evict_flag);
                                                        $display("DCACHE:write- data is ready %d %d\n",Wait_fr_mem_read,Wait_fr_mem_write);
                                                        $display("DCACHE:write-phy_addr %d", phy_addr);
                                                        $display("DCACHE:write- start block addr %d", starting_addr_of_block);
                                                        $display("DCACHE:write- addr %d tag %d\n",addr, Tag[WSet][index]);
                                                        $display("DCACHE:write- data arrived %x\n",data);
 `endif

							Wait_fr_mem_read <= UNSET_WAIT;
							Wait_fr_mem_write<=UNSET_WAIT;
							Data[WSet][index][0] <= data[(SIZE*0)+(SIZE-1):(SIZE*0)];
							Data[WSet][index][1] <= data[(SIZE*1)+(SIZE-1):(SIZE*1)];
							Data[WSet][index][2] <= data[(SIZE*2)+(SIZE-1):(SIZE*2)];
							Data[WSet][index][3] <= data[(SIZE*3)+(SIZE-1):(SIZE*3)];
							Data[WSet][index][4] <= data[(SIZE*4)+(SIZE-1):(SIZE*4)];
							Data[WSet][index][5] <= data[(SIZE*5)+(SIZE-1):(SIZE*5)];
							Data[WSet][index][6] <= data[(SIZE*6)+(SIZE-1):(SIZE*6)];
							Data[WSet][index][7] <= data[(SIZE*7)+(SIZE-1):(SIZE*7)];
							Tag[WSet][index] <= tag;
							State[WSet][index][VALID_BIT] <= 1;
							State[WSet][index][DIRTY_BIT] <= 0;
							State[WSet][index][LRU_BIT] <= 0;
							State[~WSet][index][LRU_BIT] <= 1;
						end
						else begin
 `ifdef CACHEDEBUGXTRA
                                                        $display("DCACHE :signal %d, waiting for data to be read for addr %d\n",rd_wr_evict_flag,addr);
        `endif//XXXXX
							addr_data_enable <= 0;
							Wait_fr_mem_read <= SET_WAIT;
							Wait_fr_mem_write<=UNSET_WAIT;
						end
					end
				end
			end
		end
	end
endmodule
