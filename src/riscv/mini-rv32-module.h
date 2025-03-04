#include "mini-rv32ima.h"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>

#define MINIRV32WARN(x...) printf(x);
#define MINIRV32_DECORATE static
#define MINI_RV32_RAM_SIZE ram_size
#define MINIRV32_IMPLEMENTATION
namespace godot {

class RVProc : public RefCounted {
  GDCLASS(RVProc, RefCounted);

protected:
  static void _bind_methods() {
    ClassDB::bind_method(D_METHOD("Tick"), &RVProc::Tick);
    // TODO: Add pin access methods. Maybe some setup methods?
  }

public:
  struct MiniRV32IMAState *core;
  uint32_t ram_size;
  uint32_t cycles_per_step;
  uint64_t total_cycle_count;
  uint8_t *ram_image;
  void LoadImage(); // TODO: Think of valid arguments
  void Tick();
  RVProc();
  ~RVProc();
};
} // namespace godot
