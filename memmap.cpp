#include<iostream>
#include<bitset>
#include<stdlib.h>
using namespace std;
#define GIGA 		(1024UL*1024*1024)
#define PAGE_SIZE 	(1024UL*8)
#define VALID_PAGE_DIR 	(0b0000000011)
#define VALID_PAGE 	(0b0000000001)

__uint64_t get_random_page(bitset<GIGA/PAGE_SIZE> (&memmap)){
	int page_no;
	// This logic could be improved but then we (GIGA/PAGE_SIZE) space
	// Hence sticking to this logic since the number of pages used will be less for us
	do{
		page_no = rand()%(GIGA/PAGE_SIZE);
	}while(memmap[page_no]);
	memmap[page_no] = true;
	return page_no;
}
void init_page_table(char *ram, __uint64_t table_addr){
	for(int i=0;i<1024;i++) {
		*((__uint64_t*)(&ram[table_addr+i*8])) = 0;
	}
}

__uint64_t get_new_pte(char *ram, bitset<GIGA/PAGE_SIZE> (&memmap), __uint64_t base_addr, int vpn, bool isleaf){
	__uint64_t addr = base_addr + vpn*8;
	__uint64_t pte = (*(__uint64_t*)&ram[addr]);
	__uint64_t page_no;
	if(!(pte&VALID_PAGE)){
		page_no = get_random_page(memmap);
		if(isleaf)
			(*(__uint64_t*)&ram[addr]) = (page_no<<10) | VALID_PAGE;
		else
			(*(__uint64_t*)&ram[addr]) = (page_no<<10) | VALID_PAGE_DIR;
		pte = (*(__uint64_t*)&ram[addr]);
		init_page_table(ram, pte);
	}
	return pte;
}

__uint64_t get_old_pte(char *ram, __uint64_t base_addr, int vpn){
	__uint64_t addr = base_addr + vpn*8;
	__uint64_t pte = (*(__uint64_t*)&ram[addr]);
	if(!(pte&VALID_PAGE)){
		cerr << pte <<" invalid pte" <<endl;
		return 0;
	}
	return pte;
}

__uint64_t virt_to_new_phy(char *ram, __uint64_t virt_addr, bitset <GIGA/PAGE_SIZE>(&memmap)) {
	int vpn;
	__uint64_t pte, phy_offset, tmp_virt_addr;
	__uint64_t pt_base_addr = 0;
	phy_offset = virt_addr & 0x0fff;
	tmp_virt_addr = virt_addr >> 12;
	for(int i=0;i<4;i++) {
		vpn = tmp_virt_addr & (0x01ff << 9*(3-i));
		pte = get_new_pte(ram, memmap, pt_base_addr, vpn, i == 3);
		pt_base_addr = ((pte&0x0000ffffffffffff)>>10);
	}
	return (pt_base_addr << 12) | phy_offset;
}
int main() {
	char *ram = (char *)malloc(1*GIGA);

	bitset<GIGA/PAGE_SIZE> memmap;
	memmap[0] = true;
	init_page_table(ram, 0);

	// Temporily for testing
	cout << virt_to_new_phy(ram, 0, memmap) << endl;
	cout << virt_to_new_phy(ram, 1, memmap) << endl;
	cout << virt_to_new_phy(ram, 4096, memmap) << endl;

	//Testing..
	int vpn;
	__uint64_t pte, phy_offset, tmp_virt_addr, virt_addr;
	__uint64_t pt_base_addr = 0;
	pt_base_addr = 0;
	virt_addr = 0x01000;
	tmp_virt_addr = virt_addr >> 12;
	for(int i=0;i<4;i++) {
		vpn = tmp_virt_addr & (0x01ff << 9*(3-i));
		pte = get_new_pte(ram, memmap, pt_base_addr, vpn, i == 3);
		pt_base_addr = ((pte&0x0000ffffffffffff)>>10);
	}
	cout << (pt_base_addr<<12) << endl;

	free(ram);
	return 0;
}
