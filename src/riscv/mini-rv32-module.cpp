#include "mini-rv32-module.h"
#include "mini-rv32ima.h"
using namespace godot;

RVProc::RVProc() {
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
  //
  this->core->regs[10] = 0x00; // hart ID
  //
  // dtb_ptr should be : dtb_ptr = ram_amt - dtblen - sizeof( struct
  // MiniRV32IMAState ); where dtblen is the size of the dtbfile (until the end
  // mark)

  // this-> core->regs[11] =
  // dtb_ptr?(dtb_ptr+MINIRV32_RAM_IMAGE_OFFSET):0;
  // //dtb_pa (Must be valid pointer) (Should be pointer to dtb)
  this->core->extraflags |= 3; // Machine
}
RVProc::~RVProc() {
  delete[] this->ram_image; // TODO: If alloc implementation changes, this needs
                            // to be changed.
}
void RVProc::Tick() {
  int ret = MiniRV32IMAStep(
      this->core, this->ram_image, 0,
      0 /* TODO: Why does it need to know the time?
          to use some timers and interrupts. Needs more attention*/
      ,

      this->cycles_per_step);
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

void RVProc::LoadImage() {
  // TODO: Get it from godot somehow
}
