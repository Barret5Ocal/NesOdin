package NES

STACK: u16 : 0x0100;
STACK_RESET: u8 : 0xfd;

cpu :: struct
{
    RegisterA : u8,
    RegisterX : u8,
    RegisterY : u8,
    Status : cpu_flags,
    StackPointer : u8,
    ProgramCounter : u16,
    Memory : [0xFFFF]u8,
}

addressing_mode :: enum 
{
    IMMEDIATE,
    ZEROPAGE,
    ZEROPAGE_X,
    ZEROPAGE_Y,
    ABSOLUTE,
    ABSOLUTE_X,
    ABSOLUTE_Y,
    INDIRECT_X,
    INDIRECT_Y,
    NONEADDRESSING,
}

flags :: enum{CARRY, ZERO, INTERRUPUT_DISABLE, DECIMAL_MODE, BREAK, BREAK2, OVERFLOW, NEGATIV,};

cpu_flags :: bit_set[flags; u8];

import "core:fmt"

MemReadu16 :: proc(Cpu : ^cpu, Pos : u16) -> u16
{
    Lo := cast(u16)MemRead(Cpu, Pos);
    Hi := cast(u16)MemRead(Cpu, Pos + 1);
    return (Hi << 8) | (cast(u16)Lo); // NOTE(Barret5Ocal): Be careful about this. It's different than the tutorial because it made the program work
    
}

MemWriteu16 :: proc(Cpu : ^cpu, Pos : u16, Data : u16)
{
    Lo := cast(u8)(Data >> 8);
    Hi := cast(u8)(Data & 0xff);
    MemWrite(Cpu, Pos, Hi);
    MemWrite(Cpu, Pos + 1, Lo)
}

MemRead :: proc(Cpu : ^cpu, Address : u16) -> u8
{
    return Cpu.Memory[Address];
}

MemWrite :: proc(Cpu : ^cpu, Address : u16, Value : u8)
{
    Cpu.Memory[Address] = Value;
}

StackPop :: proc (Cpu : ^cpu) -> u8
{
    Cpu.StackPointer += 1; 
    return MemRead(Cpu, cast(u16)STACK + cast(u16)Cpu.StackPointer);
}

StackPush :: proc (Cpu : ^cpu, Data : u8) 
{
    MemWrite(Cpu, cast(u16)STACK + cast(u16)Cpu.StackPointer, Data);
    Cpu.StackPointer -= 1;  
}

StackPushu16 :: proc (Cpu : ^cpu, Data : u16)
{
    Lo := cast(u8)(Data >> 8);
    Hi := cast(u8)(Data & 0xff);
    StackPush(Cpu, Hi);
    StackPush(Cpu, Lo);
}

StackPopu16 :: proc (Cpu : ^cpu) -> u16
{
    
    Lo : u16 = cast(u16)StackPop(Cpu);
    Hi : u16 = cast(u16)StackPop(Cpu);
    
    //return (Hi << 8) | (cast(u16)Lo); 
    return (Lo << 8) | (cast(u16)Hi); 
    // NOTE(Barret5Ocal): Be think that this fixed the problem but be careful. It still might not work
}

