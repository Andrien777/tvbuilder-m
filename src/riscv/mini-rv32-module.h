#pragma once
#include <stdint.h>
#define MINIRV32_IMPLEMENTATION
#define MINIRV32WARN(x...) printf(x);
#define MINIRV32_HANDLE_MEM_STORE_CONTROL(addr, val) godot::mmio_out(addr, val);
#define MINIRV32_HANDLE_MEM_LOAD_CONTROL(addr, target) godot::mmio_in(addr, &target);
#define MINIRV32_DECORATE static
#define MINI_RV32_RAM_SIZE 67108864
#include "mini-rv32ima.h"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>
#include <algorithm>

namespace godot {
class RVProc : public RefCounted {
  GDCLASS(RVProc, RefCounted);

protected:
  static void _bind_methods() {
    ClassDB::bind_method(D_METHOD("Tick"), &RVProc::Tick);
	ClassDB::bind_method(D_METHOD("get_xreg"), &RVProc::get_xreg);
	ClassDB::bind_method(D_METHOD("get_pc"), &RVProc::get_pc);
	ClassDB::bind_method(D_METHOD("get_mstatus"), &RVProc::get_mstatus);
	ClassDB::bind_method(D_METHOD("get_mscratch"), &RVProc::get_mscratch);
	ClassDB::bind_method(D_METHOD("get_mtvec"), &RVProc::get_mtvec);
	ClassDB::bind_method(D_METHOD("get_mie"), &RVProc::get_mie);
	ClassDB::bind_method(D_METHOD("get_mip"), &RVProc::get_mip);
	ClassDB::bind_method(D_METHOD("get_mepc"), &RVProc::get_mepc);
	ClassDB::bind_method(D_METHOD("get_mtval"), &RVProc::get_mtval);
	ClassDB::bind_method(D_METHOD("get_mcause"), &RVProc::get_mcause);
	ClassDB::bind_method(D_METHOD("get_memory", "addr", "size"), &RVProc::get_memory);
	ClassDB::bind_method(D_METHOD("get_mmio"), &RVProc::get_mmio);
	ClassDB::bind_method(D_METHOD("set_mmio", "value"), &RVProc::set_mmio);
	ClassDB::bind_method(D_METHOD("Load_mem", "image"), &RVProc::LoadImage);
	ClassDB::bind_method(D_METHOD("Load_dtb", "image"), &RVProc::LoadDTB);
    // TODO: Add pin access methods. Maybe some setup methods?
  }

public:
static uint32_t mmio_input_field;
static uint32_t mmio_output_field;
  struct MiniRV32IMAState *core;
  uint32_t cycles_per_step;
  uint32_t ram_size;
  uint64_t total_cycle_count;
  uint8_t *ram_image;
  void LoadImage(PackedByteArray image); // TODO: Think of valid arguments
  void LoadDTB(PackedByteArray image);
  void Tick();
  Array get_xreg();
  uint32_t get_pc();
  uint32_t get_mstatus();
  uint32_t get_mscratch();
  uint32_t get_mtvec();
  uint32_t get_mie();
  uint32_t get_mip();
  uint32_t get_mepc();
  uint32_t get_mtval();
  uint32_t get_mcause();
  uint32_t get_mmio() {return core->mmio_output_field;}
  void set_mmio(uint32_t val) {core->mmio_input_field = val;}
  Array get_memory(uint32_t addr, int size);
  RVProc();
  ~RVProc();
};
} // namespace godot