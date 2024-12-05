#pragma hdrstop

#include "IProc_8088.h"
//#include <Dialogs.hpp>
#include <set>

void IProc_8088::Perform_work() {

    // wait clk front/back to change mpu states
    if (!isClkFront() && !isClkBack()) {
        prevClock = getClockPin();
        return;
    }

    if (isClkFront() && getResetPin()) {
        reset();
        return;
    }

	if (waitClocksCount > 0) {
        if (isClkFront()) waitClocksCount--;
	}

	if (isResetState && waitClocksCount == 0) {
		isResetState = false;
        BIUAddPrefetchQueueByte();
	}

	if (!isResetState) {
		if ((waitClocksCount == 0) && !BIUDoCycle) { // prev !waitClocksCount
            EU_cycle();
        }

		if (doCalculateEffectiveAddress) {
            EU_calculateEffectiveAddress();
		}

        if (BIUDoCycle) {
			BIU_cycle();
		} else {
			BIUAddPrefetchQueueByte();
        }
    }

    prevClock = getClockPin();
}

void IProc_8088::reset() {
    isResetState = true;
    prefetchQueue.reset();
    init();
    waitClocksCount = 7;
}

void IProc_8088::BIU_cycle() {
    BIUCycleFinished = false;
    BIUOpcodeFetchCycleFinished = false;

    bool isWriteCycle = (currBIUAction == BIUAction::MW || currBIUAction == BIUAction::IOW);

    switch (currTState) {
        case TState::T1: {

            if (BIUDoOpcodeFetchCycle && prefetchQueue.full())
                return;

            // start of bus cycle. wait for clk fall
            if (!isClkBack()) return;

            // set IO/!M
            setIO_NMPin((currBIUAction == BIUAction::MW || currBIUAction == BIUAction::MR) ? 0 : 1); // 0 - BIU request to memory, 1 - to IO

            // set DT/!R
            setDT_NRPin(isWriteCycle);

            // set DEN - disable data
            setDENPin(1);
            setOutputEnabledD(false); // IT MUST BE BEFORE setOutputEnabledA(true)! due to override

            __int32 address = BIUDoOpcodeFetchCycle ? ((cs << 4) + BIUPrefetchQueueAddress) : (getBIURegValue() << 4) + BIUAddress;
            // set address
            setOutputEnabledA(true);
            setAPins(address);
            // set ALE
            setALEPin(1);


            currTState = TState::T15;
            return;
        }

        case TState::T15: {
            // T1 - clk rise
            if (!isClkFront()) return;
            currTState = TState::T2;
            return;
        }

        case TState::T2: {
            // at clk fall disable ALE, set DEN
            if (!isClkBack()) return;
            // disable ALE
            setALEPin(0);

            // set early DEN
            if (isWriteCycle) {
                setDENPin(0);
            }

            currTState = TState::T25;
            return;
        }

        case TState::T25: {
            // at clk rise - set RD or WR, DEN, (and if write cycle, set data)
            if (!isClkFront()) return;

            setOutputEnabledA(false);

            // set !WR
            setWRPin(!isWriteCycle);
            // set !RD
            setRDPin(isWriteCycle);

            if (isWriteCycle) {
                // set D for write for out
                setOutputEnabledD(true);
                setDPins(BIUDataOut);
            }

            // set DEN
            setDENPin(0);

            currTState = TState::T3;
            return;
        }

        case TState::T3: {
            // on clk fall - wait for READY signal
            if (!isClkBack()) return;

            if (!getReadyPin()) return;

			currTState = TState::T35;
            return;
        }

        case TState::T35: {
            // on clk rise - in case of read cycle - read data
            if (!isClkFront()) return;

            // on read
            if (!isWriteCycle) {
                BIUDataIn = getDPins();

                if (BIUDoOpcodeFetchCycle)
                    prefetchQueue.push(BIUDataIn);
            }

            currTState = TState::T4;
            return;
        }

        case TState::T4: {
            // on clk fall - clear signals
            if (!isClkBack()) return;

            // reset WR
            setWRPin(1);
            // reset RD
            setRDPin(1);
            // reset DEN
            setDENPin(1);
            setOutputEnabledD(false);

			if (BIUDoOpcodeFetchCycle) {
				BIUPrefetchQueueAddress++; // increase address pfq (IP)
                BIUOpcodeFetchCycleFinished = true;
			}

			if (!BIUDoOpcodeFetchCycle) { BIUCycleFinished = true; }
			BIUDoCycle = false;
            BIUDoOpcodeFetchCycle = false;


            currTState = TState::T1;
        }
    }
}