// TODO(Barret5Ocal): I have been having trouble with my reads and writes so I need to look into this to see if I am grabbing the values correctly
GetOperandAddress :: proc(Cpu : ^cpu, Mode : addressing_mode) -> u16
{
    switch Mode
    {
        case addressing_mode.IMMEDIATE: 
        {
            return Cpu.ProgramCounter;
        }
        case addressing_mode.ZEROPAGE: 
        {
            return cast(u16)MemRead(Cpu, Cpu.ProgramCounter);
        }
        case addressing_mode.ABSOLUTE:
        {
            return MemReadu16(Cpu, Cpu.ProgramCounter);
        }
        case addressing_mode.ZEROPAGE_X:
        {
            Pos := MemRead(Cpu, Cpu.ProgramCounter);
            Addr := cast(u16)(Pos + Cpu.RegisterX); // NOTE(Barret5Ocal): Ints auto wrap in Odin
            return Addr;
        }
        case addressing_mode.ZEROPAGE_Y:
        {
            Pos := MemRead(Cpu, Cpu.ProgramCounter);
            Addr := cast(u16)(Pos + Cpu.RegisterY);
            return Addr;
        }
        case addressing_mode.ABSOLUTE_X:
        {
            Base := MemReadu16(Cpu, Cpu.ProgramCounter);
            Addr := Base + cast(u16)Cpu.RegisterX;
            return Addr;
        }
        case addressing_mode.ABSOLUTE_Y:
        {
            Base := MemReadu16(Cpu, Cpu.ProgramCounter);
            Addr := Base + cast(u16)Cpu.RegisterY;
            return Addr;
        }
        // TODO(Barret5Ocal): The addressing for the indirect modes might be the cause of the current problem but changing them causes a game break. 
        case addressing_mode.INDIRECT_X:
        {
            Base := MemRead(Cpu, Cpu.ProgramCounter);
            
            Ptr : u8 = (cast(u8) Base) + Cpu.RegisterX; 
            // NOTE(Barret5Ocal): This code just creates an address based on the values that are in Base + the value of register x. The question is why is this used for the sankeDraw code 
            Lo := MemRead(Cpu, cast(u16)Ptr);
            Hi := MemRead(Cpu, cast(u16)Ptr + 1);
            Result :=  (cast(u16)Hi) << 8 | (cast(u16)Lo);
            //Result :=  (cast(u16)Lo) << 8 | (cast(u16)Hi);
            return Result;
        }
        case addressing_mode.INDIRECT_Y:
        {
            Base := MemRead(Cpu, Cpu.ProgramCounter);
            
            Lo := MemRead(Cpu, cast(u16)Base);
            Hi := MemRead(Cpu, cast(u16)((cast(u8)Base) + 1));
            DerefBase := (cast(u16)Hi) << 8 | (cast(u16)Lo);
            //DerefBase := (cast(u16)Lo) << 8 | (cast(u16)Hi);
            Deref := DerefBase + cast(u16)Cpu.RegisterY;
            return Deref
        }
        case addressing_mode.NONEADDRESSING:
        {
            assert(false);
        }
        
    }
    return 0;
}

Reset :: proc(Cpu : ^cpu)
{
    Cpu.RegisterA = 0;
    Cpu.RegisterX = 0;
    Cpu.RegisterY = 0;
    Cpu.StackPointer = STACK_RESET;
    
    StatusReset : u8 = 0b100100;
    Cpu.Status = transmute(cpu_flags)StatusReset;
    
    Cpu.ProgramCounter = MemReadu16(Cpu, 0xFFFC);
    
    // NOTE(Barret5Ocal): DEBUG
    debug_data.ProgramStart = Cpu.ProgramCounter;
}

Load :: proc(Cpu : ^cpu, Program : [dynamic]u8)
{
    copy(Cpu.Memory[0x0600:], Program[:]);
    MemWriteu16(Cpu, 0xFFFC, 0x0600);
    
}

LoadAndRun :: proc(Cpu : ^cpu, Program : [dynamic]u8)
{
    Load(Cpu, Program);
    Reset(Cpu);
    Run(Cpu);
}

Run :: proc (Cpu : ^cpu)
{
    RunWithCallback(Cpu, nil, false);
}

RunWithCallback :: proc (Cpu : ^cpu, Sdl : ^sdl_package, Callback : bool)
{
    for 
    {
        if debug_data.State == debug_state.NORMAL 
        {
            
            RunOpcode(Cpu);
            
            // NOTE(Barret5Ocal): DEBUG
        }
        
        if Callback do EngineLevel(Cpu, Sdl);
    }
}

