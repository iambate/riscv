module Set_Associative_Cache
#(
	FLUSH_BEFORE_REWRITE = 1,
	FLUSHING_NOT_NEEDED = 0,
	WAITING_FOR_MEM_WRITE = 2,
	DATA_AVAILABLE_FOR_READ = 1,
	READ_MISS = 0,
	WAITING_FOR_MEM_READ = 2
)
(
);
//marked least recently used set as 1
	always_comb begin
		assign index = addr[STARTING_INDEX+14:STARTING_INDEX+6];
		assign tag = addr[63:STARTING_INDEX+15];
		assign block_offset = addr[STARTING_INDEX+5:STARTING_INDEX];
		if((Tag[0][index] == tag) && (State[0][index]&VALID == 1)) begin
			assign RSet=0;
			assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
			assign data_available = DATA_AVAILABLE_FOR_READ;
		end
		else if((Tag[1][index] == tag) && (State[1][index]&VALID == 1)) begin
                        assign RSet=1;
			assign read_data = Data[RSet][index][block_offset/(SIZE/8)];
			assign data_available = DATA_AVAILABLE_FOR_READ;
                end
		else begin//pick least recently used set to be replaced
			if(Tag[0][index]&LRU == 1) begin
				assign RSet = 0;
				assign data_available = READ_MISS;
				assign read_data = 0;
				if(State[RSet][index]&DIRTY == 1) begin
					assign flush_before_read = FLUSH_BEFORE_REWRITE;//flush before rewriting
				end
				else begin
					assign flush_before_read = FLUSHING_NOT_NEEDED;//no need to flush
				end
			end
			else begin
				assign RSet = 1;
				assign data_available = READ_MISS;
                                assign read_data = 0;
				if(State[RSet][index]&DIRTY == 1) begin
                                        assign flush_before_read = FLUSH_BEFORE_REWRITE;
                                end
                                else begin
                                        assign flush_before_read = FLUSHING_NOT_NEEDED;
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
					if(flush_before_read == FLUSH_BEFORE_REWRITE) begin
						//change variables
						addr_data_enable <= 1;
						phy_addr <= Tag[Rset][index];
						int j;
						for(j=0;j<(64/(SIZE/8));j+=1) begin
                                                        data[(SIZE*j)+(SIZE-1):(SIZE*j)] <= Data[RSet][index][j];
                                                end
						//till here
						flush_before_read <= 2;	
					end
					else if(flush_before_read == FLUSHING_NOT_NEEDED) begin
						addr_data_enable <= 1;
						phy_addr <= addr;
						data_available = WAITING_FOR_MEM_READ;	
					end
					else if(flush_before_read == WAITING_FOR_MEM_WRITE) begin //wait for data to be written
						if(addr_data_ready) begin
							addr_data_enable <= 1;
                                                	phy_addr <= addr;
                                                	data_available = WAITING_FOR_MEM_READ;
						end
						else begin
							addr_data_enable <= 0;
						end
					end
				end
				else if(data_available == WAITING_FOR_MEM_READ) begin
					addr_data_enable <= 0;
					if(addr_data_ready) begin
						for(i=0;i<(64/(SIZE/8));i+=1) begin
                					Data[RSet][index][i] <= data[(SIZE*i)+(SIZE-1):(SIZE*i)]
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
			end
			else begin//cache eviction
			end
		end
	end
endmodule
