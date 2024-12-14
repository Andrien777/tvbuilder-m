#ifndef TVBUILDER_IPROC_8088_H
#define TVBUILDER_IPROC_8088_H

//#include <ComCtrls.hpp>
#include <set>
#include <queue>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

#define PREFETCH_QUEUE_8086_MAX_SIZE 4

using word = unsigned __int16;
typedef uint8_t byte;

// TW is T Wait - possibly not used in emu
enum class TState {
    T1, // (back) start of bus cycle - set IO/M, DT/R, DEN, ALE and address
    T15, // (front)
    T2, // (back) - disable ALE
    T25, // (front) - disable address, set DEN, RD or WR
    T3, // (back) wait for READY
    T35, // (front) read data if read cycle
    T4, // (back) reset signals - cycle is finished
};

enum class EUSTate {
    OPCODE_FETCH, INSTRUCTION_EXECUTION
};

enum class EffectiveAddressState {
    FETCH_MOD_REG_RM_BYTE,
    DECODE
};

enum class EffectiveAddressWriteBackState {
    WRITE_LOW, WRITE_HIGH
};

enum class EffectiveAddressFetchDataState {
    FETCH_LOW, FETCH_HIGH
};

enum class SegmentRegister {
    ES, CS, SS, DS, SEGMENT_00 // order is important
};

enum class Register {
  AL, CL, DL, BL,
  AH, CH, DH, BH,
  AX, CX, DX, BX,
  SP, BP, SI, DI
}; // order is important

enum class BIUAction {
    MR, MW, IOR, IOW
};

enum class BIUByteState {
    LOW, HIGH
};

class PrefetchQueue {
public:
	std::queue<byte> queue;

    int size() {
		return queue.size();
    }

    bool full() {
        return queue.size() == maxSize;
    }

    bool empty() {
		return queue.empty();
    }

	void push(byte value) {
        if (queue.size() < maxSize) {
            queue.push(value);
        }
    }

	byte pop() {
		byte value = queue.front();
		queue.pop();
		return value;
	}

	void reset() {
		while (!queue.empty())
			queue.pop();
	}

    PrefetchQueue(int maxSize) {
        this->maxSize = maxSize;
    }

private:
    int maxSize;
};


//i8088
/* pins (from 0)
 *
 * Delay: 80 ns
 * min {max} mode
 *
 * Pin    | Access:               | in_signal | out_signal
 *     0  | GND                   |           |
 *     1  | Out (A14)             |           |     0
 *     2  | Out (A13)             |           |     1
 *     3  | Out (A12)             |           |     2
 *     4  | Out (A11)             |           |     3
 *     5  | Out (A10)             |           |     4
 *     6  | Out (A9)              |           |     5
 *     7  | Out (A8)              |           |     6
 *     8  | IO (AD7)              |    0      |     7
 *     9  | IO (AD6)              |    1      |     8
 *     10 | IO (AD5)              |    2      |     9
 *     11 | IO (AD4)              |    3      |     10
 *     12 | IO (AD3)              |    4      |     11
 *     13 | IO (AD2)              |    5      |     12
 *     14 | IO (AD1)              |    6      |     13
 *     15 | IO (AD0)              |    7      |     14
 *     16 | In (NMI)              |    8      |
 *     17 | In (INTR)             |    9      |
 *     18 | In (CLK)              |    10     |
 *     19 | GND                   |           |
 *     20 | In (RESET)            |    11     |
 *     21 | In (READY)            |    12     |
 *     22 | In (!TEST)            |    13     |
 *     23 | Out (!INTA {QS1})     |           |     15
 *     24 | Out (ALE {QS0})       |           |     16
 *     25 | Out (!DEN {!S0})      |           |     17
 *     26 | Out (DT/!R {!S1})     |           |     18
 *     27 | Out (IO/!M {!S2})     |           |     19
 *     28 | Out (!WR {!LOCK})     |           |     20
 *     29 | Out (HLDA {!RQ/!GT1}) |           |     21
 *     30 | In (HOLD {!RQ/!GT0})  |    14     |
 *     31 | Out (!RD)             |           |     22
 *     32 | In (MN/!MX)           |    15     |
 *     33 | Out (!SS0 {HIGH})     |           |     23
 *     34 | Out (A19/S6)          |           |     24
 *     35 | Out (A18/S5)          |           |     25
 *     36 | Out (A17/S4)          |           |     26
 *     37 | Out (A16/S3)          |           |     27
 *     38 | Out (A15)             |           |     28
 *     39 | VCC                   |           |
*/
class IProc_8088 : public RefCounted {
	GDCLASS(IProc_8088, RefCounted)
	
protected:
    static void _bind_methods() {
		
		ClassDB::bind_method(D_METHOD("Perform_work"), &IProc_8088::Perform_work);
		ClassDB::bind_method(D_METHOD("setPinOutputDisabled", "index", "value"), &IProc_8088::setPinOutputDisabled);
		ClassDB::bind_method(D_METHOD("getPinOutputDisabled", "index"), &IProc_8088::getPinOutputDisabled);
		
		ClassDB::bind_method(D_METHOD("getClockPin"), &IProc_8088::getClockPin);
		ClassDB::bind_method(D_METHOD("setClockPin"), &IProc_8088::setClockPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "clock_pin"), "setClockPin", "getClockPin");
		