RunOpcode :: proc(Cpu : ^cpu)
{
    Code := MemRead(Cpu, Cpu.ProgramCounter);
    Cpu.ProgramCounter += 1;
    
    ProgramCounterState := Cpu.ProgramCounter;
    
    Opcode := OpcodeMap[Code];
    
    switch Code 
    {
        case 0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71: Adc(Cpu, Opcode.AddressingMode);
        
        case 0x29, 0x25, 0x35, 0x2d, 0x3d, 0x39, 0x21, 0x31:  
        And(Cpu, Opcode.AddressingMode);
        
        case 0xA9 , 0xA5 , 0xB5, 0xAD , 0xBD , 0xB9 , 0xA1 , 0xB1: Lda(Cpu, Opcode.AddressingMode);
        
        case 0x85 , 0x95 , 0x8D , 0x9D , 0x99 , 0x81 , 0x91: Sta(Cpu, Opcode.AddressingMode);
        
        case 0xAA: Tax(Cpu);
        
        case 0xA8: Tay(Cpu);
        
        case 0xE8: Inx(Cpu);
        
        case 0xC8: Iny(Cpu);
        
        case 0x0A: AslAccumulator(Cpu);
        
        case 0x06, 0x16, 0x0E, 0x1E: Asl(Cpu, Opcode.AddressingMode);
        
        case 0x90: Branch(Cpu, cpu_flags.CARRY not_in Cpu.Status);
        case 0xB0: Branch(Cpu, cpu_flags.CARRY in Cpu.Status);
        case 0xF0: Branch(Cpu, cpu_flags.ZERO in Cpu.Status);
        
        case 0x24, 0x2C: Bit(Cpu, Opcode.AddressingMode);
        
        case 0x30: Branch(Cpu, cpu_flags.NEGATIV in Cpu.Status);
        case 0xD0: Branch(Cpu, cpu_flags.ZERO not_in Cpu.Status);
        case 0x10: Branch(Cpu, cpu_flags.NEGATIV not_in Cpu.Status);
        case 0x50: Branch(Cpu, cpu_flags.OVERFLOW not_in Cpu.Status);
        case 0x70: Branch(Cpu, cpu_flags.OVERFLOW in Cpu.Status);
        
        case 0x18: ClearCarryFlag(Cpu);
        case 0xD8: Cpu.Status -= {.DECIMAL_MODE};
        case 0x58: Cpu.Status -= {.INTERRUPUT_DISABLE};
        case 0xB8: Cpu.Status -= {.OVERFLOW};
        
        case 0xC9, 0xC5, 0xD5, 0xCD, 0xDD, 0xD9, 0xC1, 0xD1: Compare(Cpu, Opcode.AddressingMode, Cpu.RegisterA);
        
        case 0xE0, 0xE4, 0xEC: Compare(Cpu, Opcode.AddressingMode, Cpu.RegisterX);
        
        case 0xC0, 0xC4, 0xCC: Compare(Cpu, Opcode.AddressingMode, Cpu.RegisterY);
        
        case 0xC6, 0xD6, 0xCE, 0xDE: Dec(Cpu, Opcode.AddressingMode);
        
        case 0xCA: Dex(Cpu);
        
        case 0x88: Dey(Cpu);
        
        case 0x49, 0x45, 0x55, 0x4D, 0x5D, 0x59, 0x41, 0x51: Eor(Cpu, Opcode.AddressingMode);
        
        case 0xE6, 0xF6, 0xEE, 0xFE: Inc(Cpu, Opcode.AddressingMode);
        
        case 0x4C: 
        {
            Addr := MemReadu16(Cpu, Cpu.ProgramCounter);
            Cpu.ProgramCounter = Addr;
        }
        
        case 0x6C: 
        {
            Mem := MemReadu16(Cpu, Cpu.ProgramCounter);
            
            IndirectRef : u16;
            if Mem & 0x00FF == 0x00FF
            {
                Lo := MemRead(Cpu, cast(u16)Mem);
                Hi := MemRead(Cpu, cast(u16)Mem & 0xFF00);
                IndirectRef = (cast(u16)Hi) << 8 | (cast(u16)Lo);
            }
            else 
            {
                IndirectRef = MemReadu16(Cpu, Mem);
            }
        }
        
        case 0x20: 
        {
            StackPushu16(Cpu, Cpu.ProgramCounter + 2 - 1);
            TargetAddr := MemReadu16(Cpu, Cpu.ProgramCounter);
            Cpu.ProgramCounter = TargetAddr; 
        }
        
        case 0xA2, 0xA6, 0xB6, 0xAE, 0xBE: Ldx(Cpu, Opcode.AddressingMode);
        
        case 0xA0, 0xA4, 0xB4, 0xAC, 0xBC: Ldy(Cpu, Opcode.AddressingMode);
        
        case  0x4A: LsrAccumulator(Cpu);
        
        case 0x46, 0x56, 0x4E, 0x5E: Lsr(Cpu, Opcode.AddressingMode);
        
        case 0x09, 0x05, 0x15, 0x0D, 0x1D, 0x19, 0x01, 0x11: Ora(Cpu, Opcode.AddressingMode);
        
        case 0x48: StackPush(Cpu, Cpu.RegisterA);
        
        case 0x08: StackPush(Cpu, transmute(u8)Cpu.Status);
        
        case 0x68: Pla(Cpu);
        
        case 0x2A: RolAccumulator(Cpu);
        case 0x26, 0x36, 0x2E, 0x3E: Rol(Cpu, Opcode.AddressingMode);
        
        case 0x6A: RorAccumulator(Cpu);
        case 0x66, 0x76, 0x6E, 0x7E: Ror(Cpu, Opcode.AddressingMode);
        
        case 0x40: 
        {
            Cpu.Status = transmute(bit_set[flags; u8])StackPop(Cpu);
            Cpu.Status -= {.BREAK};
            Cpu.Status += {.BREAK2};
            
            Cpu.ProgramCounter = StackPopu16(Cpu);
        }
        
        case 0x60: Cpu.ProgramCounter = StackPopu16(Cpu) + 1;
        
        case 0xE9, 0xE5, 0xF5, 0xED, 0xFD, 0xF9, 0xE1, 0xF1: Sbc(Cpu, Opcode.AddressingMode);
        
        case 0x38: SetCarryFlag(Cpu);
        
        case 0xF8: Cpu.Status += {.DECIMAL_MODE};
        
        case 0x78: Cpu.Status += {.INTERRUPUT_DISABLE};
        
        case 0x86, 0x96, 0x8E: 
        {
            Addr := GetOperandAddress(Cpu, Opcode.AddressingMode);
            MemWrite(Cpu, Addr, Cpu.RegisterX);
        }
        
        case 0x84, 0x94, 0x8C: 
        {
            Addr := GetOperandAddress(Cpu, Opcode.AddressingMode);
            MemWrite(Cpu, Addr, Cpu.RegisterY);
        }
        
        case 0xBA: 
        {
            Cpu.RegisterX = Cpu.StackPointer; 
            UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
        }
        
        case 0x8A:
        {
            Cpu.RegisterA = Cpu.RegisterX;
            UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterA);
        }
        
        case 0x9A:
        {
            Cpu.StackPointer = Cpu.RegisterX;
        }
        
        case 0x98:
        {
            Cpu.RegisterA = Cpu.RegisterY;
            UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterA);
        }
        
        
        
        case 0xEA: {}
        case 0x00: return;
        
        case: assert(false);
        
    }
    
    if ProgramCounterState == Cpu.ProgramCounter 
    {
        Cpu.ProgramCounter += cast(u16)(Opcode.Len - 1);
    }
    
}