void IProc_8088::EU_cycle() {
    switch (euState) {
        case EUSTate::OPCODE_FETCH: {
            if (!BIURequirePrefetchQueueByte()) return;

            // take opcode from prefetch queue
            opcodeByte = prefetchQueue.pop();
            ip++;
            euState = EUSTate::INSTRUCTION_EXECUTION;
            opcodeState = 0;
            pushState = 0;
            popState = 0;
            jumpState = 0;
            forceWordOperation = false;
            effectiveAddressState = EffectiveAddressState::FETCH_MOD_REG_RM_BYTE;
            effectiveAddressCalculationFinished = false;
            // execute instruction
        }

        case EUSTate::INSTRUCTION_EXECUTION: {
            bool finished = false;
            switch (opcodeByte) {
                // 1. math
                // 1.1 ADD
                case 0x00: finished = opcode_0x00(); break;
                case 0x01: finished = opcode_0x01(); break;
                case 0x02: finished = opcode_0x02(); break;
                case 0x03: finished = opcode_0x03(); break;
                case 0x04: finished = opcode_0x04(); break;
                case 0x05: finished = opcode_0x05(); break;
                // 1.2 ADC
                case 0x10: finished = opcode_0x10(); break;
                case 0x11: finished = opcode_0x11(); break;
                case 0x12: finished = opcode_0x12(); break;
                case 0x13: finished = opcode_0x13(); break;
                case 0x14: finished = opcode_0x14(); break;
                case 0x15: finished = opcode_0x15(); break;
                // 1.3 SBB
                case 0x18: finished = opcode_0x18(); break;
                case 0x19: finished = opcode_0x19(); break;
                case 0x1A: finished = opcode_0x1A(); break;
                case 0x1B: finished = opcode_0x1B(); break;
                case 0x1C: finished = opcode_0x1C(); break;
                case 0x1D: finished = opcode_0x1D(); break;
                // 1.4 SUB
                case 0x28: finished = opcode_0x28(); break;
                case 0x29: finished = opcode_0x29(); break;
                case 0x2A: finished = opcode_0x2A(); break;
                case 0x2B: finished = opcode_0x2B(); break;
                case 0x2C: finished = opcode_0x2C(); break;
                case 0x2D: finished = opcode_0x2D(); break;
                // 1.5 CMP
                case 0x38: finished = opcode_0x38(); break;
                case 0x39: finished = opcode_0x39(); break;
                case 0x3A: finished = opcode_0x3A(); break;
                case 0x3B: finished = opcode_0x3B(); break;
                case 0x3C: finished = opcode_0x3C(); break;
                case 0x3D: finished = opcode_0x3D(); break;
                // 1.6 INC
                case 0x40: finished = opcode_0x40(); break;
                case 0x41: finished = opcode_0x41(); break;
                case 0x42: finished = opcode_0x42(); break;
                case 0x43: finished = opcode_0x43(); break;
                case 0x44: finished = opcode_0x44(); break;
                case 0x45: finished = opcode_0x45(); break;
                case 0x46: finished = opcode_0x46(); break;
                case 0x47: finished = opcode_0x47(); break;
                // 1.7 INC
                case 0x48: finished = opcode_0x48(); break;
                case 0x49: finished = opcode_0x49(); break;
                case 0x4A: finished = opcode_0x4A(); break;
                case 0x4B: finished = opcode_0x4B(); break;
                case 0x4C: finished = opcode_0x4C(); break;
                case 0x4D: finished = opcode_0x4D(); break;
                case 0x4E: finished = opcode_0x4E(); break;
                case 0x4F: finished = opcode_0x4F(); break;
                // 1.8 adjusts
                case 0x27: finished = opcode_0x27(); break;
                case 0x2F: finished = opcode_0x2F(); break;
                case 0x37: finished = opcode_0x37(); break;
                case 0x3F: finished = opcode_0x3F(); break;
                case 0xD4: finished = opcode_0xD4(); break;
                case 0xD5: finished = opcode_0xD5(); break;

                // 2. boolean - logical
                // 2.1 OR
                case 0x08: finished = opcode_0x08(); break;
                case 0x09: finished = opcode_0x09(); break;
                case 0x0A: finished = opcode_0x0A(); break;
                case 0x0B: finished = opcode_0x0B(); break;
                case 0x0C: finished = opcode_0x0C(); break;
                case 0x0D: finished = opcode_0x0D(); break;
                // 2.2 AND
                case 0x20: finished = opcode_0x20(); break;
                case 0x21: finished = opcode_0x21(); break;
                case 0x22: finished = opcode_0x22(); break;
                case 0x23: finished = opcode_0x23(); break;
                case 0x24: finished = opcode_0x24(); break;
                case 0x25: finished = opcode_0x25(); break;
                // 2.3 XOR
                case 0x30: finished = opcode_0x30(); break;
                case 0x31: finished = opcode_0x31(); break;
                case 0x32: finished = opcode_0x32(); break;
                case 0x33: finished = opcode_0x33(); break;
                case 0x34: finished = opcode_0x34(); break;
                case 0x35: finished = opcode_0x35(); break;
                // 2.4 Shifts
				case 0xD0: finished = opcode_0xD0(); break;
                case 0xD1: finished = opcode_0xD1(); break;
                case 0xD2: finished = opcode_0xD2(); break;
                case 0xD3: finished = opcode_0xD3(); break;

                // 3. movements
                // 3.1 PUSH
                case 0x06: finished = opcode_0x06(); break;
                case 0x0E: finished = opcode_0x0E(); break;
                case 0x16: finished = opcode_0x16(); break;
                case 0x1E: finished = opcode_0x1E(); break;
                case 0x9C: finished = opcode_0x9C(); break;

                case 0x50: finished = opcode_0x50(); break;
                case 0x51: finished = opcode_0x51(); break;
                case 0x52: finished = opcode_0x52(); break;
                case 0x53: finished = opcode_0x53(); break;
                case 0x54: finished = opcode_0x54(); break;
                case 0x55: finished = opcode_0x55(); break;
                case 0x56: finished = opcode_0x56(); break;
                case 0x57: finished = opcode_0x57(); break;

                // 3.2 POP
                case 0x07: finished = opcode_0x07(); break;
                case 0x0F: finished = opcode_0x0F(); break;
                case 0x17: finished = opcode_0x17(); break;
                case 0x1F: finished = opcode_0x1F(); break;
                case 0x9D: finished = opcode_0x9D(); break;

                case 0x58: finished = opcode_0x58(); break;
                case 0x59: finished = opcode_0x59(); break;
                case 0x5A: finished = opcode_0x5A(); break;
                case 0x5B: finished = opcode_0x5B(); break;
                case 0x5C: finished = opcode_0x5C(); break;
                case 0x5D: finished = opcode_0x5D(); break;
                case 0x5E: finished = opcode_0x5E(); break;
                case 0x5F: finished = opcode_0x5F(); break;

                case 0x8F: finished = opcode_0x8F(); break;

                // 3.3 MOV
                case 0xB0: finished = opcode_0xB0(); break;
                case 0xB1: finished = opcode_0xB1(); break;
                case 0xB2: finished = opcode_0xB2(); break;
                case 0xB3: finished = opcode_0xB3(); break;
                case 0xB4: finished = opcode_0xB4(); break;
                case 0xB5: finished = opcode_0xB5(); break;
                case 0xB6: finished = opcode_0xB6(); break;
                case 0xB7: finished = opcode_0xB7(); break;
                case 0xB8: finished = opcode_0xB8(); break;
                case 0xB9: finished = opcode_0xB9(); break;
                case 0xBA: finished = opcode_0xBA(); break;
                case 0xBB: finished = opcode_0xBB(); break;
                case 0xBC: finished = opcode_0xBC(); break;
                case 0xBD: finished = opcode_0xBD(); break;
                case 0xBE: finished = opcode_0xBE(); break;
                case 0xBF: finished = opcode_0xBF(); break;

                case 0x88: finished = opcode_0x88(); break;
                case 0x89: finished = opcode_0x89(); break;
                case 0x8A: finished = opcode_0x8A(); break;
                case 0x8B: finished = opcode_0x8B(); break;
                case 0x8C: finished = opcode_0x8C(); break;
                case 0x8E: finished = opcode_0x8E(); break;

                case 0xA0: finished = opcode_0xA0(); break;
                case 0xA1: finished = opcode_0xA1(); break;
                case 0xA2: finished = opcode_0xA2(); break;
                case 0xA3: finished = opcode_0xA3(); break;

                case 0xC6: finished = opcode_0xC6(); break;
                case 0xC7: finished = opcode_0xC7(); break;

                // 3.4 Jumps
                case 0x70: finished = opcode_0x70(); break;
                case 0x71: finished = opcode_0x71(); break;
                case 0x72: finished = opcode_0x72(); break;
                case 0x73: finished = opcode_0x73(); break;
                case 0x74: finished = opcode_0x74(); break;
                case 0x75: finished = opcode_0x75(); break;
                case 0x76: finished = opcode_0x76(); break;
                case 0x77: finished = opcode_0x77(); break;
                case 0x78: finished = opcode_0x78(); break;
                case 0x79: finished = opcode_0x79(); break;
                case 0x7A: finished = opcode_0x7A(); break;
                case 0x7B: finished = opcode_0x7B(); break;
                case 0x7C: finished = opcode_0x7C(); break;
                case 0x7D: finished = opcode_0x7D(); break;
                case 0x7E: finished = opcode_0x7E(); break;
                case 0x7F: finished = opcode_0x7F(); break;

                case 0xE3: finished = opcode_0xE3(); break;

                case 0xEB: finished = opcode_0xEB(); break;
                case 0xE9: finished = opcode_0xE9(); break;
                case 0xEA: finished = opcode_0xEA(); break;

                // 3.4.1 CALL
                case 0xE8: finished = opcode_0xE8(); break;
                case 0x9A: finished = opcode_0x9A(); break;

                // 3.4.2 RET
                case 0xC3: finished = opcode_0xC3(); break;
                case 0xCB: finished = opcode_0xCB(); break;
                case 0xC2: finished = opcode_0xC2(); break;
                case 0xCA: finished = opcode_0xCA(); break;

                // 3.4.3 LOOP
                case 0xE0: finished = opcode_0xE0(); break;
                case 0xE1: finished = opcode_0xE1(); break;
                case 0xE2: finished = opcode_0xE2(); break;


                // 3.5 XCHG
                case 0x86: finished = opcode_0x86(); break;
                case 0x87: finished = opcode_0x87(); break;
                case 0x91: finished = opcode_0x91(); break;
                case 0x92: finished = opcode_0x92(); break;
                case 0x93: finished = opcode_0x93(); break;
                case 0x94: finished = opcode_0x94(); break;
                case 0x95: finished = opcode_0x95(); break;
                case 0x96: finished = opcode_0x96(); break;
                case 0x97: finished = opcode_0x97(); break;

                // 3.6 LEA, LES, LDS
                case 0x8D: finished = opcode_0x8D(); break;
                case 0xC4: finished = opcode_0xC4(); break;
                case 0xC5: finished = opcode_0xC5(); break;


                // 4 - NOP, flags
                case 0x90: finished = opcode_0x90(); break;
                case 0xD6: finished = opcode_0xD6(); break;
                case 0xD8: finished = opcode_0xD8(); break; // ESC
                case 0xF8: finished = opcode_0xF8(); break;
                case 0xF5: finished = opcode_0xF5(); break;
                case 0xF9: finished = opcode_0xF9(); break;
                case 0xFC: finished = opcode_0xFC(); break;
                case 0xFD: finished = opcode_0xFD(); break;
                case 0xFA: finished = opcode_0xFA(); break;
                case 0xFB: finished = opcode_0xFB(); break;

                case 0x9F: finished = opcode_0x9F(); break;
                case 0x9E: finished = opcode_0x9E(); break;

                case 0x98: finished = opcode_0x98(); break;
                case 0x99: finished = opcode_0x99(); break;


                // 5 - Extended opcodes (Math with immediate)
                case 0x80: finished = opcode_0x80(); break;
                case 0x81: finished = opcode_0x81(); break;
                case 0x82: finished = opcode_0x80(); break; // duplicated on 0x80
                case 0x83: finished = opcode_0x83(); break;
                case 0xF6: finished = opcode_0xF6(); break;
                case 0xF7: finished = opcode_0xF7(); break;
                case 0xFE: finished = opcode_0xFE(); break;
                case 0xFF: finished = opcode_0xFF(); break;


                // 6 - Test opcodes
                case 0xA8: finished = opcode_0xA8(); break;
                case 0xA9: finished = opcode_0xA9(); break;
                case 0x84: finished = opcode_0x84(); break;
                case 0x85: finished = opcode_0x85(); break;

                // 7 interrupts:
                case 0xCC: finished = opcode_0xCC(); break;
                case 0xCE: finished = opcode_0xCE(); break;
                case 0xCD: finished = opcode_0xCD(); break;
                case 0xCF: finished = opcode_0xCF(); break;

                // 8 in / out:
				case 0xEC: finished = opcode_0xEC(); break;
                case 0xE4: finished = opcode_0xE4(); break;
                case 0xED: finished = opcode_0xED(); break;
                case 0xE5: finished = opcode_0xE5(); break;
                case 0xEE: finished = opcode_0xEE(); break;
                case 0xEF: finished = opcode_0xEF(); break;
                case 0xE6: finished = opcode_0xE6(); break;
				case 0xE7: finished = opcode_0xE7(); break;

				//prefixes for segments
				case 0x26: finished = opcode_0x26(); break;
				case 0x2E: finished = opcode_0x2E(); break;
				case 0x36: finished = opcode_0x36(); break;
				case 0x3E: finished = opcode_0x3E(); break;

            }

            if (!finished) return;

            interrupted = false;
            interruptState = 0;
            euState = EUSTate::OPCODE_FETCH;


            return;
        }
    }
}

void IProc_8088::EU_calculateEffectiveAddress() {
    if (!doCalculateEffectiveAddress) return;

    switch (effectiveAddressState) {
        case EffectiveAddressState::FETCH_MOD_REG_RM_BYTE: {
            if (!BIURequirePrefetchQueueByte()) return;

            // take addressing byte from prefetch queue
            addressingModeByte = prefetchQueue.pop();
            ip++;
			dispOrAddressByteLowFetched = false;
			dispOrAddressByteHighFetched = false;
			dataLowFetched = false;
            dataHighFetched = false;

            effectiveAddressState = EffectiveAddressState::DECODE;
            // do decode
        }

        case EffectiveAddressState::DECODE: {
            byte MOD = getMODField();
            byte RM = getRMField();

            effectiveAddressIsRegister = false; // default case
            if (MOD == 3) effectiveAddressIsRegister = true;
            else if (MOD == 0) {
                if (RM == 0x06) {
                    // Word direct address fetch
                    if (!dispOrAddressByteLowFetched) {
						if (!BIURequirePrefetchQueueByte()) return;
						dispByteLow = prefetchQueue.pop();
						ip++;
						dispOrAddressByteLowFetched = true;
					}

					if (!dispOrAddressByteHighFetched) {
						if (!BIURequirePrefetchQueueByte()) return;
						dispByteHigh = prefetchQueue.pop();
                        ip++;
                        dispOrAddressByteHighFetched = true;
                    }
                }

                switch (RM) {
					case 0x00: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + si; waitClocksCount += 7; break;
					case 0x01: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + di; waitClocksCount += 8; break;
					case 0x02: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + si; waitClocksCount += 8; break;
					case 0x03: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + di; waitClocksCount += 7; break;
					case 0x04: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = si; waitClocksCount += 5; break;
					case 0x05: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = di; waitClocksCount += 5; break;
					case 0x06: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = getDispWord(); waitClocksCount += 6; break;
					case 0x07: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx; waitClocksCount += 5; break;
                }
            } else if (MOD == 1) {
                // byte signed (low) displacement

                if (!dispOrAddressByteLowFetched) {
                    if (!BIURequirePrefetchQueueByte()) return;
                    dispByteLow = prefetchQueue.pop();
                    ip++;
                    dispOrAddressByteLowFetched = true;
                }

                switch (RM) {
					case 0x00: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + si + signExtendedByte(dispByteLow); waitClocksCount += 11; break;
					case 0x01: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + di + signExtendedByte(dispByteLow); waitClocksCount += 12; break;
					case 0x02: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + si + signExtendedByte(dispByteLow); waitClocksCount += 12; break;
					case 0x03: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + di + signExtendedByte(dispByteLow); waitClocksCount += 11; break;
					case 0x04: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = si + signExtendedByte(dispByteLow); waitClocksCount += 9; break;
					case 0x05: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = di + signExtendedByte(dispByteLow); waitClocksCount += 9; break;
					case 0x06: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + signExtendedByte(dispByteLow); waitClocksCount += 9; break;
					case 0x07: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + signExtendedByte(dispByteLow); waitClocksCount += 9; break;
                }
            } else if (MOD == 2) {
                // word unsigned displacement
                if (!dispOrAddressByteLowFetched) {
                    if (!BIURequirePrefetchQueueByte()) return;
                    dispByteLow = prefetchQueue.pop();
                    ip++;
                    dispOrAddressByteLowFetched = true;
                }

                if (!dispOrAddressByteHighFetched) {
                    if (!BIURequirePrefetchQueueByte()) return;
                    dispByteHigh = prefetchQueue.pop();
                    ip++;
                    dispOrAddressByteHighFetched = true;
                }

                switch (RM) {
					case 0x00: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + si + getDispWord(); waitClocksCount += 11; break;
					case 0x01: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + di + getDispWord(); waitClocksCount += 12; break;
					case 0x02: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + si + getDispWord(); waitClocksCount += 12; break;
					case 0x03: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + di + getDispWord(); waitClocksCount += 11; break;
					case 0x04: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = si + getDispWord(); waitClocksCount += 9; break;
					case 0x05: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = di + getDispWord(); waitClocksCount += 9; break;
					case 0x06: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::SS;} else{ segmentRegSpecified = false;} effectiveAddress = bp + getDispWord(); waitClocksCount += 9; break;
					case 0x07: if (!segmentRegSpecified){ effectiveAddressSegment = SegmentRegister::DS;} else{ segmentRegSpecified = false;} effectiveAddress = bx + getDispWord(); waitClocksCount += 9; break;
                }
            }

            effectiveAddressState = EffectiveAddressState::FETCH_MOD_REG_RM_BYTE;
            effectiveAddressCalculationFinished = true;
            doCalculateEffectiveAddress = false;
        }

    }
}