		ClassDB::bind_method(D_METHOD("getALEPin"), &IProc_8088::getALEPin);
		ClassDB::bind_method(D_METHOD("setALEPin"), &IProc_8088::setALEPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "ale_pin"), "setALEPin", "getALEPin");
		
		ClassDB::bind_method(D_METHOD("getDENPin"), &IProc_8088::getDENPin);
		ClassDB::bind_method(D_METHOD("setDENPin"), &IProc_8088::setDENPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "den_pin"), "setDENPin", "getDENPin");
		
		ClassDB::bind_method(D_METHOD("getDT_NRPin"), &IProc_8088::getDT_NRPin);
		ClassDB::bind_method(D_METHOD("setDT_NRPin"), &IProc_8088::setDT_NRPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "dt_nr_pin"), "setDT_NRPin", "getDT_NRPin");
		
		ClassDB::bind_method(D_METHOD("getIO_NMPin"), &IProc_8088::getIO_NMPin);
		ClassDB::bind_method(D_METHOD("setIO_NMPin"), &IProc_8088::setIO_NMPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "io_np_pin"), "setIO_NMPin", "getIO_NMPin");
		
		ClassDB::bind_method(D_METHOD("getWRPin"), &IProc_8088::getWRPin);
		ClassDB::bind_method(D_METHOD("setWRPin"), &IProc_8088::setWRPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "wr_pin"), "setWRPin", "getWRPin");
		
		ClassDB::bind_method(D_METHOD("getRDPin"), &IProc_8088::getRDPin);
		ClassDB::bind_method(D_METHOD("setRDPin"), &IProc_8088::setRDPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "rd_pin"), "setRDPin", "getRDPin");
		
		ClassDB::bind_method(D_METHOD("getMN_MXPin"), &IProc_8088::getMN_MXPin);
		ClassDB::bind_method(D_METHOD("setMN_MXPin"), &IProc_8088::setMN_MXPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "mn_mx_pin"), "setMN_MXPin", "getMN_MXPin");
		
		ClassDB::bind_method(D_METHOD("getResetPin"), &IProc_8088::getResetPin);
		ClassDB::bind_method(D_METHOD("setResetPin"), &IProc_8088::setResetPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "rst_pin"), "setResetPin", "getResetPin");
		
		ClassDB::bind_method(D_METHOD("getReadyPin"), &IProc_8088::getReadyPin);
		ClassDB::bind_method(D_METHOD("setReadyPin"), &IProc_8088::setReadyPin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "rdy_pin"), "setReadyPin", "getReadyPin");
		
		ClassDB::bind_method(D_METHOD("getA0Pin"), &IProc_8088::getA0Pin);
		ClassDB::bind_method(D_METHOD("setA0Pin"), &IProc_8088::setA0Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a0_pin"), "setA0Pin", "getA0Pin");
		
		ClassDB::bind_method(D_METHOD("getA1Pin"), &IProc_8088::getA1Pin);
		ClassDB::bind_method(D_METHOD("setA1Pin"), &IProc_8088::setA1Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a1_pin"), "setA1Pin", "getA1Pin");
		
		ClassDB::bind_method(D_METHOD("getA2Pin"), &IProc_8088::getA2Pin);
		ClassDB::bind_method(D_METHOD("setA2Pin"), &IProc_8088::setA2Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a2_pin"), "setA2Pin", "getA2Pin");
		
		ClassDB::bind_method(D_METHOD("getA3Pin"), &IProc_8088::getA3Pin);
		ClassDB::bind_method(D_METHOD("setA3Pin"), &IProc_8088::setA3Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a3_pin"), "setA3Pin", "getA3Pin");
		
		ClassDB::bind_method(D_METHOD("getA4Pin"), &IProc_8088::getA4Pin);
		ClassDB::bind_method(D_METHOD("setA4Pin"), &IProc_8088::setA4Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a4_pin"), "setA4Pin", "getA4Pin");
		
		ClassDB::bind_method(D_METHOD("getA5Pin"), &IProc_8088::getA5Pin);
		ClassDB::bind_method(D_METHOD("setA5Pin"), &IProc_8088::setA5Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a5_pin"), "setA5Pin", "getA5Pin");
		
		ClassDB::bind_method(D_METHOD("getA6Pin"), &IProc_8088::getA6Pin);
		ClassDB::bind_method(D_METHOD("setA6Pin"), &IProc_8088::setA6Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a6_pin"), "setA6Pin", "getA6Pin");
		
		ClassDB::bind_method(D_METHOD("getA7Pin"), &IProc_8088::getA7Pin);
		ClassDB::bind_method(D_METHOD("setA7Pin"), &IProc_8088::setA7Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a7_pin"), "setA7Pin", "getA7Pin");
		
		ClassDB::bind_method(D_METHOD("getA8Pin"), &IProc_8088::getA8Pin);
		ClassDB::bind_method(D_METHOD("setA8Pin"), &IProc_8088::setA8Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a8_pin"), "setA8Pin", "getA8Pin");
		
		ClassDB::bind_method(D_METHOD("getA9Pin"), &IProc_8088::getA9Pin);
		ClassDB::bind_method(D_METHOD("setA9Pin"), &IProc_8088::setA9Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a9_pin"), "setA9Pin", "getA9Pin");
		
		ClassDB::bind_method(D_METHOD("getA10Pin"), &IProc_8088::getA10Pin);
		ClassDB::bind_method(D_METHOD("setA10Pin"), &IProc_8088::setA10Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a10_pin"), "setA10Pin", "getA10Pin");
		
		ClassDB::bind_method(D_METHOD("getA11Pin"), &IProc_8088::getA11Pin);
		ClassDB::bind_method(D_METHOD("setA11Pin"), &IProc_8088::setA11Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a11_pin"), "setA11Pin", "getA11Pin");
		
		ClassDB::bind_method(D_METHOD("getA12Pin"), &IProc_8088::getA12Pin);
		ClassDB::bind_method(D_METHOD("setA12Pin"), &IProc_8088::setA12Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a12_pin"), "setA12Pin", "getA12Pin");
		
		ClassDB::bind_method(D_METHOD("getA13Pin"), &IProc_8088::getA13Pin);
		ClassDB::bind_method(D_METHOD("setA13Pin"), &IProc_8088::setA13Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a13_pin"), "setA13Pin", "getA13Pin");
		
		ClassDB::bind_method(D_METHOD("getA14Pin"), &IProc_8088::getA14Pin);
		ClassDB::bind_method(D_METHOD("setA14Pin"), &IProc_8088::setA14Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a14_pin"), "setA14Pin", "getA14Pin");
		
		ClassDB::bind_method(D_METHOD("getA15Pin"), &IProc_8088::getA15Pin);
		ClassDB::bind_method(D_METHOD("setA15Pin"), &IProc_8088::setA15Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a15_pin"), "setA15Pin", "getA15Pin");
		
		ClassDB::bind_method(D_METHOD("getA16Pin"), &IProc_8088::getA16Pin);
		ClassDB::bind_method(D_METHOD("setA16Pin"), &IProc_8088::setA16Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a16_pin"), "setA16Pin", "getA16Pin");
		
		ClassDB::bind_method(D_METHOD("getA17Pin"), &IProc_8088::getA17Pin);
		ClassDB::bind_method(D_METHOD("setA17Pin"), &IProc_8088::setA17Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a17_pin"), "setA17Pin", "getA17Pin");
		
		ClassDB::bind_method(D_METHOD("getA18Pin"), &IProc_8088::getA18Pin);
		ClassDB::bind_method(D_METHOD("setA18Pin"), &IProc_8088::setA18Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a18_pin"), "setA18Pin", "getA18Pin");
		
		ClassDB::bind_method(D_METHOD("getA19Pin"), &IProc_8088::getA19Pin);
		ClassDB::bind_method(D_METHOD("setA19Pin"), &IProc_8088::setA19Pin);
		ADD_PROPERTY(PropertyInfo(Variant::BOOL, "a19_pin"), "setA19Pin", "getA19Pin");
	};
	
private:
/**
 * true, if the bit with index [bitIdx] == 1 in number [n], else false
 */
bool isActiveBitByIdx(int n, int bitIdx)
{
    return ((n >> bitIdx) & 1U) == 1;
}

/**
 * set [bitIdx]'th bit of [n] with [value] (0, 1)
 */
void setBitByIdx(int* n, int bitIdx, int value)
{
    if (value) {
        // set to 1
        *n |= 1UL << bitIdx;
    } else {
        // reset to 0
        *n &= ~(1UL << bitIdx);
    }
}

/**
 * set [bitIdx]'th bit of [n] with [value] (0, 1)
 */
void setBitByIdx_s(word* n, int bitIdx, int value)
{
    if (value) {
        // set to 1
        *n |= 1UL << bitIdx;
    } else {
        // reset to 0
        *n &= ~(1UL << bitIdx);
    }
}
	
public:
    bool prevClock; // Clock at previous state

    static const word DEFAULT_FLAGS = 0xF000;
    static const word DEFAULT_CS = 0xFFFF;
    static const word DEFAULT_ES = 0;
    static const word DEFAULT_SS = 0;
    static const word DEFAULT_DS = 0;
    static const word DEFAULT_IP = 0;

    word flags;

	word ax; // accumulator
	word bx; // base
	word cx; // count
	word dx; // data

	word sp; // stack pointer
	word bp; // base pointer
	word si; // source index
	word di; // destination index
	word ip; // instruction pointer

	word cs; // code segment
	word ds; // data segment
	word ss; // stack segment
	word es; // extra segment

    // CF (Carry flag)
    bool getFlagCarry() { return isActiveBitByIdx(flags, 0); }
	void setFlagCarry(bool value) { setBitByIdx_s(&flags, 0, value); }

    // PF (Parity flag)
    bool getFlagParity() { return isActiveBitByIdx(flags, 2); }
	void setFlagParity(bool value) { setBitByIdx_s(&flags, 2, value); }

    // AF (Auxiliary carry flag)
    bool getFlagAuxiliaryCarry() { return isActiveBitByIdx(flags, 4); }
	void setFlagAuxiliaryCarry(bool value) { setBitByIdx_s(&flags, 4, value); }

    // ZF (Zero flag)
    bool getFlagZero() { return isActiveBitByIdx(flags, 6); }
	void setFlagZero(bool value) { setBitByIdx_s(&flags, 6, value); }

    // SF (Sign flag)
    bool getFlagSign() { return isActiveBitByIdx(flags, 7); }
	void setFlagSign(bool value) { setBitByIdx_s(&flags, 7, value); }

    // Control flags below

    // TF (Trace flag)
	bool getFlagTrace() { return isActiveBitByIdx(flags, 8); }
	void setFlagTrace(bool value) { setBitByIdx_s(&flags, 8, value); }

    // IF (Interrupt enable flag)
    bool getFlagInterrupt() { return isActiveBitByIdx(flags, 9); }
	void setFlagInterrupt(bool value) { setBitByIdx_s(&flags, 9, value); }

    // DF (Direction flag)
    bool getFlagDirection() { return isActiveBitByIdx(flags, 10); }
	void setFlagDirection(bool value) { setBitByIdx_s(&flags, 10, value); }

    // -----

    // OF (Overflow flag)
    bool getFlagOverflow() { return isActiveBitByIdx(flags, 11); }
	void setFlagOverflow(bool value) { setBitByIdx_s(&flags, 11, value); }

    void setFlagsByteSZP(byte data) {
        setFlagZero(0);
        setFlagSign(0);
        setFlagParity(0);

        if (data & 0x80) setFlagSign(1);
        if (data == 0) setFlagZero(1);

        int activeBitsData = 0;
        for (int i = 0; i < 8; i++) {
			activeBitsData += isActiveBitByIdx(data, i);
        }

        if (activeBitsData % 2 == 0) setFlagParity(1);
    }

    void setFlagsWordSZP(word data) {
        setFlagZero(0);
        setFlagSign(0);
        setFlagParity(0);

        if (data & 0x8000) setFlagSign(1);
        if (data == 0) setFlagZero(1);

        int activeBitsData = 0;
        // Parity is only for least byte
        for (int i = 0; i < 8; i++) {
			activeBitsData += isActiveBitByIdx(data, i);
        }

        if (activeBitsData % 2 == 0) setFlagParity(1);
    }
	

    // ------------ //
    // pins section //
	
	bool clock;
    bool getClockPin() const { return clock; }
	void setClockPin(const bool value) { clock = value; }
	
	bool ale = false;
    void setALEPin(const bool value) { ale = value; }
	bool getALEPin() const { return ale; }

	bool den = false;
    void setDENPin(const bool value) { den = value; }
	bool getDENPin() const { return den; }

	bool dt_nr = false;
    void setDT_NRPin(const bool value) { dt_nr = value; }
	bool getDT_NRPin() const { return dt_nr; }
	
	bool io_nm = false;
    void setIO_NMPin(const bool value) { io_nm = value; }
	bool getIO_NMPin() const { return io_nm; }

    /**
     * active - 0
     */
	 bool wr = false;
    void setWRPin(const bool value) { wr = value; }
	bool getWRPin() const { return wr; }

    /**
     * active - 0
     */
	 bool rd = false;
    void setRDPin(const bool value) { rd = value; }
	bool getRDPin() const { return rd; }

    /**
     * 0 - MX mode
     * 1 - MN mode
     */
	 bool mn_mx;
    bool getMN_MXPin() const { return mn_mx; }
	void setMN_MXPin(const bool value) { mn_mx = value; }
	
	bool rst;
    bool getResetPin() const { return rst; }
	void setResetPin(const bool value) { rst = value; }
	
	bool rdy;
    bool getReadyPin() const { return rdy; }
	void setReadyPin(const bool value) { rdy = value; }
	
	bool a_pins[20] = {false};
    void setA0Pin(const bool value) { a_pins[0] = value; }
	bool getA0Pin() const { return a_pins[0]; }

    void setA1Pin(const bool value) { a_pins[1] = value; }
	bool getA1Pin() const { return a_pins[1]; }

    void setA2Pin(const bool value) { a_pins[2] = value; }
	bool getA2Pin() const { return a_pins[2]; }

    void setA3Pin(const bool value) { a_pins[3] = value; }
	bool getA3Pin() const { return a_pins[3]; }

    void setA4Pin(const bool value) { a_pins[4] = value; }
	bool getA4Pin() const { return a_pins[4]; }

    void setA5Pin(const bool value) { a_pins[5] = value; }
	bool getA5Pin() const { return a_pins[5]; }

    void setA6Pin(const bool value) { a_pins[6] = value; }
	bool getA6Pin() const { return a_pins[6]; }

    void setA7Pin(const bool value) { a_pins[7] = value; }
	bool getA7Pin() const { return a_pins[7]; }

    void setA8Pin(const bool value) { a_pins[8] = value; }
	bool getA8Pin() const { return a_pins[8]; }

    void setA9Pin(const bool value) { a_pins[9] = value;; }
	bool getA9Pin() const { return a_pins[9]; }

    void setA10Pin(const bool value) { a_pins[10] = value; }
	bool getA10Pin() const { return a_pins[10]; }

    void setA11Pin(const bool value) { a_pins[11] = value; }
	bool getA11Pin() const { return a_pins[11]; }

    void setA12Pin(const bool value) { a_pins[12] = value; }
	bool getA12Pin() const { return a_pins[12]; }

    void setA13Pin(const bool value) { a_pins[13] = value; }
	bool getA13Pin() const { return a_pins[13]; }

    void setA14Pin(const bool value) { a_pins[14] = value; }
	bool getA14Pin() const { return a_pins[14]; }

    void setA15Pin(const bool value) { a_pins[15] = value; }
	bool getA15Pin() const { return a_pins[15]; }

    void setA16Pin(const bool value) { a_pins[16] = value; }
	bool getA16Pin() const { return a_pins[16]; }

    void setA17Pin(const bool value) { a_pins[17] = value; }
	bool getA17Pin() const { return a_pins[17]; }

    void setA18Pin(const bool value) { a_pins[18] = value; }
	bool getA18Pin() const { return a_pins[18]; }

    void setA19Pin(const bool value) { a_pins[19] = value; }
	bool getA19Pin() const { return a_pins[19]; }

    void setAPins(__int32 value) {
        setA0Pin(isActiveBitByIdx(value, 0));
        setA1Pin(isActiveBitByIdx(value, 1));
        setA2Pin(isActiveBitByIdx(value, 2));
        setA3Pin(isActiveBitByIdx(value, 3));
        setA4Pin(isActiveBitByIdx(value, 4));
        setA5Pin(isActiveBitByIdx(value, 5));
        setA6Pin(isActiveBitByIdx(value, 6));
        setA7Pin(isActiveBitByIdx(value, 7));
        setA8Pin(isActiveBitByIdx(value, 8));
        setA9Pin(isActiveBitByIdx(value, 9));
        setA10Pin(isActiveBitByIdx(value, 10));
        setA11Pin(isActiveBitByIdx(value, 11));
        setA12Pin(isActiveBitByIdx(value, 12));
        setA13Pin(isActiveBitByIdx(value, 13));
        setA14Pin(isActiveBitByIdx(value, 14));
        setA15Pin(isActiveBitByIdx(value, 15));
        setA16Pin(isActiveBitByIdx(value, 16));
        setA17Pin(isActiveBitByIdx(value, 17));
        setA18Pin(isActiveBitByIdx(value, 18));
        setA19Pin(isActiveBitByIdx(value, 19));
    }
	
	bool outputDisabled[29] = {false}; //wtf
	bool getPinOutputDisabled(int index) { return outputDisabled[index]; }
	void setPinOutputDisabled(int index, bool value) { outputDisabled[index] = value; }

    void setOutputEnabledA(bool enabled) {
        outputDisabled[14] = !enabled;
        outputDisabled[13] = !enabled;
        outputDisabled[12] = !enabled;
        outputDisabled[11] = !enabled;
        outputDisabled[10] = !enabled;
        outputDisabled[9] = !enabled;
        outputDisabled[8] = !enabled;
        outputDisabled[7] = !enabled;
        outputDisabled[6] = !enabled;
        outputDisabled[5] = !enabled;
        outputDisabled[4] = !enabled;
        outputDisabled[3] = !enabled;
        outputDisabled[2] = !enabled;
        outputDisabled[1] = !enabled;
        outputDisabled[0] = !enabled;
        outputDisabled[28] = !enabled;
        outputDisabled[27] = !enabled;
        outputDisabled[26] = !enabled;
        outputDisabled[25] = !enabled;
        outputDisabled[24] = !enabled;
    }
	
	//D0-D7 are actually A0-A7

    void setD0Pin(bool value) { a_pins[0] = value; }

    void setD1Pin(bool value) { a_pins[1] = value; }

    void setD2Pin(bool value) { a_pins[2] = value; }

    void setD3Pin(bool value) { a_pins[3] = value; }

    void setD4Pin(bool value) { a_pins[4] = value; }

    void setD5Pin(bool value) { a_pins[5] = value; }

    void setD6Pin(bool value) { a_pins[6] = value; }

    void setD7Pin(bool value) { a_pins[7] = value; }

	void setDPins(int value) {
		setD0Pin(isActiveBitByIdx(value, 0));
		setD1Pin(isActiveBitByIdx(value, 1));
		setD2Pin(isActiveBitByIdx(value, 2));
		setD3Pin(isActiveBitByIdx(value, 3));
		setD4Pin(isActiveBitByIdx(value, 4));
		setD5Pin(isActiveBitByIdx(value, 5));
		setD6Pin(isActiveBitByIdx(value, 6));
		setD7Pin(isActiveBitByIdx(value, 7));
	}

    void setOutputEnabledD(bool enabled) {
        outputDisabled[7] = !enabled;
        outputDisabled[8] = !enabled;
        outputDisabled[9] = !enabled;
        outputDisabled[10] = !enabled;
        outputDisabled[11] = !enabled;
        outputDisabled[12] = !enabled;
        outputDisabled[13] = !enabled;
        outputDisabled[14] = !enabled;
    }

    void setDPins(byte value) {
        setDPins((int) value);
    }

    bool getD0Pin() { return a_pins[0]; }

    bool getD1Pin() { return a_pins[1]; }

    bool getD2Pin() { return a_pins[2]; }

    bool getD3Pin() { return a_pins[3]; }

    bool getD4Pin() { return a_pins[4]; }

    bool getD5Pin() { return a_pins[5]; }

    bool getD6Pin() { return a_pins[6]; }

    bool getD7Pin() { return a_pins[7]; }

    byte getDPins() {
        int D;
        setBitByIdx(&D, 0, getD0Pin());
        setBitByIdx(&D, 1, getD1Pin());
        setBitByIdx(&D, 2, getD2Pin());
        setBitByIdx(&D, 3, getD3Pin());
        setBitByIdx(&D, 4, getD4Pin());
        setBitByIdx(&D, 5, getD5Pin());
        setBitByIdx(&D, 6, getD6Pin());
        setBitByIdx(&D, 7, getD7Pin());
        return (byte) D;
    }

    // end of pins section

    // BIU
    PrefetchQueue prefetchQueue;
    TState currTState;
    BIUAction currBIUAction;
    word BIUAddress;
    word BIUPrefetchQueueAddress;
    SegmentRegister BIUReg; // segment reg for address computation
    word getBIURegValue() {
        switch (BIUReg) {
			case SegmentRegister::CS: return cs;
			case SegmentRegister::DS: return ds;
			case SegmentRegister::SS: return ss;
            case SegmentRegister::ES: return es;
            case SegmentRegister::SEGMENT_00: return (word) 0;
        }
    }
	byte BIUDataOut;
	byte BIUDataIn;
    bool BIUDoCycle;
    bool BIUDoOpcodeFetchCycle;
    bool BIUCycleFinished;
    bool BIUOpcodeFetchCycleFinished;
    void BIU_cycle();

    byte BIURequiredByteLow;
    byte BIURequiredByteHigh;
    word BIURequiredWord() { return concatenateBytes(BIURequiredByteLow, BIURequiredByteHigh); }

    int BIUOperationByte;
    /**
     * @return true, if operation completed, else - start operation and return false
     */
    bool BIURequireOperationByte(BIUAction action, SegmentRegister reg, word address, word writeData) {
        if (!BIUDoCycle && !BIUCycleFinished) {
            BIUStartOperation(action, reg, address, writeData);
            return false;
        }

        if (BIUCycleFinished) {
            BIURequiredByteLow = BIUDataIn;
            BIUCycleFinished = false;
            return true;
        }
    }

    /**
     * @return true, if operation completed, else - start operation and return false
     */
    bool BIURequireOperationWord(BIUAction action, SegmentRegister reg, word address, word writeData) {
        // operation with low byte
        if (BIUOperationByte == 0) {
            if (!BIUDoCycle && !BIUCycleFinished) {
                BIUStartOperation(action, reg, address, writeData);
                return false;
            }

            if (BIUCycleFinished) {
                BIURequiredByteLow = BIUDataIn;
                BIUCycleFinished = false;
                BIUOperationByte = 1;
            }
        }

        // operation with high byte
        if (BIUOperationByte == 1) {
            if (!BIUDoCycle && !BIUCycleFinished) {
                BIUStartOperation(action, reg, address + 1, writeData >> 8);
                return false;
            }

            if (BIUCycleFinished) {
                BIURequiredByteHigh = BIUDataIn;
                BIUCycleFinished = false;
                BIUOperationByte = 0;
            }
        }

        return true;
    }

    void BIUStartOperation(BIUAction action, SegmentRegister reg, word address, word writeData) {
        currBIUAction = action;
        BIUReg = reg;
        BIUAddress = address;
        BIUDataOut = writeData;

        BIUDoCycle = true;
    }

	void BIUAddPrefetchQueueByte() {
		if (prefetchQueue.full()) return;

		BIUDoCycle = true;
		BIUDoOpcodeFetchCycle = true;
        currBIUAction = BIUAction::MR;
    }

    /**
     * @return true, if byte is available, else - start BIU for fetch byte and return false
     */
    bool BIURequirePrefetchQueueByte() {
		if (!BIUOpcodeFetchCycleFinished && prefetchQueue.empty()) {
			BIUAddPrefetchQueueByte();
            return false;
        }

		// else, byte is available
		bool finished = BIUOpcodeFetchCycleFinished || (!prefetchQueue.empty() && !BIUDoOpcodeFetchCycle);
		BIUOpcodeFetchCycleFinished = false;
		return finished;
    }

    /**
     * @return true, if word is available, else - start BIU for fetch byte and return false
     */
    bool BIURequirePrefetchQueueWord() {
		if (!BIUOpcodeFetchCycleFinished && prefetchQueue.size() < 2) {
            BIUAddPrefetchQueueByte();
            return false;
        }

        // else, bytes are available
        bool finished = BIUOpcodeFetchCycleFinished || (!prefetchQueue.empty() && !BIUDoOpcodeFetchCycle);
		BIUOpcodeFetchCycleFinished = false;
		return finished;
    }

    /**
     * @return true, if dword (4 bytes) is available, else - start BIU for fetch byte and return false
     */
    bool BIURequirePrefetchQueueDWord() {
		if (prefetchQueue.size() < 4) {
			BIUAddPrefetchQueueByte();
            return false;
        }

        // else, bytes are available
        bool finished = BIUOpcodeFetchCycleFinished || (!prefetchQueue.empty() && !BIUDoOpcodeFetchCycle);
		BIUOpcodeFetchCycleFinished = false;
		return finished;
    }
    // end of BIU

    int waitClocksCount;
    bool isResetState;

    // EU
    EUSTate euState;
    int pushState, popState;
    int jumpState;
	byte opcodeByte = (byte) 0; // opcode, d, w
    bool forceWordOperation;
    bool isWordOperation() { return (0x01 & opcodeByte) || forceWordOperation; } // isolate word/byte bit from opcode byte
	byte addressingModeByte = (byte) 0; // MOD, REG, R/M
	byte getREGField() { return (0x38 & addressingModeByte) >> 3; } // REG
	byte getMODField() { return addressingModeByte >> 6; } // MOD
	byte getRMField() { return 0x07 & addressingModeByte; } // R/M
	byte getREGFieldTable() { return isWordOperation() << 3 | getREGField(); } // Concatenate W and MOD=11 register field bits
	byte getRMFieldTable() { return isWordOperation() << 3 | getRMField(); } // Concatenate W and R/M register field bits
	byte dispByteLow; // or direct address low
	byte dispByteHigh; // or direct address high
    word getDispWord() { return concatenateBytes(dispByteLow, dispByteHigh); }
	byte dataByteLow;
	byte dataByteHigh;
    word getDataWord() { return concatenateBytes(dataByteLow, dataByteHigh); }
	bool dispOrAddressByteLowFetched;
    bool dispOrAddressByteHighFetched;
    bool dataHighFetched;
    bool dataLowFetched;
    bool effectiveAddressIsRegister;
	SegmentRegister effectiveAddressSegment;
	bool segmentRegSpecified = false;
    unsigned __int16 effectiveAddress;
    bool doCalculateEffectiveAddress;
    bool effectiveAddressCalculationFinished;
    EffectiveAddressState effectiveAddressState;
    EffectiveAddressWriteBackState effectiveAddressWritebackState;
    bool effectiveAddressWriteBackFinished;

    /**
     * @return true, if write finished, else - false
     */
    bool writeBackEffectiveAddress(word data) {
        effectiveAddressWriteBackFinished = false;

        if (effectiveAddressIsRegister) {
            // write to register
            writeRegister((Register) getRMFieldTable(), data);
            effectiveAddressWriteBackFinished = true;
            return true;
		} else if (!isWordOperation()) {
            if (!BIURequireOperationByte(BIUAction::MW, effectiveAddressSegment, effectiveAddress, data))
                return false;

            effectiveAddressWriteBackFinished = true;
            return true;

        } else if (isWordOperation()) {

            if (!BIURequireOperationWord(BIUAction::MW, effectiveAddressSegment, effectiveAddress, data))
                return false;

            effectiveAddressWriteBackFinished = true;
            return true;
        }
    }

    word effectiveAddressFetchedData;
    bool effectiveAddressFetchDataFinished;
    EffectiveAddressFetchDataState effectiveAddressFetchDataState;

    /**
     * @return true, if data fetched, else - false
     */
    bool fetchDataOnEffectiveAddress() {
        effectiveAddressFetchDataFinished = false;

        if (effectiveAddressIsRegister) {
            effectiveAddressFetchedData = fetchRegister((Register) getRMFieldTable());
            effectiveAddressFetchDataFinished = true;
            return true;
		} else if (!isWordOperation()) {
            if (!BIURequireOperationByte(BIUAction::MR, effectiveAddressSegment, effectiveAddress, 0))
                return false;

            effectiveAddressFetchDataFinished = true;
            effectiveAddressFetchedData = BIURequiredByteLow;
            return true;

        } else if (isWordOperation()) {
            if (!BIURequireOperationWord(BIUAction::MR, effectiveAddressSegment, effectiveAddress, 0))
                return false;

            effectiveAddressFetchDataFinished = true;
            effectiveAddressFetchedData = BIURequiredByteLow; // low byte
            effectiveAddressFetchedData = effectiveAddressFetchedData | ( ((word) BIURequiredByteHigh) << 8); // high byte
            return true;
        }
    }

    word fetchedRegister;
    word fetchRegister(Register regSel) {
        word result;
        switch (regSel) {
            case Register::AL: result = 0x00FF & ax; break; // AL
            case Register::CL: result = 0x00FF & cx; break; // CL
            case Register::DL: result = 0x00FF & dx; break; // DL
            case Register::BL: result = 0x00FF & bx; break; // BL
            case Register::AH: result = ax >> 8; break; // AH
            case Register::CH: result = cx >> 8; break; // CH
            case Register::DH: result = dx >> 8; break; // DH
            case Register::BH: result = bx >> 8; break; // BH
            case Register::AX: result = ax; break; // AX
            case Register::CX: result = cx; break; // CX
            case Register::DX: result = dx; break; // DX
            case Register::BX: result = bx; break; // BX
            case Register::SP: result = sp; break; // SP
            case Register::BP: result = bp; break; // BP
            case Register::SI: result = si; break; // SI
            case Register::DI: result = di; break; // DI
        }

        fetchedRegister = result;
        return result;
    }

    void writeRegister(Register regSel, word data) {
        switch (regSel) {
            case Register::AL: ax = (0xFF00 & ax) | (data & 0xFF); break; // AL
            case Register::CL: cx = (0xFF00 & cx) | (data & 0xFF); break; // CL
            case Register::DL: dx = (0xFF00 & dx) | (data & 0xFF); break; // DL
            case Register::BL: bx = (0xFF00 & bx) | (data & 0xFF); break; // BL
            case Register::AH: ax = (0x00FF & ax) | (data << 8); break; // AH
            case Register::CH: cx = (0x00FF & cx) | (data << 8); break; // CH
            case Register::DH: dx = (0x00FF & dx) | (data << 8); break; // DH
            case Register::BH: bx = (0x00FF & bx) | (data << 8); break; // BH
            case Register::AX: ax = data; break; // AX
            case Register::CX: cx = data; break; // CX
            case Register::DX: dx = data; break; // DX
            case Register::BX: bx = data; break; // BX
            case Register::SP: sp = data; break; // SP
            case Register::BP: bp = data; break; // BP
            case Register::SI: si = data; break; // SI
            case Register::DI: di = data; break; // DI
        }
    }

    void writeSegmentRegister(SegmentRegister regSel, word data) {
        switch (regSel) {
            case SegmentRegister::ES: es = data; break; // ES
            case SegmentRegister::CS: cs = data; break; // CS
            case SegmentRegister::SS: ss = data; break; // SS
            case SegmentRegister::DS: ds = data; break; // DS
        }
    }

    word fetchSegmentRegister(SegmentRegister regSel) {
        switch (regSel) {
            case SegmentRegister::ES: return es; // ES
            case SegmentRegister::CS: return cs; // CS
            case SegmentRegister::SS: return ss; // SS
            case SegmentRegister::DS: return ds; // DS
            case SegmentRegister::SEGMENT_00: return 0; // absolute memory (for interrupt addresses)
        }

        // unachievable case
        return 0;
    }

    void EU_calculateEffectiveAddress();
    /**
     * @return true, if effective address calculation is completed, else - start calculation and return false
     */
    bool requireEffectiveAddressCalculation() {
        if (effectiveAddressCalculationFinished) {
            effectiveAddressCalculationFinished = false;
            return true;
        }

        doCalculateEffectiveAddress = true;
        return false;
    }

    void EU_cycle();
    // end of EU

    word signExtendedByte(word d) { return (0x0080 & d) != 0 ? 0xFF00 | d : 0x00FF & d; }
    word concatenateBytes(byte low, byte high) { return ((word) low) | (((word) high) << 8); }

    void reset();

    bool isClkFront() {
        return !prevClock && getClockPin();
    }

    bool isClkBack() {
        return prevClock && !getClockPin();
    }

    void Perform_work();

    void init() {
        prevClock = 1;

        setALEPin(0);
        setWRPin(1);
        setRDPin(1);
        setDENPin(1);

        setOutputEnabledA(false);
        setOutputEnabledD(false);

        ip = DEFAULT_IP;
        BIUPrefetchQueueAddress = ip;
        cs = DEFAULT_CS;
        ds = DEFAULT_DS;
        ss = DEFAULT_SS;
        es = DEFAULT_ES;

        flags = DEFAULT_FLAGS;

        currTState = TState::T1;

        BIUCycleFinished = false;
        BIUOpcodeFetchCycleFinished = false;
        BIUDoCycle = false;
		BIUDoOpcodeFetchCycle = false;
        BIUOperationByte = 0;
		euState = EUSTate::OPCODE_FETCH;
        doCalculateEffectiveAddress = false;
        effectiveAddressFetchDataState = EffectiveAddressFetchDataState::FETCH_LOW;
        effectiveAddressWritebackState = EffectiveAddressWriteBackState::WRITE_LOW;
        effectiveAddressState = EffectiveAddressState::FETCH_MOD_REG_RM_BYTE;
    }

    bool interrupted = false;

    bool div0InterruptHandler() {
        if (!interrupted) {
            waitClocksCount += 1;
            interruptState = 0;
            throw std::logic_error("Возникло прерывание: деление на ноль!");
            interrupted = true;
        }

        return interruptHandler(0); // division by zero interrupt
    }

    bool trapInterruptHandler() {
        if (!interrupted) {
            waitClocksCount += 1;
            interruptState = 0;
            throw std::logic_error("Возникло прерывание: TRAP!");
            interrupted = true;
        }

        return interruptHandler(1); // trap interrupt
    }

    int interruptState = 0;
    bool interruptHandler(byte interruptType) {
        if (interruptState == 0) {
            waitClocksCount += 71;
            interruptState = 1;
            pushState = 0;
        }

        if (interruptState == 1) {
            if (!push(flags | 0xF000, 14)) return false;
            setFlagTrace(0);
            setFlagInterrupt(0);
            pushState = 0;
            interruptState = 2;
        }

        if (interruptState == 2) {
            if (!push(cs, 14)) return false;
            pushState = 0;
            interruptState = 3;
        }

        if (interruptState == 3) {
            if (!BIURequireOperationWord(BIUAction::MR, SegmentRegister::SEGMENT_00, (interruptType << 2) + 2, 0))
                return false;
            cs = BIURequiredWord();
            interruptState = 4;
        }

        if (interruptState == 4) {
            if (!push(ip, 0)) return false;
            pushState = 0;
            interruptState = 5;
        }

        if (interruptState == 5) {
            if (!BIURequireOperationWord(BIUAction::MR, SegmentRegister::SEGMENT_00, (interruptType << 2), 0))
                return false;
            ip = BIURequiredWord();
            prefetchQueue.reset();
            BIUPrefetchQueueAddress = ip;
            opcodeState++;
        }

        return true;
    }


    int opcodeState;
    word opcodeResult; // result in operation in opcode_xxx function

    /////////////
    // opcodes //

    // ==========
    // math (ADD, ADC, SBB, SUB, CMP, INC, DEC)

    byte addBytes(byte data1, byte data2, bool withCarry = false, bool inc = false);
    word addWords(word data1, word data2, bool withCarry = false, bool inc = false);

    byte subBytes(byte data1, byte data2, bool withCarry = false, bool dec = false);
    word subWords(word data1, word data2, bool withCarry = false, bool dec = false);
    /**
     * ADD R/M8, R8
     */
    bool opcode_0x00();
    /**
     * ADD R/M16, R16
     */
	bool opcode_0x01();
	/**
	 * ADD R8, R/M8
	 */
	bool opcode_0x02();
	/**
	 * ADD R16, R/M16
	 */
	bool opcode_0x03();
	/**
	 * ADD AL, immediate8
	 */
	bool opcode_0x04();
    /**
     * ADD AX, immediate16
     */
    bool opcode_0x05();

    /**
     * ADC R/M8, R8
     */
    bool opcode_0x10();
    /**
     * ADC R/M16, R16
     */
    bool opcode_0x11();
    /**
     * ADC R8, R/M8
     */
    bool opcode_0x12();
    /**
     * ADC R16, R/M16
     */
    bool opcode_0x13();
    /**
     * ADC AL, immediate8
     */
    bool opcode_0x14();
    /**
     * ADC AX, immediate16
     */
    bool opcode_0x15();

    /**
     * SBB R/M8, R8
     */
    bool opcode_0x18();
    /**
     * SBB R/M16, R16
     */
    bool opcode_0x19();
    /**
     * SBB R8, R/M8
     */
    bool opcode_0x1A();
    /**
     * SBB R16, R/M16
     */
    bool opcode_0x1B();
    /**
     * SBB AL, immediate8
     */
    bool opcode_0x1C();
    /**
     * SBB AX, immediate16
     */
    bool opcode_0x1D();

    /**
     * SUB R/M8, R8
     */
    bool opcode_0x28();
    /**
     * SUB R/M16, R16
     */
    bool opcode_0x29();
    /**
     * SUB R8, R/M8
     */
    bool opcode_0x2A();
    /**
     * SUB R16, R/M16
     */
    bool opcode_0x2B();
    /**
     * SUB AL, immediate8
     */
    bool opcode_0x2C();
    /**
     * SUB AX, immediate16
     */
    bool opcode_0x2D();

    /**
     * CMP R/M8, R8
     */
    bool opcode_0x38();
    /**
     * CMP R/M16, R16
     */
    bool opcode_0x39();
    /**
     * CMP R8, R/M8
     */
    bool opcode_0x3A();
    /**
     * CMP R16, R/M16
     */
    bool opcode_0x3B();
    /**
     * CMP AL, immediate8
     */
    bool opcode_0x3C();
    /**
     * CMP AX, immediate16
     */
    bool opcode_0x3D();

    /**
     * INC AX
     */
    bool opcode_0x40();
    /**
     * INC CX
     */
    bool opcode_0x41();
    /**
     * INC DX
     */
    bool opcode_0x42();
    /**
     * INC BX
     */
    bool opcode_0x43();
    /**
     * INC SP
     */
    bool opcode_0x44();
    /**
     * INC BP
     */
    bool opcode_0x45();
    /**
     * INC SI
     */
    bool opcode_0x46();
    /**
     * INC DI
     */
    bool opcode_0x47();

    /**
     * DEC AX
     */
    bool opcode_0x48();
    /**
     * DEC CX
     */
    bool opcode_0x49();
    /**
     * DEC DX
     */
    bool opcode_0x4A();
    /**
     * DEC BX
     */
    bool opcode_0x4B();
    /**
     * DEC SP
     */
    bool opcode_0x4C();
    /**
     * DEC BP
     */
    bool opcode_0x4D();
    /**
     * DEC SI
     */
    bool opcode_0x4E();
    /**
     * DEC DI
     */
    bool opcode_0x4F();

    /**
     * DAA
     */
    bool opcode_0x27();
    /**
     * DAS
     */
    bool opcode_0x2F();
    /**
     * AAA
     */
    bool opcode_0x37();
    /**
     * AAS
     */
    bool opcode_0x3F();
    /**
     * AAM
     */
    bool opcode_0xD4();
    /**
     * AAD
     */
    bool opcode_0xD5();

    // ==========
    // logical (OR, AND, XOR)

    word booleanOr(word data1, word data2);
    word booleanAnd(word data1, word data2);
    word booleanXor(word data1, word data2);
    byte rolByte(byte data, byte count);
    word rolWord(word data, byte count);
    byte rorByte(byte data, byte count);
    word rorWord(word data, byte count);
    byte rclByte(byte data, byte count);
    word rclWord(word data, byte count);
    byte rcrByte(byte data, byte count);
    word rcrWord(word data, byte count);
    byte salByte(byte data, byte count);
    word salWord(word data, byte count);
    byte shrByte(byte data, byte count);
    word shrWord(word data, byte count);
    byte sarByte(byte data, byte count);
    word sarWord(word data, byte count);

    /**
     * OR R/M8, R8
     */
    bool opcode_0x08();
    /**
     * OR R/M16, R16
     */
    bool opcode_0x09();
    /**
     * OR R8, R/M8
     */
    bool opcode_0x0A();
    /**
     * OR R16, R/M16
     */
    bool opcode_0x0B();
    /**
     * OR AL, immediate8
     */
    bool opcode_0x0C();
    /**
     * OR AX, immediate16
     */
    bool opcode_0x0D();

    /**
     * AND R/M8, R8
     */
    bool opcode_0x20();
    /**
     * AND R/M16, R16
     */
    bool opcode_0x21();
    /**
     * AND R8, R/M8
     */
    bool opcode_0x22();
    /**
     * AND R16, R/M16
     */
    bool opcode_0x23();
    /**
     * AND AL, immediate8
     */
    bool opcode_0x24();
    /**
     * AND AX, immediate16
     */
    bool opcode_0x25();

    /**
     * XOR R/M8, R8
     */
    bool opcode_0x30();
    /**
     * XOR R/M16, R16
     */
    bool opcode_0x31();
    /**
     * XOR R8, R/M8
     */
    bool opcode_0x32();
    /**
     * XOR R16, R/M16
     */
    bool opcode_0x33();
    /**
     * XOR AL, immediate8
     */
    bool opcode_0x34();
    /**
     * XOR AX, immediate16
     */
    bool opcode_0x35();

    /**
     * Shifts R/M8, 1
     */
    bool opcode_0xD0();
    /**
     * Shifts R/M16, 1
     */
    bool opcode_0xD1();
    /**
     * Shifts R/M8, CL
     */
    bool opcode_0xD2();
    /**
     * Shifts R/M16, CL
     */
    bool opcode_0xD3();

    // ==========
    // movements (PUSH, POP, MOV)

    bool push(word data, int clocks);
    bool pop(int clocks);

    /**
     * PUSH ES
     */
    bool opcode_0x06();
    /**
     * PUSH CS
     */
    bool opcode_0x0E();
    /**
     * PUSH SS
     */
    bool opcode_0x16();
    /**
     * PUSH DS
     */
    bool opcode_0x1E();
    /**
     * PUSHF - Push Flags
     */
    bool opcode_0x9C();

    /**
     * PUSH AX
     */
    bool opcode_0x50();
    /**
     * PUSH CX
     */
    bool opcode_0x51();
    /**
     * PUSH DX
     */
    bool opcode_0x52();
    /**
     * PUSH BX
     */
    bool opcode_0x53();
    /**
     * PUSH SP (new)
     */
    bool opcode_0x54();
    /**
     * PUSH BP
     */
    bool opcode_0x55();
    /**
     * PUSH SI
     */
    bool opcode_0x56();
    /**
     * PUSH DI
     */
    bool opcode_0x57();

    /**
     * POP ES
     */
    bool opcode_0x07();
    /**
     * POP CS
     */
    bool opcode_0x0F();
    /**
     * POP SS
     */
    bool opcode_0x17();
    /**
     * POP DS
     */
    bool opcode_0x1F();
    /**
     * POPF - Pop Flags
     */
    bool opcode_0x9D();

    /**
     * POP AX
     */
    bool opcode_0x58();
    /**
     * POP CX
     */
    bool opcode_0x59();
    /**
     * POP DX
     */
    bool opcode_0x5A();
    /**
     * POP BX
     */
    bool opcode_0x5B();
    /**
     * POP SP
     */
    bool opcode_0x5C();
    /**
     * POP BP
     */
    bool opcode_0x5D();
    /**
     * POP SI
     */
    bool opcode_0x5E();
    /**
     * POP DI
     */
    bool opcode_0x5F();
    /**
     * POP R/M16
     */
    bool opcode_0x8F();


    bool movImmediateByteToReg(Register reg);
    bool movImmediateWordToReg(Register reg);
    /**
     * MOV AL, immediate8
     */
    bool opcode_0xB0();
    /**
     * MOV CL, immediate8
     */
    bool opcode_0xB1();
    /**
     * MOV DL, immediate8
     */
    bool opcode_0xB2();
    /**
     * MOV BL, immediate8
     */
    bool opcode_0xB3();
    /**
     * MOV AH, immediate8
     */
    bool opcode_0xB4();
    /**
     * MOV CH, immediate8
     */
    bool opcode_0xB5();
    /**
     * MOV DH, immediate8
     */
    bool opcode_0xB6();
    /**
     * MOV BH, immediate8
     */
    bool opcode_0xB7();
    /**
     * MOV AX, immediate16
     */
    bool opcode_0xB8();
    /**
     * MOV CX, immediate16
     */
    bool opcode_0xB9();
    /**
     * MOV DX, immediate16
     */
    bool opcode_0xBA();
    /**
     * MOV BX, immediate16
     */
    bool opcode_0xBB();
    /**
     * MOV SP, immediate16
     */
    bool opcode_0xBC();
    /**
     * MOV BP, immediate16
     */
    bool opcode_0xBD();
    /**
     * MOV SI, immediate16
     */
    bool opcode_0xBE();
    /**
     * MOV DI, immediate16
     */
    bool opcode_0xBF();

    /**
     * MOV R/M8, R8
     */
    bool opcode_0x88();
    /**
     * MOV R/M16, R16
     */
    bool opcode_0x89();
    /**
     * MOV R8, R/M8
     */
    bool opcode_0x8A();
    /**
     * MOV R16, R/M16
     */
    bool opcode_0x8B();
    /**
     * MOV R/M16, SEGREG
     */
    bool opcode_0x8C();
    /**
     * MOV SEGREG, R/M16
     */
    bool opcode_0x8E();

    /**
     * MOV AL, M8
     */
    bool opcode_0xA0();
    /**
     * MOV AX, M16
     */
    bool opcode_0xA1();
    /**
     * MOV M8, AL
     */
    bool opcode_0xA2();
    /**
     * MOV M16, AX
     */
    bool opcode_0xA3();

    /**
     * MOV M8, immediate8
     */
    bool opcode_0xC6();
    /**
     * MOV M16, immediate16
     */
    bool opcode_0xC7();

    // ==========
    // jumps (JO, JNO, JB, JNB, JZ, JNZ, JNA, JA, JS, JNS, JP, JNP, JL, JLE, JNLE, JCXZ, CALL, RET)

    bool jumpNotTakenByte();
    bool jumpTakenByte();

    bool jumpTakenWord();
    bool jumpTakenDWord();

    /**
     * JO disp8
     */
    bool opcode_0x70();
    /**
     * JNO disp8
     */
    bool opcode_0x71();
    /**
     * JB disp8
     */
    bool opcode_0x72();
    /**
     * JNB disp8
     */
    bool opcode_0x73();
    /**
     * JZ disp8
     */
    bool opcode_0x74();
    /**
     * JNZ disp8
     */
    bool opcode_0x75();
    /**
     * JNA disp8
     */
    bool opcode_0x76();
    /**
     * JA disp8
     */
    bool opcode_0x77();
    /**
     * JS disp8
     */
    bool opcode_0x78();
    /**
     * JNS disp8
     */
    bool opcode_0x79();
    /**
     * JP disp8
     */
    bool opcode_0x7A();
    /**
     * JNP disp8
     */
    bool opcode_0x7B();
    /**
     * JL disp8
     */
    bool opcode_0x7C();
    /**
     * JNL disp8
     */
    bool opcode_0x7D();
    /**
     * JLE disp8
     */
    bool opcode_0x7E();
    /**
     * JNLE disp8
     */
    bool opcode_0x7F();

    /**
     * JCXZ disp8
     */
    bool opcode_0xE3();

    /**
     * JMP disp8
     */
    bool opcode_0xEB();
    /**
     * JMP disp16
     */
    bool opcode_0xE9();
    /**
     * JMP intersegment
     */
    bool opcode_0xEA();

    /**
     * CALL intrasegment
     */
    bool opcode_0xE8();
    /**
     * CALL intersegment
     */
    bool opcode_0x9A();

    /**
     * RET intrasegment
     */
    bool opcode_0xC3();
    /**
     * RET intersegment
     */
    bool opcode_0xCB();
    /**
     * RET intrasegment, add immediate16 to SP
     */
    bool opcode_0xC2();
    /**
     * RET intersegment, add immediate16 to SP
     */
    bool opcode_0xCA();

    /**
     * LOOPNZ
     */
    bool opcode_0xE0();
    /**
     * LOOPZ
     */
    bool opcode_0xE1();
    /**
     * LOOP
     */
    bool opcode_0xE2();

    /**
     * XCHG R8, R/M8
     */
    bool opcode_0x86();
    /**
     * XCHG R16, R/M16
     */
    bool opcode_0x87();
    /**
     * XCHG AX, CX
     */
    bool opcode_0x91();
    /**
     * XCHG AX, DX
     */
    bool opcode_0x92();
    /**
     * XCHG AX, BX
     */
    bool opcode_0x93();
    /**
     * XCHG AX, SP
     */
    bool opcode_0x94();
    /**
     * XCHG AX, BP
     */
    bool opcode_0x95();
    /**
     * XCHG AX, SI
     */
    bool opcode_0x96();
    /**
     * XCHG AX, DI
     */
    bool opcode_0x97();

    /**
     * LEA R16, M16
     */
    bool opcode_0x8D();
    /**
     * LES R16, M16
     */
    bool opcode_0xC4();
    /**
     * LDS R16, M16
     */
    bool opcode_0xC5();

    //////////////
    // flags

    /**
     * NOP
     */
    bool opcode_0x90();
    /**
     * ESC data8
     */
    bool opcode_0xD8();

    /**
     * SETALC
     */
    bool opcode_0xD6();

    /**
     * CLC (Clear carry flag)
     */
    bool opcode_0xF8();
    /**
     * CMC (Complement carry flag)
     */
    bool opcode_0xF5();
    /**
     * STC (Set carry flag)
     */
    bool opcode_0xF9();
    /**
     * CLD (Clear direction flag)
     */
    bool opcode_0xFC();
    /**
     * STD (Set direction flag)
     */
    bool opcode_0xFD();
    /**
     * CLI (Clear interrupt flag)
     */
    bool opcode_0xFA();
    /**
     * STI (Set interrupt flag)
     */
    bool opcode_0xFB();

    /**
     * LAHF - Load 8080 flags into AH register
     */
    bool opcode_0x9F();
    /**
     * SAHF - Store AH register into 8080 flags
     */
    bool opcode_0x9E();

    /**
     * CBW - Sign extend AL Register into AH Register
     */
    bool opcode_0x98();
    /**
     * CWD - Sign extend AX Register into DX Register
     */
    bool opcode_0x99();


    // Extended opcodes

    /**
     * OP R/M8, immediate8 (duplicates 0x82)
     */
    bool opcode_0x80();
    /**
     * OP R/M16, immediate16
     */
    bool opcode_0x81();
    /**
     * OP R/M16, sign extended immediate8
     */
    bool opcode_0x83();

    /**
     * OP (NOT, NEG, TEST, DIV, IDIV, MUL, IMUL) R/M8, immediate8
     */
    bool opcode_0xF6();
    /**
     * OP (NOT, NEG, TEST, DIV, IDIV, MUL, IMUL) R/M16, immediate16
     */
    bool opcode_0xF7();
    /**
     * OP (INC, DEC, CALL, JMP, PUSH)
     */
    bool opcode_0xFE();
    /**
     * OP (INC, DEC, CALL, JMP, PUSH)
     */
    bool opcode_0xFF();

    ////////////
    // Test   //

    /**
     * TEST AL, immediate8
     */
    bool opcode_0xA8();
    /**
     * TEST AX, immediate16
     */
    bool opcode_0xA9();
    /**
     * TEST R/M8, R8
     */
    bool opcode_0x84();
    /**
     * TEST R/M16, R16
     */
    bool opcode_0x85();

    ///////////////////
    // interrupts    //

    /**
     * INT (type 3 - breakpoint)
     */
    bool opcode_0xCC();
    /**
     * INTO (type 4 - on overflow)
     */
    bool opcode_0xCE();
    /**
     * INT immediate8
     */
    bool opcode_0xCD();
    /**
     * IRET
     */
    bool opcode_0xCF();

    // In / out
    /**
     * IN AL, DX
     */
    bool opcode_0xEC();
    /**
     * IN AL, immediate8
     */
    bool opcode_0xE4();
    /**
     * IN AX, DX
     */
    bool opcode_0xED();
    /**
     * IN AX, immediate8
     */
    bool opcode_0xE5();
    /**
     * OUT DX, AL
     */
    bool opcode_0xEE();
    /**
     * OUT DX, AX
     */
    bool opcode_0xEF();
    /**
     * OUT immediate8, AL
     */
    bool opcode_0xE6();
    /**
     * OUT immediate8, AX
     */
	bool opcode_0xE7();

	//prefix ES
	bool opcode_0x26();
	//prefix CS
	bool opcode_0x2E();
	//prefis SS
	bool opcode_0x36();
    //prefix DS
	bool opcode_0x3E();


	IProc_8088() : prefetchQueue(PREFETCH_QUEUE_8086_MAX_SIZE) {

        doCalculateEffectiveAddress = false;
        BIUDoCycle = false;
        BIUDoOpcodeFetchCycle = false;
        euState = EUSTate::OPCODE_FETCH;
        currTState = TState::T1;
        opcodeState = 0;
        jumpState = 0;
        popState = 0;
        pushState = 0;
        effectiveAddressFetchDataState = EffectiveAddressFetchDataState::FETCH_LOW;
        effectiveAddressWritebackState = EffectiveAddressWriteBackState::WRITE_LOW;
        effectiveAddressState = EffectiveAddressState::FETCH_MOD_REG_RM_BYTE;
        BIUOperationByte = 0;

        reset();
    };

    ~IProc_8088() {
		prefetchQueue.reset();
    }

};
}

/*
 * Not implemented opcodes:
 *  * HLT
 *  * XLAT
 *  * some opcode extensions
 *  * string opcodes
 */

/*
 * Not implemented features:
 * * NMI interruptions
 * * hardware interruptions
 * * maximum mode
 *
 */

#endif //TVBUILDER_IPROC_8088_H