SetRegisterA :: proc(Cpu : ^cpu, Result : u8)
{
    Cpu.RegisterA = Result;
    UpdateZeroAndNegativeFlags(Cpu, Result);
}

SetCarryFlag :: proc(Cpu : ^cpu)
{
    Cpu.Status += {.CARRY};
}

ClearCarryFlag :: proc(Cpu : ^cpu)
{
    Cpu.Status -= {.CARRY};
}

Branch :: proc(Cpu : ^cpu, Flag : bool)
{
    if Flag
    {
        Jump : i8 = cast(i8)MemRead(Cpu, Cpu.ProgramCounter);
        JumpAdd := Cpu.ProgramCounter + 1 + cast(u16)Jump;
        Cpu.ProgramCounter = JumpAdd;
    }
}

Compare :: proc(Cpu : ^cpu, AddressingMode : addressing_mode, Value : u8)
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    
    if Data <= Value
    {
        Cpu.Status += {.CARRY};
    }
    else 
    {
        Cpu.Status -= {.CARRY};
    }
    
    UpdateZeroAndNegativeFlags(Cpu, Value - Data);
}

AddToRegisterA :: proc(Cpu : ^cpu, Value : u8)
{
    // NOTE(Barret5Ocal): Carry Flay is set if you overflow a unsigned addition or subtraction. Overflow is set if you overflow a signed addition or subtraction.
    Sum : u16 = cast(u16)Cpu.RegisterA + cast(u16)Value + (cpu_flags.CARRY in Cpu.Status ? 1 : 0); 
    
    if Carry := Sum > 0xff; Carry 
    {
        Cpu.Status += {.CARRY};
    }
    else 
    { 
        Cpu.Status -= {.CARRY};
    }
    
    Result := cast(u8)Sum;
    
    if (Value ~ Result) & (Result ~ Cpu.RegisterA) & 0x80 != 0
    {
        Cpu.Status += {.OVERFLOW};
    }
    else
    {
        Cpu.Status -= {.OVERFLOW};
    }
    
    SetRegisterA(Cpu, Result);
}