byte IProc_8088::addBytes(byte data1, byte data2, bool withCarry, bool inc) {
    setFlagOverflow(0);
	setFlagAuxiliaryCarry(0);

	bool carry = getFlagCarry();
    if (!inc) setFlagCarry(0);

    byte nibbleResult;
    word byteResult;

    if (withCarry) {
		nibbleResult = (0x0F & data1) + (0x0F & data2) + carry;
        byteResult = (word) data1 + (word) data2 + carry;
    } else {
        nibbleResult = (0x0F & data1) + (0x0F & data2);
        byteResult = (word) data1 + (word) data2;
    }

    if (nibbleResult > 0x0F) setFlagAuxiliaryCarry(1);
    if (!inc && byteResult > 0xFF) setFlagCarry(1);

    bool sign1 = (data1 & 0x80) >> 7;
    bool sign2 = (data2 & 0x80) >> 7;
    bool signResult = (byteResult & 0x80) >> 7;

    if ((!sign1 && !sign2 && signResult) || (sign1 && sign2 && !signResult)) setFlagOverflow(1);
    setFlagsByteSZP(byteResult);

    return byteResult;
}

word IProc_8088::addWords(word data1, word data2, bool withCarry, bool inc) {
    setFlagOverflow(0);
	setFlagAuxiliaryCarry(0);

	bool carry = getFlagCarry();

    if (!inc) setFlagCarry(0);

    byte nibbleResult;
    unsigned __int32 wordResult;

    if (withCarry) {
		nibbleResult = (0x0F & data1) + (0x0F & data2) + carry;
		wordResult = (unsigned __int32) data1 + (unsigned __int32) data2 + carry;
	} else {
        nibbleResult = (0x0F & data1) + (0x0F & data2);
        wordResult = (unsigned __int32) data1 + (unsigned __int32) data2;
    }

    if (nibbleResult > 0x0F) setFlagAuxiliaryCarry(1);
    if (!inc && wordResult > 0xFFFF) setFlagCarry(1);

    bool sign1 = (data1 & 0x8000) >> 15;
    bool sign2 = (data2 & 0x8000) >> 15;
    bool signResult = (wordResult & 0x8000) >> 15;

    if ((!sign1 && !sign2 && signResult) || (sign1 && sign2 && !signResult)) setFlagOverflow(1);
    setFlagsWordSZP(wordResult);

    return wordResult;
}

bool IProc_8088::opcode_0x00() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x01() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addWords((word) effectiveAddressFetchedData, (word) fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x02() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x03() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addWords((word) effectiveAddressFetchedData, (word) fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x04() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, addBytes(ax, dataByteLow));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x05() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, addWords(ax, getDataWord()));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x10() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x11() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addWords((word) effectiveAddressFetchedData, (word) fetchedRegister, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x12() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x13() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = addWords((word) effectiveAddressFetchedData, (word) fetchedRegister, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x14() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, addBytes(ax, dataByteLow, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x15() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, addWords(ax, getDataWord(), true));
        opcodeState++;
    }
    return true;
}

byte IProc_8088::subBytes(byte data1, byte data2, bool withCarry, bool dec) {
    setFlagOverflow(0);
	setFlagAuxiliaryCarry(0);

	bool carry = getFlagCarry();
    if (!dec) setFlagCarry(0);

	byte nibbleResult;
    word byteResult;

    if (withCarry) {
		nibbleResult = (0x0F & data1) - (0x0F & data2) - carry;
        byteResult = (word) data1 - (word) data2 - carry;
    } else {
        nibbleResult = (0x0F & data1) - (0x0F & data2);
        byteResult = (word) data1 - (word) data2;
    }

    if (nibbleResult > 0x0F) setFlagAuxiliaryCarry(1);
    if (!dec && byteResult > 0xFF) setFlagCarry(1);

    bool sign1 = (data1 & 0x80) >> 7;
    bool sign2 = (data2 & 0x80) >> 7;
    bool signResult = (byteResult & 0x80) >> 7;

    if ((!sign1 && sign2 && signResult) || (sign1 && !sign2 && !signResult)) setFlagOverflow(1);
    setFlagsByteSZP(byteResult);

    return byteResult;
}

word IProc_8088::subWords(word data1, word data2, bool withCarry, bool dec) {
    setFlagOverflow(0);
	setFlagAuxiliaryCarry(0);
	bool carry = getFlagCarry();
    if (!dec) setFlagCarry(0);

    byte nibbleResult;
    unsigned __int32 wordResult;

    if (withCarry) {
		nibbleResult = (0x0F & data1) - (0x0F & data2) - carry;
		wordResult = (unsigned __int32) data1 - (unsigned __int32) data2 - carry;
    } else {
        nibbleResult = (0x0F & data1) - (0x0F & data2);
        wordResult = (unsigned __int32) data1 - (unsigned __int32) data2;
    }

    if (nibbleResult > 0x0F) setFlagAuxiliaryCarry(1);
    if (!dec && wordResult > 0xFFFF) setFlagCarry(1);

    bool sign1 = (data1 & 0x8000) >> 15;
    bool sign2 = (data2 & 0x8000) >> 15;
    bool signResult = (wordResult & 0x8000) >> 15;

    if ((!sign1 && sign2 && signResult) || (sign1 && !sign2 && !signResult)) setFlagOverflow(1);
    setFlagsWordSZP(wordResult);

    return wordResult;
}

bool IProc_8088::opcode_0x18() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x19() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subWords((word) effectiveAddressFetchedData, (word) fetchedRegister, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x1A() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subBytes((byte) fetchedRegister, (byte) effectiveAddressFetchedData, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x1B() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subWords((word) fetchedRegister, (word) effectiveAddressFetchedData, true);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x1C() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, subBytes(ax, dataByteLow, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x1D() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, subWords(ax, getDataWord(), true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x28() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x29() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subWords((word) effectiveAddressFetchedData, (word) fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x2A() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
		opcodeResult = subBytes((byte) fetchedRegister, (byte) effectiveAddressFetchedData);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x2B() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
		opcodeResult = subWords((word) fetchedRegister, (word) effectiveAddressFetchedData);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x2C() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, subBytes(ax, dataByteLow));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x2D() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, subWords(ax, getDataWord()));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x38() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subBytes((byte) effectiveAddressFetchedData, (byte) fetchedRegister);
        opcodeState++;
    }
    // operation computed

    return true;
}

bool IProc_8088::opcode_0x39() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subWords((word) effectiveAddressFetchedData, (word) fetchedRegister);
        opcodeState++;
    }
    // operation computed

    return true;
}

bool IProc_8088::opcode_0x3A() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subBytes((byte) fetchedRegister, (byte) effectiveAddressFetchedData);
        opcodeState++;
    }
    // operation computed

    return true;
}

bool IProc_8088::opcode_0x3B() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = subWords((word) fetchedRegister, (word) effectiveAddressFetchedData);
        opcodeState++;
    }
    // operation computed

    return true;
}

