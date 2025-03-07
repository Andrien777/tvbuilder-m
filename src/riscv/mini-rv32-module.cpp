#include "mini-rv32-module.h"
using namespace godot;

RVProc::RVProc() {
	this->ram_size = MINI_RV32_RAM_SIZE;
	this->ram_image =
      new uint8_t[this->ram_size]; // TODO: Is ths the right amount? I don`t
                                   // think so since it will allocate ram_size
                                   // ints, not ram_size bits
  // this->core = new MiniRV32IMAState();
  this->core = (struct MiniRV32IMAState
                    *)(this->ram_image + this->ram_size -
                       sizeof(struct MiniRV32IMAState)); // TODO: Check this for
                                                         // memory safety.
  this->core->pc = MINIRV32_RAM_IMAGE_OFFSET; // TODO: this define probably does
                                              // not exist here
											  // It does, 0x80000000
  //
  this->core->regs[10] = 0x00; // hart ID
  this->cycles_per_step = 1;
  //
  // dtb_ptr should be : dtb_ptr = ram_amt - dtblen - sizeof( struct
  // MiniRV32IMAState ); where dtblen is the size of the dtbfile (until the end
  // mark)

  // this-> core->regs[11] =
  // dtb_ptr?(dtb_ptr+MINIRV32_RAM_IMAGE_OFFSET):0;
  // //dtb_pa (Must be valid pointer) (Should be pointer to dtb)
  this->core->extraflags |= 3; // Machine
}
void RVProc::Reset(){
	this->core = (struct MiniRV32IMAState
                    *)(this->ram_image + this->ram_size -
                       sizeof(struct MiniRV32IMAState));
	this->core->pc = MINIRV32_RAM_IMAGE_OFFSET; // TODO: this define probably does
                                              // not exist here
											  // It does, 0x80000000
  //
  this->core->regs[10] = 0x00; // hart ID
  this->cycles_per_step = 1;
  //
  // dtb_ptr should be : dtb_ptr = ram_amt - dtblen - sizeof( struct
  // MiniRV32IMAState ); where dtblen is the size of the dtbfile (until the end
  // mark)

  // this-> core->regs[11] =
  // dtb_ptr?(dtb_ptr+MINIRV32_RAM_IMAGE_OFFSET):0;
  // //dtb_pa (Must be valid pointer) (Should be pointer to dtb)
  this->core->extraflags |= 3;
}
RVProc::~RVProc() {
  delete[] this->ram_image; // TODO: If alloc implementation changes, this needs
                            // to be changed.
}
void RVProc::Tick() {
	printf("We are doing something\n");
  int ret = MiniRV32IMAStep(
      this->core, this->ram_image, 0,
      *((uint64_t*)&core->cyclel)/* TODO: Why does it need to know the time?
          to use some timers and interrupts. Needs more attention*/
      ,

      this->cycles_per_step);
	 printf("%x\n", ret);
  switch (ret) {
  case 0:
    break;
  case 1:
    // if (do_sleep)
    // MiniSleep();
    this->total_cycle_count += this->cycles_per_step;
    break;
  case 3:
    // instct = 0;
    break;
  case 0x7777:
    // goto restart; // syscon code for restart
  case 0x5555:
    // printf("POWEROFF@0x%08x%08x\n", core->cycleh, core->cyclel);
    // return 0; // syscon code for power-off
    // TODO: some sort of power-off
    break;
  default:
    // printf("Unknown failure\n");
    // TODO: report failuer
    break;
  }
}

void RVProc::LoadImage(PackedByteArray image) {
  for (int i = 0; i < std::min(image.size(), static_cast<int64_t>(this->ram_size)); i++) {
	  this->ram_image[i] = image[i];
  }
}

void RVProc::LoadDTB(PackedByteArray image) {
	int dtb_ptr = 0;
	dtb_ptr = static_cast<int64_t>(this->ram_size) - image.size() - static_cast<int64_t>(sizeof( struct MiniRV32IMAState ));
  for (int i = 0; i < image.size(); i++) {
	  this->ram_image[dtb_ptr + i] = image[i];
  }
  core->regs[11] = dtb_ptr?(dtb_ptr+MINIRV32_RAM_IMAGE_OFFSET):0;
}

uint32_t RVProc::get_pc() {
	return core->pc;
}

Array RVProc::get_xreg() {
	Array arr;
	for (int i = 0; i < 32; i++) {
		arr.append(core->regs[i]);
	}
	return arr;
}

uint32_t RVProc::get_mstatus() {
	return core->mstatus;
}
uint32_t RVProc::get_mscratch() {
	return core->mscratch;
}
uint32_t RVProc::get_mtvec() {
	return core->mtvec;
}
uint32_t RVProc::get_mie() {
	return core->mie;
}
uint32_t RVProc::get_mip() {
	return core->mip;
}
uint32_t RVProc::get_mepc() {
	return core->mepc;
}
uint32_t RVProc::get_mtval() {
	return core->mtval;
}
uint32_t RVProc::get_mcause() {
	return core->mcause;
}
Array RVProc::get_memory(uint32_t addr, int size) {
	Array res;
	for (uint32_t ptr = addr; ptr < addr + size && ptr < this->ram_size; ptr++) {
		res.append(this->ram_image[ptr]);
	}
	return res;	
}
// void Helper::mmio_out(uint32_t addr, uint32_t val){
	// if (addr == 0x10000000)
		// mmio_output_field = val;
	// else
		// pass //Error
// }
// void Helper::mmio_in(uint32_t addr, uint32_t& val){
	// if(addr == 0x11000000)
		// val = mmio_input_field;
	// else
		// pass //Error
// }