Adc :: proc(Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Value := MemRead(Cpu, Addr);
    
    AddToRegisterA(Cpu, Value);
}

And :: proc(Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Value := MemRead(Cpu, Addr);
    
    Result := Cpu.RegisterA & Value;
    SetRegisterA(Cpu, Result);
}

AslAccumulator :: proc(Cpu : ^cpu)
{
    Data := Cpu.RegisterA;
    if Data >> 7 == 1 
    {
        Cpu.Status += {.CARRY};
    }
    else 
    {
        Cpu.Status -= {.CARRY};
    }
    
    Data = Data << 1; 
    SetRegisterA(Cpu, Data);
}

Asl :: proc(Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Data := MemRead(Cpu, Addr);
    
    if Data >> 7 == 1 
    {
        Cpu.Status += {.CARRY};
    }
    else 
    {
        Cpu.Status -= {.CARRY};
    }
    
    Data = Data << 1; 
    MemWrite(Cpu, Addr, Data);
    UpdateZeroAndNegativeFlags(Cpu, Data);
}

Bit :: proc(Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr : u16 = GetOperandAddress(Cpu, AddessingMode);
    Value : u8 = MemRead(Cpu, Addr);
    Result : u8 = Cpu.RegisterA & Value;
    if Result == 0 
    {
        Cpu.Status += {.ZERO};
    }
    else 
    {
        Cpu.Status -= {.ZERO};
    }
    
    if Value & 0b10000000 > 0
    {
        Cpu.Status += {.NEGATIV};
    }
    else 
    {
        Cpu.Status -= {.NEGATIV};
    }
    
    if Value & 0b01000000 > 0
    {
        Cpu.Status += {.OVERFLOW};
    }
    else 
    {
        Cpu.Status -= {.OVERFLOW};
    }
    
}

Lda :: proc(Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Value := MemRead(Cpu, Addr);
    
    Cpu.RegisterA = Value; 
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterA);
}


Ldx :: proc (Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Value := MemRead(Cpu, Addr);
    
    Cpu.RegisterX = Value;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
}

Ldy :: proc (Cpu : ^cpu, AddessingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Value := MemRead(Cpu, Addr);
    
    Cpu.RegisterY = Value;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterY);
}

Tax :: proc(Cpu : ^cpu)
{
    Cpu.RegisterX = Cpu.RegisterA;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
}

Tay :: proc(Cpu : ^cpu)
{
    Cpu.RegisterY = Cpu.RegisterA;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterY);
}

Inx :: proc(Cpu : ^cpu)
{
    Cpu.RegisterX += 1;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
}


Iny :: proc(Cpu : ^cpu)
{
    Cpu.RegisterY += 1;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterY);
}

Sta :: proc(Cpu : ^cpu, AddressingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    MemWrite(Cpu, Addr, Cpu.RegisterA);
}

Dec :: proc(Cpu : ^cpu, AddressingMode : addressing_mode) -> u8
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    Data -= 1; 
    MemWrite(Cpu, Addr, Data);
    UpdateZeroAndNegativeFlags(Cpu, Data);
    return Data; 
}

Dex :: proc (Cpu : ^cpu)
{
    Cpu.RegisterX -= 1;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
}


Dey :: proc (Cpu : ^cpu)
{
    Cpu.RegisterY -= 1;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterY);
}

Eor :: proc(Cpu : ^cpu, AddressingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Value := MemRead(Cpu, Addr);
    SetRegisterA(Cpu, Value ~ Cpu.RegisterA);
}

Inc :: proc(Cpu : ^cpu, AddressingMode : addressing_mode) -> u8
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    Data += 1;
    MemWrite(Cpu, Addr, Data);
    UpdateZeroAndNegativeFlags(Cpu, Data);
    return Data; 
}

