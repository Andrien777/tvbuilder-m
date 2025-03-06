#pragma once
#define MINIRV32_IMPLEMENTATION
#define MINIRV32WARN(x...) printf(x);
#define MINIRV32_DECORATE static
#define MINI_RV32_RAM_SIZE 62914560
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
	ClassDB::bind_method(D_METHOD("Get_x1"), &RVProc::get_x1);
	ClassDB::bind_method(D_METHOD("Load_mem", "image"), &RVProc::LoadImage);
	ClassDB::bind_method(D_METHOD("Load_dtb", "image"), &RVProc::LoadDTB);
    // TODO: Add pin access methods. Maybe some setup methods?
  }

public:
  struct MiniRV32IMAState *core;
  uint32_t cycles_per_step;
  uint32_t ram_size;
  uint64_t total_cycle_count;
  uint8_t *ram_image;
  void LoadImage(PackedByteArray image); // TODO: Think of valid arguments
  void LoadDTB(PackedByteArray image);
  void Tick();
  uint8_t get_x1();
  RVProc();
  ~RVProc();
};
} // namespace godot
