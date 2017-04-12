module Set_Associative_Cache
#(
	SIZE=32,
	FLUSH_BEFORE_REWRITE = 1,
	FLUSHING_NOT_NEEDED = 0,
	WAITING_FOR_MEM_WRITE = 2,
	DATA_AVAILABLE_FOR_READ = 1,
	READ_MISS = 0,
	WAITING_FOR_MEM_READ = 2,
	VALID='b100,
	LRU='b010,
	DIRTY='b001
)
(	
	input[63:0]  addr,
	output [SIZE-1:0] read_data,
	output data_available
);
	logic [8:0] index;
	logic [48:0] tag;
	logic [5:0] block_offset;
	logic WSet;
	logic RSet;
	logic 
//marked least recently used set as 1
	always_comb begin
		assign index = addr[STARTING_INDEX+14:STARTING_INDEX+6];
		assign tag = addr[63:STARTING_INDEX+15];
		assign block_offset = addr[STARTING_INDEX+5:STARTING_INDEX];
		if((Tag[0][index] == tag) && (State[0][index]&VALID == 1)) begin
			assign WSet=0;//write
			assign canWrite=1;//write
			assign RSet=0;
			assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
			assign data_available = DATA_AVAILABLE_FOR_READ;
		end
		else if((Tag[1][index] == tag) && (State[1][index]&VALID == 1)) begin
			assign WSet=1;//write
			assign canWrite=1;//write
                        assign RSet=1;
			assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
			assign data_available = DATA_AVAILABLE_FOR_READ;
                end
		else begin//pick least recently used set to be replaced
			assign canWrite=0;//write
			if(Tag[0][index]&LRU == 1) begin
				assign WSet=0;//write
				assign RSet = 0;
				assign data_available = READ_MISS;
				assign read_data = 0;
				if(State[RSet][index]&DIRTY == 1) begin
					//use for write
					assign flush_before_replacement = FLUSH_BEFORE_REWRITE;//flush before rewriting
				end
				else begin
					//use for write
					assign flush_before_replacement = FLUSHING_NOT_NEEDED;//no need to flush
				end
			end
			else begin
				assign WSet=1;
				assign RSet = 1;
				assign data_available = READ_MISS;
                                assign read_data = 0;
				if(State[RSet][index]&DIRTY == 1) begin
                                        assign flush_before_replacement = FLUSH_BEFORE_REWRITE;
                                end
                                else begin
                                        assign flush_before_replacement = FLUSHING_NOT_NEEDED;
                                end
			end
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
		end
		else begin
			if(rd_wr_evict_flag == 0) begin //read
				if(data_available == DATA_AVAILABLE_FOR_READ) begin//not a miss
					State[Rset][index]<= 0;
					State[~Rset][index]<= 1;
				end
				else if(data_available == READ_MISS) begin//miss
					if(flush_before_replacement == FLUSH_BEFORE_REWRITE) begin
						//TODO:change variables
						store_data_enable <= 1;
						store_data_at_addr <= Tag[Rset][index];
						if(SIZE == 32) begin
                                                        flush_data[(SIZE*0)+(SIZE-1):(SIZE*0)] <= Data[RSet][index][0];
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
						flush_before_replacement <= WAITING_FOR_MEM_WRITE;	
					end
					else if(flush_before_replacement == FLUSHING_NOT_NEEDED) begin
						addr_data_enable <= 1;
						phy_addr <= addr;
						data_available <= WAITING_FOR_MEM_READ;	
					end
					else if(flush_before_replacement == WAITING_FOR_MEM_WRITE) begin //wait for data to be written
						if(store_data_ready) begin//TODO:we are done writing to mem
							addr_data_enable <= 1;
                                                	phy_addr <= addr;
                                                	data_available <= WAITING_FOR_MEM_READ;
						end
						else begin
							store_data_enable <= 0;
						end
					end
				end
				else if(data_available == WAITING_FOR_MEM_READ) begin
					addr_data_enable <= 0;
					if(addr_data_ready) begin
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
						State[RSet][index][2] <= 1;
						State[RSet][index][0] <= 0;
					end
					//wait, request has been sent, check if data is available, if its
					// fill in this cycle and change Tag, State arrays 
				end
			end
			else if(rd_wr_evict_flag == 1) begin//write
				if(can_Write==1)begin
					Data[WSet][index][block_offset/(SIZE/8)] <= write_data;
					State[WSet][index][1]<= 0;
					State[~WSet][index][1]<=1;
					State[WSet][index][0]<=1;
				end
				else if(canWrite ==0) begin
					if(flush_before_replacement==FLUSH_BEFORE_REWRITE) begin
						store_data_enable <= 1;
                                                store_data_at_addr <= Tag[Wset][index];
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
                                                flush_before_replacement <= WAITING_FOR_MEM_WRITE;
					end
					else if(flush_before_replacement == FLUSHING_NOT_NEEDED) begin
						addr_data_enable <= 1;
                                                phy_addr <= addr;//TODO:set last 6 bits to 0
                                                canWrite <= WAITING_FOR_CACHE_FILL;
					end
					else begin
						if(store_data_ready) begin//TODO:we are done writing to mem
                                                        addr_data_enable <= 1;
                                                        phy_addr <= addr;//TODO:set last 6 bits to 0
                                                        canWrite <= WAITING_FOR_CACHE_FILL;
                                                end
                                                else begin
                                                        store_data_enable <= 0;
                                                end
					end
				end
				else if(canWrite==WAITING_FOR_CACHE_FILL) begin
					addr_data_enable <= 0;
                                        if(addr_data_ready) begin
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
                                                State[RSet][index][2] <= 1;
                                                State[RSet][index][0] <= 0;
                                        end
				end
			end
			else begin//cache eviction
			end
		end
	end
endmodule