LsrAccumulator :: proc (Cpu : ^cpu)
{
    Data := Cpu.RegisterA;
    if Data & 1 == 1 
    {
        SetCarryFlag(Cpu);
    }
    else 
    {
        ClearCarryFlag(Cpu);
    }
    Data = Data >> 1; 
    SetRegisterA(Cpu, Data);
}

Lsr :: proc (Cpu : ^cpu, AddressingMode : addressing_mode) -> u8
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    if Data & 1 == 1 
    {
        SetCarryFlag(Cpu);
    }
    else 
    {
        ClearCarryFlag(Cpu);
    }
    Data = Data >> 1; 
    MemWrite(Cpu, Addr, Data);
    UpdateZeroAndNegativeFlags(Cpu, Data);
    return Data;
}

Ora :: proc(Cpu : ^cpu, AddressingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    SetRegisterA(Cpu, Cpu.RegisterA | Data);
}

Pla :: proc(Cpu : ^cpu)
{
    Data := StackPop(Cpu);
    SetRegisterA(Cpu, Data);
}

Plp :: proc(Cpu : ^cpu)
{
    Cpu.Status = transmute(bit_set[flags; u8])StackPop(Cpu);
    Cpu.Status -= {.BREAK};
    Cpu.Status += {.BREAK2};
}

RolAccumulator :: proc(Cpu : ^cpu)
{
    Data := Cpu.RegisterA;
    OldCarry := cpu_flags.CARRY in Cpu.Status;
    
    if Data >> 7 == 1
    {
        SetCarryFlag(Cpu);
    }
    else 
    {
        ClearCarryFlag(Cpu);
    }
    Data = Data << 1; 
    if OldCarry
    {
        Data = Data | 1; 
    }
    
    SetRegisterA(Cpu, Data);
}

Rol :: proc(Cpu : ^cpu, AddressingMode : addressing_mode) -> u8
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    OldCarry := cpu_flags.CARRY in Cpu.Status;
    
    if Data >> 7 == 1
    {
        SetCarryFlag(Cpu);
    }
    else 
    {
        ClearCarryFlag(Cpu);
    }
    Data = Data << 1; 
    if OldCarry
    {
        Data = Data | 1; 
    }
    MemWrite(Cpu, Addr, Data);
    UpdateZeroAndNegativeFlags(Cpu, Data);
    return Data;
}

RorAccumulator :: proc(Cpu : ^cpu)
{
    Data := Cpu.RegisterA;
    OldCarry := cpu_flags.CARRY in Cpu.Status;
    
    if Data & 7 == 1
    {
        SetCarryFlag(Cpu);
    }
    else 
    {
        ClearCarryFlag(Cpu);
    }
    Data = Data >> 1; 
    if OldCarry
    {
        Data = Data | 1; 
    }
    
    SetRegisterA(Cpu, Data);
}

Ror :: proc(Cpu : ^cpu, AddressingMode : addressing_mode) -> u8
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    OldCarry := cpu_flags.CARRY in Cpu.Status;
    
    if Data & 7 == 1
    {
        SetCarryFlag(Cpu);
    }
    else 
    {
        ClearCarryFlag(Cpu);
    }
    Data = Data >> 1; 
    if OldCarry
    {
        Data = Data | 1; 
    }
    MemWrite(Cpu, Addr, Data);
    UpdateZeroAndNegativeFlags(Cpu, Data);
    return Data;
}

Sbc :: proc(Cpu : ^cpu, AddressingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    Data := MemRead(Cpu, Addr);
    AddToRegisterA(Cpu, cast(u8)((-(cast(i8)Data)) - 1));
}

UpdateZeroAndNegativeFlags :: proc(Cpu : ^cpu, Result : u8)
{
    if Result == 0
    {
        Cpu.Status = Cpu.Status + {.ZERO};
    }
    else
    {
        Cpu.Status = Cpu.Status - {.ZERO};
    }
    
    if Result & 0b1000_0000 != 0
    {
        Cpu.Status = Cpu.Status + {.NEGATIV};
    }
    else 
    {
        Cpu.Status = Cpu.Status - {.NEGATIV};
    }
}
