#ifndef __SYSTEM_H
#define __SYSTEM_H

#include <map>
#include <list>
#include <queue>
#include <utility>
#include <bitset>
#include "DRAMSim2/DRAMSim.h"
#include "Vtop.h"

#define KILO (1024UL)
#define MEGA (1024UL*1024)
#define GIGA (1024UL*1024*1024)

#define PAGE_SIZE 	(1024UL*4)
#define VALID_PAGE_DIR 	(0b0000000011)
#define VALID_PAGE 	(0b0000000001)

typedef unsigned long __uint64_t;
typedef __uint64_t uint64_t;
typedef unsigned int __uint32_t;
typedef __uint32_t uint32_t;
typedef int __int32_t;
typedef __int32_t int32_t;
typedef unsigned short __uint16_t;
typedef __uint16_t uint16_t;

extern uint64_t main_time;
extern const int ps_per_clock;
double sc_time_stamp();

class System {
    Vtop* top;

    char* ram;
    unsigned int ramsize;
    uint64_t max_elf_addr;
    bitset<GIGA/PAGE_SIZE> memmap;

    enum { IRQ_TIMER=0, IRQ_KBD=1 };
    int interrupts;
    std::queue<char> keys;

    bool show_console;

    uint64_t load_elf(const char* filename);

    int cmd, rx_count;
    uint64_t xfer_addr;
    std::map<uint64_t, std::pair<uint64_t, int> > addr_to_tag;
    std::list<std::pair<uint64_t, int> > tx_queue;

    void dram_read_complete(unsigned id, uint64_t address, uint64_t clock_cycle);
    void dram_write_complete(unsigned id, uint64_t address, uint64_t clock_cycle);
    uint64_t get_random_page();
    void init_page_table(uint64_t table_addr);
    uint64_t get_new_pte(uint64_t base_addr, int vpn, bool isleaf);
    uint64_t get_old_pte(uint64_t base_addr, int vpn);
    uint64_t virt_to_new_phy(uint64_t virt_addr);
    uint64_t virt_to_old_phy(uint64_t virt_addr);
    void load_segment(int fileDescriptor, size_t header_size, uint64_t start_addr);
    uint64_t load_elf_parts(int fileDescriptor, size_t size, uint64_t virt_addr);

    DRAMSim::MultiChannelMemorySystem* dramsim;
    
public:
    System(Vtop* top, unsigned ramsize, const char* ramelf, const int argc, char* argv[], int ps_per_clock);
    ~System();

    void console();
    void tick(int clk);

    uint64_t get_ram_address() const { return (uint64_t)ram; }
    uint64_t get_max_elf_addr() const { return max_elf_addr;  }
};

#endif