bool IProc_8088::opcode_0x3C() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        subBytes(ax, dataByteLow);
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x3D() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        subWords(ax, getDataWord());
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x40() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::AX, addWords(ax, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x41() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::CX, addWords(cx, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x42() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::DX, addWords(dx, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x43() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::BX, addWords(bx, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x44() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::SP, addWords(sp, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x45() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::BP, addWords(bp, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x46() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::SI, addWords(si, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x47() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::DI, addWords(di, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x48() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::AX, subWords(ax, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x49() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::CX, subWords(cx, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x4A() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::DX, subWords(dx, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x4B() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::BX, subWords(bx, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x4C() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::SP, subWords(sp, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x4D() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::BP, subWords(bp, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x4E() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::SI, subWords(si, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x4F() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::DI, subWords(di, 1, false, true));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x27() {
    if (opcodeState == 0) {
        waitClocksCount += 4;

        byte al = fetchRegister(Register::AL);
        if ( ((0x0F & al) > 0x09) || getFlagAuxiliaryCarry() )  {
            al += 0x06;
            setFlagAuxiliaryCarry(1);
        } else setFlagAuxiliaryCarry(0);

        if ( ((0xFF & al) > 0x9F) || getFlagCarry() )  {
            al += 0x60;
            setFlagCarry(1);
        } else setFlagCarry(0);

        writeRegister(Register::AL, al);
        setFlagsByteSZP(al);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x2F() {
    if (opcodeState == 0) {
        waitClocksCount += 4;

        byte al = fetchRegister(Register::AL);
        if ( ((0x0F & al) > 0x09) || getFlagAuxiliaryCarry() ) {
            al -= 0x06;
            setFlagAuxiliaryCarry(1);
        } else setFlagAuxiliaryCarry(0);

        if ( ((0xFF & al) > 0x9F) || getFlagCarry() )  {
            al -= 0x60;
            setFlagCarry(1);
        } else setFlagCarry(0);

        writeRegister(Register::AL, al);
        setFlagsByteSZP(al);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x37() {
    if (opcodeState == 0) {
        waitClocksCount += 4;

        byte al = fetchRegister(Register::AL);
        bool a = getFlagAuxiliaryCarry();

        if ( ((0x0F & al) > 0x09) || a )  {
            al += 0x06;
            writeRegister(Register::AL, al);
            ax += 0x0010; // AH ++
            setFlagAuxiliaryCarry(1);
        }

        setFlagCarry(a);
        ax = ax & 0xFF0F; // AL = AL & 0x0F

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x3F() {
    if (opcodeState == 0) {
        waitClocksCount += 4;

        byte al = fetchRegister(Register::AL);
        bool a = getFlagAuxiliaryCarry();

        if ( ((0x0F & al) > 0x09) || a )  {
            al -= 0x06;
            ax -= 0x0100; // AH --
            writeRegister(Register::AL, al);
            setFlagAuxiliaryCarry(1);
        }

        setFlagCarry(a);
        ax = ax & 0xFF0F; // AL = AL & 0x0F

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0xD4() {
    if (opcodeState == 0) {
        waitClocksCount += 83;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte())
            return false;

        byte opcodeDivisor = prefetchQueue.pop();
        ip++;

        byte al = fetchRegister(Register::AL);
        byte ah = al / opcodeDivisor;
        al = al % opcodeDivisor;

        setFlagsByteSZP(al);
        writeRegister(Register::AH, ah);
        writeRegister(Register::AL, al);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xD5() {
    if (opcodeState == 0) {
        waitClocksCount += 60;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte())
            return false;

        byte opcodeMultiplier = prefetchQueue.pop();
        ip++;

        byte al = (byte) fetchRegister(Register::AL);
		byte ah = (byte) fetchRegister(Register::AH);

        ax = 0x00FF & ((ah * opcodeMultiplier) + al);

        setFlagsByteSZP(al);
        opcodeState++;
    }

    return true;
}


word IProc_8088::booleanOr(word data1, word data2) {
    word result = data1 | data2;

    if (isWordOperation()) setFlagsWordSZP(result);
    else setFlagsByteSZP(result);

    setFlagOverflow(0);
    setFlagCarry(0);

    return result;
}

bool IProc_8088::opcode_0x08() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanOr(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x09() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanOr(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x0A() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanOr(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x0B() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanOr(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x0C() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, booleanOr(ax, dataByteLow));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x0D() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, booleanOr(ax, getDataWord()));
        opcodeState++;
    }
    return true;
}

word IProc_8088::booleanAnd(word data1, word data2) {
    word result = data1 & data2;

    if (isWordOperation()) setFlagsWordSZP(result);
    else setFlagsByteSZP(result);

    setFlagOverflow(0);
    setFlagCarry(0);

    return result;
}

bool IProc_8088::opcode_0x20() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanAnd(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x21() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanAnd(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x22() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanAnd(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x23() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanAnd(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x24() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, booleanAnd(ax, dataByteLow));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x25() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, booleanAnd(ax, getDataWord()));
        opcodeState++;
    }
    return true;
}

word IProc_8088::booleanXor(word data1, word data2) {
    word result = data1 ^ data2;

    if (isWordOperation()) setFlagsWordSZP(result);
    else setFlagsByteSZP(result);

    setFlagOverflow(0);
    setFlagCarry(0);

    return result;
}

bool IProc_8088::opcode_0x30() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 16;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanXor(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x31() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanXor(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x32() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanXor(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x33() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }
    // data on effective address is fetched

    if (opcodeState == 3) {
        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }
    // register fetched

    if (opcodeState == 4) {
        opcodeResult = booleanXor(effectiveAddressFetchedData, fetchedRegister);
        opcodeState = 5;
    }
    // operation computed

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }
    // result written

    return true;
}

bool IProc_8088::opcode_0x34() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;

        dataLowFetched = true;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AL, booleanXor(ax, dataByteLow));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x35() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!dataLowFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataLowFetched = true;
            dataByteLow = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!dataHighFetched) {
            if (!BIURequirePrefetchQueueByte()) return false;
            dataHighFetched = true;
            dataByteHigh = prefetchQueue.pop();
            ip++;
        }
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AL, booleanXor(ax, getDataWord()));
        opcodeState++;
    }
    return true;
}


byte IProc_8088::rolByte(byte data, byte count) {
    bool oldMsb = 0;
    bool newMsb = 0;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = (data & 0x80) >> 7;
        data = (data << 1) | oldMsb;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x80) >> 7;
    setFlagCarry(oldMsb);
    if (newMsb != getFlagCarry()) setFlagOverflow(1);

    return data;
}

word IProc_8088::rolWord(word data, byte count) {
    bool oldMsb = 0;
    bool newMsb = 0;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = (data & 0x8000) >> 15;
        data = (data << 1) | oldMsb;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x8000) >> 15;
    setFlagCarry(oldMsb);
    if (newMsb != getFlagCarry()) setFlagOverflow(1);

    return data;
}

byte IProc_8088::rorByte(byte data, byte count) {
    byte oldLsb = 0;
    byte newMsb = 0;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldLsb = (data << 7);
        data = oldLsb | (data >> 1);
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x80) >> 7;
    setFlagCarry(newMsb);
    if ((data & 0x80) != ((data & 0x40) << 1)) setFlagOverflow(1);

    return data;
}

word IProc_8088::rorWord(word data, byte count) {
    word oldLsb = 0;
    word newMsb = 0;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldLsb = (data << 15);
        data = oldLsb | (data >> 1);
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x8000) >> 15;
    setFlagCarry(newMsb);
    if ((data & 0x8000) != ((data & 0x4000) << 1)) setFlagOverflow(1);

    return data;
}

byte IProc_8088::rclByte(byte data, byte count) {
    bool oldMsb, newMsb, tempcf;

    while (count != 0) {
        tempcf = getFlagCarry();
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = (data & 0x80) >> 7;
        setFlagCarry(oldMsb);
        data = (data << 1) | tempcf;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x80) >> 7;
    setFlagCarry(oldMsb);
    if (newMsb != getFlagCarry()) setFlagOverflow(1);

    return data;
}

word IProc_8088::rclWord(word data, byte count) {
    word oldMsb, newMsb;
    bool tempcf;

    while (count != 0) {
        tempcf = getFlagCarry();
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = (data & 0x8000) >> 15;
        setFlagCarry(oldMsb);
        data = (data << 1) | tempcf;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x8000) >> 15;
    setFlagCarry(oldMsb);
    if (newMsb != getFlagCarry()) setFlagOverflow(1);

    return data;
}

byte IProc_8088::rcrByte(byte data, byte count) {
    byte tempcf, oldLsb;

    while (count != 0) {
        tempcf = ((byte) getFlagCarry()) << 7;
        setFlagCarry(0);
        setFlagOverflow(0);

        oldLsb = data & 1;
        setFlagCarry(oldLsb);
        data = tempcf | (data >> 1);
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    if ((data & 0x80) != ((data & 0x40) << 1)) setFlagOverflow(1);

    return data;
}

word IProc_8088::rcrWord(word data, byte count) {
    word tempcf, oldLsb;

    while (count != 0) {
        tempcf = ((byte) getFlagCarry()) << 15;
        setFlagCarry(0);
        setFlagOverflow(0);

        oldLsb = data & 1;
        setFlagCarry(oldLsb);
        data = tempcf | (data >> 1);
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    if ((data & 0x8000) != ((data & 0x4000) << 1)) setFlagOverflow(1);

    return data;
}

byte IProc_8088::salByte(byte data, byte count) {
    bool oldMsb, newMsb;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = (data & 0x80) >> 7;
        setFlagCarry(oldMsb);
        data = data << 1;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x80) >> 7;
    setFlagCarry(oldMsb);
    if (newMsb != getFlagCarry()) setFlagOverflow(1);
    setFlagsByteSZP(data);

    return data;
}

word IProc_8088::salWord(word data, byte count) {
    bool oldMsb, newMsb;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = (data & 0x8000) >> 15;
        setFlagCarry(oldMsb);
        data = data << 1;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    newMsb = (data & 0x8000) >> 15;
    setFlagCarry(oldMsb);
    if (newMsb != getFlagCarry()) setFlagOverflow(1);
    setFlagsWordSZP(data);

    return data;
}

byte IProc_8088::shrByte(byte data, byte count) {
    byte oldLsb;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldLsb = data & 1;
		setFlagCarry(oldLsb);
        data = data >> 1;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    if ((data & 0x80) != ((data & 0x40) << 1)) setFlagOverflow(1);
    setFlagsByteSZP(data);
    return data;
}

word IProc_8088::shrWord(word data, byte count) {
    word oldLsb;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldLsb = data & 1;
        setFlagCarry(oldLsb);
        data = data >> 1;
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    if ((data & 0x8000) != ((data & 0x4000) << 1)) setFlagOverflow(1);
    setFlagsWordSZP(data);
    return data;
}

byte IProc_8088::sarByte(byte data, byte count) {
    byte oldLsb, oldMsb;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = data & 0x80;
        oldLsb = data & 1;
        setFlagCarry(oldLsb);
        data = oldMsb | (data >> 1);
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    if ((data & 0x80) != ((data & 0x40) << 1)) setFlagOverflow(1);
    setFlagsByteSZP(data);
    return data;
}

word IProc_8088::sarWord(word data, byte count) {
    word oldLsb, oldMsb;

    while (count != 0) {
        setFlagCarry(0);
        setFlagOverflow(0);

        oldMsb = data & 0x8000;
        oldLsb = data & 1;
        setFlagCarry(oldLsb);
        data = oldMsb | (data >> 1);
        count--;
        waitClocksCount += 4; // per bit clocks
    }

    if ((data & 0x8000) != ((data & 0x4000) << 1)) setFlagOverflow(1);
    setFlagsWordSZP(data);
    return data;
}

bool IProc_8088::opcode_0xD0() {
	if (opcodeState == 0) {
		waitClocksCount += effectiveAddressIsRegister ? 2 : 13;      //-2
		opcodeState = 1;
    }

	if (opcodeState == 1) {
		if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

	if (opcodeState == 2) {
		if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
		switch (getREGField()) {
			case 0: opcodeResult = rolByte(effectiveAddressFetchedData & 0xFF, 1); break;
			case 1: opcodeResult = rorByte(effectiveAddressFetchedData & 0xFF, 1); break;
			case 2: opcodeResult = rclByte(effectiveAddressFetchedData & 0xFF, 1); break;
			case 3: opcodeResult = rcrByte(effectiveAddressFetchedData & 0xFF, 1); break;
			case 4: opcodeResult = salByte(effectiveAddressFetchedData & 0xFF, 1); break;
			case 5: opcodeResult = shrByte(effectiveAddressFetchedData & 0xFF, 1); break;
			case 6: opcodeResult = shrByte(effectiveAddressFetchedData & 0xFF, 1); break; // duplicate on reg = 5
			case 7: opcodeResult = sarByte(effectiveAddressFetchedData & 0xFF, 1); break;
        }
        opcodeState = 4;
	}

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

	return true;
}

bool IProc_8088::opcode_0xD1() {
	if (opcodeState == 0) {
		waitClocksCount += effectiveAddressIsRegister ? 2 : 21;    //-2
        opcodeState = 1;
	}

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        switch (getREGField()) {
			case 0: opcodeResult = rolWord(effectiveAddressFetchedData, 1); break;
            case 1: opcodeResult = rorWord(effectiveAddressFetchedData, 1); break;
            case 2: opcodeResult = rclWord(effectiveAddressFetchedData, 1); break;
			case 3: opcodeResult = rcrWord(effectiveAddressFetchedData, 1); break;
            case 4: opcodeResult = salWord(effectiveAddressFetchedData, 1); break;
            case 5: opcodeResult = shrWord(effectiveAddressFetchedData, 1); break;
            case 6: opcodeResult = shrWord(effectiveAddressFetchedData, 1); break; // duplicate on reg = 5
            case 7: opcodeResult = sarWord(effectiveAddressFetchedData, 1); break;
        }
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xD2() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 8 : 20;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        switch (getREGField()) {
            case 0: opcodeResult = rolByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 1: opcodeResult = rorByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 2: opcodeResult = rclByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 3: opcodeResult = rcrByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 4: opcodeResult = salByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 5: opcodeResult = shrByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 6: opcodeResult = shrByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break; // duplicate on reg = 5
            case 7: opcodeResult = sarByte(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
        }
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xD3() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 8 : 28;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        switch (getREGField()) {
            case 0: opcodeResult = rolWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 1: opcodeResult = rorWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 2: opcodeResult = rclWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 3: opcodeResult = rcrWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 4: opcodeResult = salWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 5: opcodeResult = shrWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
            case 6: opcodeResult = shrWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break; // duplicate on reg = 5
            case 7: opcodeResult = sarWord(effectiveAddressFetchedData, fetchRegister(Register::CL)); break;
        }
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::push(word data, int clocks) {
    if (pushState == 0) {
        waitClocksCount += clocks;
        pushState = 1;
    }

    if (pushState == 1) {
        sp -= 2;
        pushState = 2;
    }
    // sp decreased

    // write word
    if (pushState == 2) {
        if (!BIURequireOperationWord(BIUAction::MW, SegmentRegister::SS, sp, data))
            return false;
        pushState++;
    }

    return true;
}

bool IProc_8088::pop(int clocks) {
    if (popState == 0) {
        waitClocksCount += clocks;
        popState = 1;
    }

    // read low byte
    if (popState == 1) {
        if (!BIURequireOperationWord(BIUAction::MR, SegmentRegister::SS, sp, 0))
            return false;

        opcodeResult = BIURequiredWord();
        popState = 2;
    }

	if (popState == 2) {
		sp += 2;
        popState++;
    }

    return true;
}

bool IProc_8088::opcode_0x06() {
    return push(es, 14);
}

bool IProc_8088::opcode_0x0E() {
    return push(cs, 14);
}

bool IProc_8088::opcode_0x16() {
    return push(ss, 14);
}

bool IProc_8088::opcode_0x1E() {
    return push(ds, 14);
}

bool IProc_8088::opcode_0x9C() {
    return push(0xF000 | flags, 14);
}

bool IProc_8088::opcode_0x50() {
    return push(ax, 15);
}

bool IProc_8088::opcode_0x51() {
    return push(cx, 15);
}

bool IProc_8088::opcode_0x52() {
    return push(dx, 15);
}

bool IProc_8088::opcode_0x53() {
    return push(bx, 15);
}

bool IProc_8088::opcode_0x54() {
    return push(sp, 15); // at sp-2 address sp-2 value will be written
}

bool IProc_8088::opcode_0x55() {
    return push(bp, 15);
}

bool IProc_8088::opcode_0x56() {
    return push(si, 15);
}

bool IProc_8088::opcode_0x57() {
    return push(di, 15);
}

bool IProc_8088::opcode_0x07() {
    if (!pop(8)) return false;
    es = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x0F() {
    if (!pop(8)) return false;
    cs = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x17() {
    if (!pop(8)) return false;
    ss = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x1F() {
    if (!pop(8)) return false;
    ds = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x9D() {
    if (!pop(8)) return false;
    flags = 0xF000 | (0xFD5 & opcodeResult);
    return true;
}

bool IProc_8088::opcode_0x58() {
    if (!pop(8)) return false;
    ax = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x59() {
    if (!pop(8)) return false;
    cx = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x5A() {
    if (!pop(8)) return false;
    dx = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x5B() {
    if (!pop(8)) return false;
    bx = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x5C() {
    if (!pop(8)) return false;
    sp = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x5D() {
    if (!pop(8)) return false;
    bp = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x5E() {
    if (!pop(8)) return false;
    si = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x5F() {
    if (!pop(8)) return false;
    di = opcodeResult;
    return true;
}

bool IProc_8088::opcode_0x8F() {
    if (opcodeState == 0) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!pop(effectiveAddressIsRegister ? 8 : 17)) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result is written

    return true;
}

bool IProc_8088::movImmediateByteToReg(Register reg) {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(reg, (word) dataByteLow);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::movImmediateWordToReg(Register reg) {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;
        dataByteLow = prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!BIURequirePrefetchQueueByte()) return false;
        dataByteHigh = prefetchQueue.pop();
        ip++;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(reg, getDataWord());
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xB0() { return movImmediateByteToReg(Register::AL); }
bool IProc_8088::opcode_0xB1() { return movImmediateByteToReg(Register::CL); }
bool IProc_8088::opcode_0xB2() { return movImmediateByteToReg(Register::DL); }
bool IProc_8088::opcode_0xB3() { return movImmediateByteToReg(Register::BL); }
bool IProc_8088::opcode_0xB4() { return movImmediateByteToReg(Register::AH); }
bool IProc_8088::opcode_0xB5() { return movImmediateByteToReg(Register::CH); }
bool IProc_8088::opcode_0xB6() { return movImmediateByteToReg(Register::DH); }
bool IProc_8088::opcode_0xB7() { return movImmediateByteToReg(Register::BH); }
bool IProc_8088::opcode_0xB8() { return movImmediateWordToReg(Register::AX); }
bool IProc_8088::opcode_0xB9() { return movImmediateWordToReg(Register::CX); }
bool IProc_8088::opcode_0xBA() { return movImmediateWordToReg(Register::DX); }
bool IProc_8088::opcode_0xBB() { return movImmediateWordToReg(Register::BX); }
bool IProc_8088::opcode_0xBC() { return movImmediateWordToReg(Register::SP); }
bool IProc_8088::opcode_0xBD() { return movImmediateWordToReg(Register::BP); }
bool IProc_8088::opcode_0xBE() { return movImmediateWordToReg(Register::SI); }
bool IProc_8088::opcode_0xBF() { return movImmediateWordToReg(Register::DI); }

bool IProc_8088::opcode_0x88() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        opcodeResult = fetchRegister((Register) getREGFieldTable());
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0x89() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        opcodeResult = fetchRegister((Register) getREGFieldTable());
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0x8A() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 8;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister((Register) getREGFieldTable(), effectiveAddressFetchedData);
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0x8B() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 12;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister((Register) getREGFieldTable(), effectiveAddressFetchedData);
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0x8C() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 13;
        forceWordOperation = true; // need force word operation due to opcode w = 0
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        opcodeResult = fetchSegmentRegister((SegmentRegister) getREGField());
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    forceWordOperation = false;
    // result is written
    return true;
}

bool IProc_8088::opcode_0x8E() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 12;
        forceWordOperation = true;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeSegmentRegister((SegmentRegister) getREGField(), effectiveAddressFetchedData);
        opcodeState++;
    }
    forceWordOperation = false;
    // result is written
    return true;
}

bool IProc_8088::opcode_0xA0() {
    if (opcodeState == 0) {
        waitClocksCount += 10;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        // address from MOV
        opcodeResult = prefetchQueue.pop();
        ip++;
        opcodeResult = opcodeResult | ( ((word)prefetchQueue.pop()) << 8);
        ip++;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequireOperationByte(BIUAction::MR, SegmentRegister::DS, opcodeResult, 0))
            return false;

        opcodeResult = BIUDataIn;
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        writeRegister(Register::AL, opcodeResult);
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0xA1() {
    if (opcodeState == 0) {
        waitClocksCount += 14;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        // address from MOV
        opcodeResult = prefetchQueue.pop();
        ip++;
        opcodeResult = opcodeResult | ( ((word)prefetchQueue.pop()) << 8);
        ip++;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequireOperationWord(BIUAction::MR, SegmentRegister::DS, opcodeResult, 0))
            return false;

        opcodeState = 4;
    }


    if (opcodeState == 4) {
        writeRegister(Register::AX, BIURequiredWord());
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0xA2() {
    if (opcodeState == 0) {
        waitClocksCount += 10;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        // address to MOV
        opcodeResult = prefetchQueue.pop();
        ip++;
        opcodeResult = opcodeResult | ( ((word)prefetchQueue.pop()) << 8);
        ip++;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequireOperationByte(BIUAction::MW, SegmentRegister::DS, opcodeResult, ax))
            return false;
        opcodeState++;
    }

    // result is written
    return true;
}

bool IProc_8088::opcode_0xA3() {
    if (opcodeState == 0) {
        waitClocksCount += 14;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        // address to MOV
        opcodeResult = prefetchQueue.pop();
        ip++;
        opcodeResult = opcodeResult | ( ((word)prefetchQueue.pop()) << 8);
        ip++;
        opcodeState = 3;
    }

    // write low byte
    if (opcodeState == 3) {
        if (!BIURequireOperationWord(BIUAction::MW, SegmentRegister::DS, opcodeResult, ax))
            return false;
        opcodeState++;
    }

    // result is written
    return true;
}

bool IProc_8088::opcode_0xC6() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 10;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!BIURequirePrefetchQueueByte()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        opcodeResult = prefetchQueue.pop();
        ip++;
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::opcode_0xC7() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 14;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        opcodeResult = prefetchQueue.pop(); // low byte
        ip++;
        opcodeResult = opcodeResult | ( ((word)prefetchQueue.pop()) << 8 ); // high byte
        ip++;
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }
    // result is written
    return true;
}

bool IProc_8088::jumpNotTakenByte() {
    if (jumpState == 0) {
        waitClocksCount += 3;
        jumpState = 1;
    }

    if (jumpState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;
        jumpState = 2;
    }

    if (jumpState == 2) {
        prefetchQueue.pop();
        ip++;
        jumpState++;
    }
    return true;
}

bool IProc_8088::jumpTakenByte() {
    if (jumpState == 0) {
        waitClocksCount += 9;
        jumpState = 1;
    }

    if (jumpState == 1) {
        if (!BIURequirePrefetchQueueByte()) return false;
        jumpState = 2;
    }

    if (jumpState == 2) {
        word displacement = signExtendedByte(prefetchQueue.pop());
        ip++;

        ip += displacement;
        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        jumpState++;
    }
    return true;
}

bool IProc_8088::jumpTakenWord() {
    if (jumpState == 0) {
        waitClocksCount += 7;
        jumpState = 1;
    }

    if (jumpState == 1) {
        if (!BIURequirePrefetchQueueWord()) return false;
        jumpState = 2;
    }

    if (jumpState == 2) {
        word displacement = prefetchQueue.pop(); // low byte
        ip++;
        displacement = displacement | ( ((word)prefetchQueue.pop()) << 8 ); // high byte
        ip++;

        ip += displacement;
        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        jumpState++;
    }
    return true;
}

bool IProc_8088::jumpTakenDWord() {
    if (jumpState == 0) {
        waitClocksCount += 7;
        jumpState = 1;
    }

    if (jumpState == 1) {
        if (!BIURequirePrefetchQueueDWord()) return false;
        jumpState = 2;
    }

    if (jumpState == 2) {
        word newIP = prefetchQueue.pop(); // low byte
        ip++;
        newIP = newIP | ( ((word)prefetchQueue.pop()) << 8 ); // high byte
        ip++;

        word newCS = prefetchQueue.pop(); // low byte
        ip++;
        newCS = newCS | ( ((word)prefetchQueue.pop()) << 8 ); // high byte
        ip++;

        ip = newIP;
        cs = newCS;

        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        jumpState++;
    }
    return true;
}

bool IProc_8088::opcode_0x70() {
    if (opcodeState == 0) { opcodeState = getFlagOverflow() ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x71() {
    if (opcodeState == 0) { opcodeState = (!getFlagOverflow()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x72() {
    if (opcodeState == 0) { opcodeState = getFlagCarry() ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x73() {
    if (opcodeState == 0) { opcodeState = (!getFlagCarry()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x74() {
    if (opcodeState == 0) { opcodeState = getFlagZero() ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x75() {
    if (opcodeState == 0) { opcodeState = (!getFlagZero()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x76() {
    if (opcodeState == 0) { opcodeState = (getFlagZero() || getFlagCarry()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x77() {
    if (opcodeState == 0) { opcodeState = (!getFlagZero() && !getFlagCarry()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x78() {
    if (opcodeState == 0) { opcodeState = getFlagSign() ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x79() {
    if (opcodeState == 0) { opcodeState = (!getFlagSign()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x7A() {
    if (opcodeState == 0) { opcodeState = getFlagParity() ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x7B() {
    if (opcodeState == 0) { opcodeState = (!getFlagParity()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x7C() {
    if (opcodeState == 0) { opcodeState = (getFlagSign() != getFlagOverflow()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x7D() {
    if (opcodeState == 0) { opcodeState = ((getFlagSign() == getFlagOverflow())) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x7E() {
    if (opcodeState == 0) { opcodeState = ((getFlagSign() != getFlagOverflow()) || getFlagZero()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0x7F() {
    if (opcodeState == 0) { opcodeState = ((getFlagSign() == getFlagOverflow()) && !getFlagZero()) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0xE3() {
    if (opcodeState == 0) { opcodeState = (cx == 0) ? 1 : 2; }
    if (opcodeState == 1) { if (jumpTakenByte()) opcodeState = 3; else return false; }
    if (opcodeState == 2) { if (jumpNotTakenByte()) opcodeState = 3; else return false; }
    return opcodeState == 3;
}

bool IProc_8088::opcode_0xEB() { return jumpTakenByte(); }
bool IProc_8088::opcode_0xE9() { return jumpTakenWord(); }
bool IProc_8088::opcode_0xEA() { return jumpTakenDWord(); }

bool IProc_8088::opcode_0xE8() {
    if (opcodeState == 0) {
        waitClocksCount += 8;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!push(ip + 2, 0)) return false;

        // push completed
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        return jumpTakenWord();
    }
}

bool IProc_8088::opcode_0x9A() {
    if (opcodeState == 0) {
        waitClocksCount += 21;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!push(cs, 0)) return false;

        // push completed
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!push(ip + 4, 0)) return false;

        // push completed
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        return jumpTakenDWord();
    }
}

bool IProc_8088::opcode_0xC3() {
    if (opcodeState == 0) {
        waitClocksCount += 20;
        opcodeState = 1;
    }

    if (opcodeState == 1) {

        if (!pop(0)) return false;
        // pop completed, data in opcodeResult
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        ip = opcodeResult;
        BIUPrefetchQueueAddress = ip;
        prefetchQueue.reset();
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xCB() {
    if (opcodeState == 0) {
        waitClocksCount += 34;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!pop(0)) return false;
        // pop completed, data in opcodeResult
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        ip = opcodeResult;
        BIUPrefetchQueueAddress = ip;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!pop(0)) return false;
        // pop completed, data in opcodeResult
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        cs = opcodeResult;
        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xC2() {
    if (opcodeState == 0) {
        waitClocksCount += 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {

        if (!pop(0)) return false;
        // pop completed, data in opcodeResult (temporary IP)
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!BIURequirePrefetchQueueWord()) return false;

        word immed16 = prefetchQueue.pop(); // low byte
        ip++;
        immed16 = immed16 | ( ((word) prefetchQueue.pop()) << 8); // high byte
        ip++;
        sp += immed16;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        ip = opcodeResult;
        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xCA() {
    if (opcodeState == 0) {
        waitClocksCount += 33;
        opcodeState = 1;
    }

    if (opcodeState == 1) {

        if (!pop(0)) return false;
        // pop completed, data in opcodeResult (new IP), write it to data
        dataByteLow = opcodeResult;
        dataByteHigh = (opcodeResult >> 8);
        opcodeState = 2;
    }

    if (opcodeState == 2) {

        if (!pop(0)) return false;
        // pop completed, data in opcodeResult (new CS)
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequirePrefetchQueueWord()) return false;

        word immed16 = prefetchQueue.pop(); // low byte
        ip++;
        immed16 = immed16 | ( ((word) prefetchQueue.pop()) << 8); // high byte
        ip++;
        sp += immed16;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        ip = getDataWord();
        cs = opcodeResult;
        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xE0() {
    if (opcodeState == 0) {
        cx--;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!getFlagZero() && (cx != 0)) {
            waitClocksCount += 3;
            opcodeState = 2;
        } else {
            waitClocksCount += 1;
            opcodeState = 3;
        }
    }

    // jump
    if (opcodeState == 2) { return jumpTakenByte(); }

    // do not jump
    if (opcodeState == 3) { return jumpNotTakenByte(); }
    // unachievable state
}

bool IProc_8088::opcode_0xE1() {
    if (opcodeState == 0) {
        cx--;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (getFlagZero() && (cx != 0)) {
            waitClocksCount += 2;
            opcodeState = 2;
        } else {
            waitClocksCount += 2;
            opcodeState = 3;
        }
    }

    // jump
    if (opcodeState == 2) { return jumpTakenByte(); }

    // do not jump
    if (opcodeState == 3) { return jumpNotTakenByte(); }
    // unachievable state
}

bool IProc_8088::opcode_0xE2() {
    if (opcodeState == 0) {
        cx--;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (cx != 0) {
            waitClocksCount += 1;
            opcodeState = 2;
        } else {
            waitClocksCount += 1;
            opcodeState = 3;
        }
    }

    // jump
    if (opcodeState == 2) { return jumpTakenByte(); }

    // do not jump
    if (opcodeState == 3) { return jumpNotTakenByte(); }
    // unachievable state
}

bool IProc_8088::opcode_0x90() {
    if (opcodeState == 0) {
        waitClocksCount += 3;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xD8() {
    if (opcodeState == 0) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        waitClocksCount += effectiveAddressIsRegister ? 2 : 8;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        if (isWordOperation()) waitClocksCount += 4;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xD6() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::AL, (!getFlagCarry()) ? 0 : 0xFF);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xF8() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        setFlagCarry(0);
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0xF5() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState) {
        setFlagCarry(!getFlagCarry());
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0xF9() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        setFlagCarry(1);
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0xFC() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        setFlagDirection(0);
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0xFD() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        setFlagDirection(1);
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0xFA() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        setFlagInterrupt(0);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xFB() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        setFlagInterrupt(1);
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x9F() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        ax = ((flags << 8) | (ax & 0x00FF));
        ax = ax | 0x200;
        opcodeState++;
	}
	return true;
}

bool IProc_8088::opcode_0x9E() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
		flags = (flags & 0xFF00) | ((ax & 0xD500) >> 8);
		opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x98() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        writeRegister(Register::AX, signExtendedByte(ax));
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x99() {
    if (opcodeState == 0) {
        waitClocksCount += 5;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        dx = (0x8000 & ax) ? 0xFFFF : 0;
        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x80() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 17;
        // TODO: on reg = 7, waitClocks must be equal 10 instead of 17, and 3 instead of 4
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequirePrefetchQueueByte()) return false;
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        byte pfqData = prefetchQueue.pop();
        ip++;

        switch (getREGField()) {
            case 0: opcodeResult = addBytes(effectiveAddressFetchedData, pfqData); break;
            case 1: opcodeResult = booleanOr(effectiveAddressFetchedData, pfqData); break;
            case 2: opcodeResult = addBytes(effectiveAddressFetchedData, pfqData, true); break;
            case 3: opcodeResult = subBytes(effectiveAddressFetchedData, pfqData, true); break;
            case 4: opcodeResult = booleanAnd(effectiveAddressFetchedData, pfqData); break;
            case 5: opcodeResult = subBytes(effectiveAddressFetchedData, pfqData); break;
            case 6: opcodeResult = booleanXor(effectiveAddressFetchedData, pfqData); break;
            case 7: opcodeResult = subBytes(effectiveAddressFetchedData, pfqData); break;
        }
        opcodeState = 5;
    }

    if (opcodeState == 5) {
        if (getREGField() != 7) // do not write back for CMP op (reg = 7)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x81() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 23;
        // TODO: on reg = 7, waitClocks must be equal 14 instead of 23
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 4;
    }

	if (opcodeState == 4) {
		word pfqData = prefetchQueue.pop(); // low byte
		ip++;
		pfqData = pfqData | ( ((word)prefetchQueue.pop()) << 8 ); // high byte
		ip++;
		switch (getREGField()) {
            case 0: opcodeResult = addWords(effectiveAddressFetchedData, pfqData); break;
            case 1: opcodeResult = booleanOr(effectiveAddressFetchedData, pfqData); break;
            case 2: opcodeResult = addWords(effectiveAddressFetchedData, pfqData, true); break;
            case 3: opcodeResult = subWords(effectiveAddressFetchedData, pfqData, true); break;
            case 4: opcodeResult = booleanAnd(effectiveAddressFetchedData, pfqData); break;
            case 5: opcodeResult = subWords(effectiveAddressFetchedData, pfqData); break;
            case 6: opcodeResult = booleanXor(effectiveAddressFetchedData, pfqData); break;
            case 7: opcodeResult = subWords(effectiveAddressFetchedData, pfqData); break;
        }

        opcodeState = 5;
    }

    if (opcodeState == 5) {
        if (getREGField() != 7) // do not write back for CMP op (reg = 7)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x83() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 23;
        // TODO: on reg = 7, waitClocks must be equal 14 instead of 23
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }
    // effective address calculated

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (!BIURequirePrefetchQueueByte()) return false;
        opcodeState = 4;
    }

	if (opcodeState == 4) {
        word pfqData = signExtendedByte(prefetchQueue.pop());
		ip++;
		switch (getREGField()) {
            case 0: opcodeResult = addWords(effectiveAddressFetchedData, pfqData); break;
            case 1: opcodeResult = booleanOr(effectiveAddressFetchedData, pfqData); break;
            case 2: opcodeResult = addWords(effectiveAddressFetchedData, pfqData, true); break;
            case 3: opcodeResult = subWords(effectiveAddressFetchedData, pfqData, true); break;
            case 4: opcodeResult = booleanAnd(effectiveAddressFetchedData, pfqData); break;
            case 5: opcodeResult = subWords(effectiveAddressFetchedData, pfqData); break;
            case 6: opcodeResult = booleanXor(effectiveAddressFetchedData, pfqData); break;
            case 7: opcodeResult = subWords(effectiveAddressFetchedData, pfqData); break;
        }

        opcodeState = 5;
    }

    if (opcodeState == 5) {
        if (getREGField() != 7) // do not write back for CMP op (reg = 7)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xF6() {
    if (opcodeState == 0) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (getREGField() == 0 || getREGField() == 1)
            if (!BIURequirePrefetchQueueByte()) return false;

        opcodeState = 3;
    }

    if (opcodeState == 3) {
        switch (getREGField()) {
            case 0: ;// duplicate with 1
			case 1: {
                waitClocksCount += effectiveAddressIsRegister ? 5 : 11; // TEST
				byte data = prefetchQueue.pop();
				ip++;
				booleanAnd(effectiveAddressFetchedData, data);
			}
            break;

            case 2: {
			waitClocksCount += effectiveAddressIsRegister ? 3 : 16; // NOT
			opcodeResult = ~effectiveAddressFetchedData;
			}
			break;

			case 3: {
			waitClocksCount += effectiveAddressIsRegister ? 3 : 16; // NEG
			opcodeResult = subBytes((byte) 0, effectiveAddressFetchedData);
			}
			break;

			case 4: {
                waitClocksCount += effectiveAddressIsRegister ? 65 : 69; // MUL
                writeRegister(Register::AX, effectiveAddressFetchedData * (fetchRegister(Register::AX) & 0xFF));
                if ((ax & 0xFF00) != 0) {
                    setFlagOverflow(1);
                    setFlagCarry(1);
                } else {
                    setFlagOverflow(0);
                    setFlagCarry(0);
                }

                flags = flags & 0xFFBF; // clear zero bit to appear
            }
            break;

            case 5: {
                waitClocksCount += effectiveAddressIsRegister ? 79 : 85; // IMUL
                writeRegister(Register::AX, effectiveAddressFetchedData * (fetchRegister(Register::AX) & 0xFF));
                __int16 tempAX = (__int16) ax;
                if (tempAX > 255 || tempAX <= -256) {
                    setFlagOverflow(1);
                    setFlagCarry(1);
                } else {
                    setFlagOverflow(0);
                    setFlagCarry(0);
                }
                flags = flags & 0xFFBF; // clear zero bit to appear
            }
            break;

            case 6: {
                if (!interrupted)
                    waitClocksCount += effectiveAddressIsRegister ? 75 : 81; // DIV
                if (effectiveAddressFetchedData == 0) return div0InterruptHandler();
                else {
                    byte quo = ax / effectiveAddressFetchedData;
                    byte rem = ax % effectiveAddressFetchedData;
                    ax = rem << 8;
                    writeRegister(Register::AL, quo);
                }
              }
                break;
            case 7: {
                if (!interrupted)
                    waitClocksCount += effectiveAddressIsRegister ? 97 : 104; // IDIV
                __int8 signedDivr = (__int8) effectiveAddressFetchedData;
                if (signedDivr == 0) return div0InterruptHandler();
                else {
                    __int8 signedQuo = (__int8)(((__int16) ax) / signedDivr);
                    __int8 signedRem = (__int8)(((__int16) ax) % signedDivr);
                    ax = (word) (signedRem << 8); // AH
                    writeRegister(Register::AL, (byte) signedQuo);
                }
            }
                break;
        }

        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (getREGField() == 2 || getREGField() == 3)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;

        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xF7() {
    if (opcodeState == 0) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (getREGField() == 0 || getREGField() == 1)
            if (!BIURequirePrefetchQueueWord()) return false;

        opcodeState = 3;
    }

	if (opcodeState == 3) {
		unsigned __int32 res;
        switch (getREGField()) {
            case 0: // duplicate with 1
            case 1: {
                waitClocksCount += effectiveAddressIsRegister ? 5 : 15; // TEST
                word data = prefetchQueue.pop(); // low byte
                ip++;
                data = data | (((word) prefetchQueue.pop()) << 8); // high byte
                ip++;
                booleanAnd(effectiveAddressFetchedData, data);
            }
                break;
            case 2: {
                waitClocksCount += effectiveAddressIsRegister ? 3 : 24; // NOT
                opcodeResult = ~effectiveAddressFetchedData;
            }
                break;
            case 3: {
                waitClocksCount += effectiveAddressIsRegister ? 3 : 24; // NEG
                opcodeResult = subWords((word) 0, effectiveAddressFetchedData);
            }
                break;
            case 4: {
                waitClocksCount += effectiveAddressIsRegister ? 110 : 121; // MUL
                res = (unsigned __int32) effectiveAddressFetchedData * (unsigned __int32) ax;
                dx = (word) (res >> 16);
                ax = (word) (res & 0x0000FFFF);

                if (dx != 0) {
                    setFlagOverflow(1);
                    setFlagCarry(1);
                } else {
                    setFlagOverflow(0);
                    setFlagCarry(0);
                }

                flags = flags & 0xFFBF; // temp clear zero bit
            }
                break;
            case 5: {
                waitClocksCount += effectiveAddressIsRegister ? 131 : 137; // IMUL
                word fetched = effectiveAddressFetchedData;
                unsigned __int32 fetchedPositive;
                unsigned __int32 axPositive;
                unsigned __int32 resPositive;

                fetchedPositive = (0x8000 & fetched) ? (~fetched) + 1 : fetched;
                axPositive = (0x8000 & ax) ? (~ax) + 1 : ax;
                resPositive = fetchedPositive * axPositive;
                if (resPositive > 0xFFFF) {
                    setFlagCarry(1);
                    setFlagOverflow(1);
                } else {
                    setFlagCarry(0);
                    setFlagOverflow(0);
                }

                res = (unsigned __int32) ((__int16) fetched * (__int16) ax);
                dx = (word) (res >> 16);
                ax = (word) (res & 0x0000FFFF);

                flags = flags & 0xFFBF; // clear zero bit to appear
            }
                    break;
            case 6: {
                if (!interrupted)
                    waitClocksCount += effectiveAddressIsRegister ? 143 : 157; // DIV
                unsigned __int32 numr;
                unsigned __int16 divr;

//                numr = ((unsigned __int32)dx << 16) | (unsigned __int32) ax; WTF?
                numr = (unsigned __int32) ax;
                divr = (unsigned __int32) effectiveAddressFetchedData;

                if (divr == 0) return div0InterruptHandler();
                else {
                    ax = (word) (numr / divr);
                    dx = (word) (numr % divr);
                }
            }
                break;
            case 7: {
                if (!interrupted)
                    waitClocksCount += effectiveAddressIsRegister ? 97 : 104; // IDIV
//                __int32 numrSigned = ((__int32) dx << 16) | (__int32) ax; WTF?
                __int32 numrSigned = (__int32) ax;
                __int16 divrSigned = (__int16) effectiveAddressFetchedData;

                if (divrSigned == 0) return div0InterruptHandler();
                else {
                    ax = (word) (numrSigned / divrSigned);
                    dx = (word) (numrSigned % divrSigned);
                }
            }
                break;
        }

        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (getREGField() == 2 || getREGField() == 3)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;

        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xFE() {
    if (opcodeState == 0) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        switch (getREGField()) {
            case 0: { // INC R/M8
                forceWordOperation = false;
                waitClocksCount += effectiveAddressIsRegister ? 3 : 15;
                opcodeResult = addBytes(effectiveAddressFetchedData, 1, false, true);
            }
            break;
            case 1: { // DEC R/M8
                forceWordOperation = false;
                waitClocksCount += effectiveAddressIsRegister ? 3 : 15;
                opcodeResult = subBytes(effectiveAddressFetchedData, 1, false, true);
            }
                break;

            case 2: ; // duplicated TODO()
            case 3: ; // duplicated
            case 4: ; // duplicated
            case 5: ; // duplicated
            case 6: ; // duplicated
            case 7: ; // duplicated
                break;
        }

        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (getREGField() == 0 || getREGField() == 1)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;

        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xFF() {
    if (opcodeState == 0) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        switch (getREGField()) {
            case 0: { // INC R/M16
                forceWordOperation = false;
                waitClocksCount += effectiveAddressIsRegister ? 3 : 23;
                opcodeResult = addWords(effectiveAddressFetchedData, (word) 1, false, true);
            }
                break;
            case 1: { // DEC R/M16
                forceWordOperation = false;
                waitClocksCount += effectiveAddressIsRegister ? 3 : 23;
                opcodeResult = subWords(effectiveAddressFetchedData, (word) 1, false, true);
            }
                break;

            case 2: ; // TODO
            case 3: ; // TODO
            case 4: ; // TODO
            case 5: ; // TODO
            case 6: ; // TODO
            case 7: ; // TODO
                break;
        }

        opcodeState = 3;
    }

    if (opcodeState == 3) {
        if (getREGField() == 0 || getREGField() == 1)
            if (!writeBackEffectiveAddress(opcodeResult)) return false;

        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xA8() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        forceWordOperation = 0;
        if (!BIURequirePrefetchQueueByte()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        booleanAnd(fetchRegister(Register::AL), prefetchQueue.pop());
        ip++;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xA9() {
    if (opcodeState == 0) {
        waitClocksCount += 4;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        forceWordOperation = true;
        if (!BIURequirePrefetchQueueWord()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        word data = prefetchQueue.pop(); // low byte
        ip++;
        data = data | ( ((word) prefetchQueue.pop()) << 8); // high byte
        ip++;
        booleanAnd(fetchRegister(Register::AX), data);
        opcodeState++;
    }

    forceWordOperation = false;
    return true;
}

bool IProc_8088::opcode_0x84() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 9;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        booleanAnd(effectiveAddressFetchedData, fetchRegister((Register) getREGFieldTable()));
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x85() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 3 : 13;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        booleanAnd(effectiveAddressFetchedData, fetchRegister((Register) getREGFieldTable()));
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x86() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 17;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        opcodeResult = effectiveAddressFetchedData;

        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }

    if (opcodeState == 4) {
		if (!writeBackEffectiveAddress(fetchedRegister)) return false;
        opcodeState = 5;
    }

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x87() {
    if (opcodeState == 0) {
        waitClocksCount += effectiveAddressIsRegister ? 4 : 25;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        opcodeResult = effectiveAddressFetchedData;

        fetchRegister((Register) getREGFieldTable());
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!writeBackEffectiveAddress(fetchedRegister)) return false;
        opcodeState = 5;
    }

    if (opcodeState == 5) {
        writeRegister((Register) getREGFieldTable(), opcodeResult);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x91() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::CX));
        writeRegister(Register::CX, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x92() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::DX));
        writeRegister(Register::DX, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x93() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::BX));
        writeRegister(Register::BX, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x94() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::SP));
        writeRegister(Register::SP, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x95() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::BP));
        writeRegister(Register::BP, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x96() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::SI));
        writeRegister(Register::SI, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x97() {
    if (opcodeState == 0) {
        waitClocksCount += 3;

        word tmp = fetchRegister(Register::AX);
        writeRegister(Register::AX, fetchRegister(Register::DI));
        writeRegister(Register::DI, tmp);

        opcodeState++;
    }
    return true;
}

bool IProc_8088::opcode_0x8D() {
    if (opcodeState == 0) {
        waitClocksCount += 2;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        writeRegister((Register) getREGFieldTable(), effectiveAddress);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xC4() {
    if (opcodeState == 0) {
        waitClocksCount += 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        forceWordOperation = true;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        writeRegister((Register) (0x08 | getREGField()), effectiveAddressFetchedData);
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        effectiveAddress += 2;
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!fetchDataOnEffectiveAddress()) return false;
        es = effectiveAddressFetchedData;
        opcodeState++;
    }

    forceWordOperation = false;
    return true;
}

bool IProc_8088::opcode_0xC5() {
    if (opcodeState == 0) {
        waitClocksCount += 24;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!requireEffectiveAddressCalculation()) return false;
        forceWordOperation = true;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!fetchDataOnEffectiveAddress()) return false;
        writeRegister((Register) (0x08 | getREGField()), effectiveAddressFetchedData);
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        effectiveAddress += 2;
        opcodeState = 4;
    }

    if (opcodeState == 4) {
        if (!fetchDataOnEffectiveAddress()) return false;
        ds = effectiveAddressFetchedData;
        opcodeState++;
    }

    forceWordOperation = false;
    return true;
}

// interrupts

bool IProc_8088::opcode_0xCC() {
    if (!interrupted) {
        waitClocksCount += 1;
        interruptState = 0;
        throw std::logic_error("Возникло прерывание: breakpoint!");
        interrupted = true;
    }

    return interruptHandler(3); // breakpoint interrupt
}

bool IProc_8088::opcode_0xCE() {
    if (opcodeState == 0) {
        if (!getFlagOverflow()) {
            waitClocksCount += 4;
            opcodeState = 2;
        } else {
            waitClocksCount += 2;
            opcodeState = 1;
        }
    }

    if (opcodeState == 1) {
        if (!interrupted) {
            interruptState = 0;
            throw std::logic_error("Возникло прерывание: переполнение!");
            interrupted = true;
        }
        return interruptHandler(4); // interrupt on overflow
    }

    return true;
}

bool IProc_8088::opcode_0xCD() {
    if (opcodeState == 0) {
        if (!BIURequirePrefetchQueueByte()) return false;
        opcodeResult = prefetchQueue.pop();
        ip++;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!interrupted) {
            interruptState = 0;
            throw std::logic_error("Возникло прерывание типа " + std::to_string(opcodeResult));
            interrupted = true;
        }

        return interruptHandler(opcodeResult); // custom interrupt
    }
    // unachievable branch here;
}

bool IProc_8088::opcode_0xCF() {
    if (opcodeState == 0) {
		waitClocksCount += 44;
		popState = 0;
        opcodeState = 1;
    }

	if (opcodeState == 1) {
		if (!pop(0)) return false; // opcodeResult = pop result
        ip = opcodeResult;
		opcodeState = 2;
		popState = 0;
	}

    if (opcodeState == 2) {
		if (!pop(0)) return false; // opcodeResult = pop result
        cs = opcodeResult;
		opcodeState = 3;
		popState = 0;
    }

    if (opcodeState == 3) {
        if (!pop(0)) return false; // opcodeResult = pop result
		flags = 0x0FD5 & opcodeResult;
        popState = 0;

        prefetchQueue.reset();
        BIUPrefetchQueueAddress = ip;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xEC() {
    if (opcodeState == 0) {
        waitClocksCount += 8;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequireOperationByte(BIUAction::IOR, SegmentRegister::SEGMENT_00, dx, 0))
            return false;

        opcodeResult = BIUDataIn;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AX, opcodeResult);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xE4() {
    if (opcodeState == 0) {
        waitClocksCount += 10;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte())
            return false;

        opcodeResult = ((byte) 0x00FF) & prefetchQueue.pop();
        ip++;

        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!BIURequireOperationByte(BIUAction::IOR, SegmentRegister::SEGMENT_00, opcodeResult, 0))
            return false;

        // reuse opcodeResult
        opcodeResult = BIUDataIn;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AX, opcodeResult);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xED() {
    if (opcodeState == 0) {
        waitClocksCount += 12;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequireOperationWord(BIUAction::IOR, SegmentRegister::SEGMENT_00, dx, 0))
            return false;

        opcodeResult = BIUDataIn;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        writeRegister(Register::AX, opcodeResult);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xE5() {
    if (opcodeState == 0) {
        waitClocksCount += 14;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte())
            return false;

        opcodeResult = ((byte) 0x00FF) & prefetchQueue.pop();
        ip++;

        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!BIURequireOperationWord(BIUAction::IOR, SegmentRegister::SEGMENT_00, opcodeResult, 0))
            return false;

        // reuse opcodeResult
        opcodeResult = BIUDataIn;
        opcodeState = 3;
    }

    if (opcodeState == 3) {
        writeRegister(Register::AX, opcodeResult);
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xEE() {
    if (opcodeState == 0) {
        waitClocksCount += 8;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequireOperationByte(BIUAction::IOW, SegmentRegister::SEGMENT_00, dx, ax))
            return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xEF() {
    if (opcodeState == 0) {
        waitClocksCount += 12;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequireOperationWord(BIUAction::IOW, SegmentRegister::SEGMENT_00, dx, ax))
            return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xE6() {
    if (opcodeState == 0) {
        waitClocksCount += 10;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte())
            return false;

        opcodeResult = ((byte) 0x00FF) & prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!BIURequireOperationByte(BIUAction::IOW, SegmentRegister::SEGMENT_00, opcodeResult, ax))
            return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0xE7() {
    if (opcodeState == 0) {
        waitClocksCount += 14;
        opcodeState = 1;
    }

    if (opcodeState == 1) {
        if (!BIURequirePrefetchQueueByte())
            return false;

        opcodeResult = ((byte) 0x00FF) & prefetchQueue.pop();
        ip++;
        opcodeState = 2;
    }

    if (opcodeState == 2) {
        if (!BIURequireOperationWord(BIUAction::IOW, SegmentRegister::SEGMENT_00, opcodeResult, ax))
            return false;
        opcodeState++;
    }

    return true;
}

bool IProc_8088::opcode_0x26() {
	effectiveAddressSegment = SegmentRegister::ES;
    segmentRegSpecified = true;
	return true;
}

bool IProc_8088::opcode_0x2E() {
	effectiveAddressSegment = SegmentRegister::CS;
	segmentRegSpecified = true;
	return true;
}

bool IProc_8088::opcode_0x36() {
	effectiveAddressSegment = SegmentRegister::SS;
	segmentRegSpecified = true;
	return true;
}

bool IProc_8088::opcode_0x3E() {
	effectiveAddressSegment = SegmentRegister::DS;
    segmentRegSpecified = true;
	return true;
}
