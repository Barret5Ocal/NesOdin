package NES

cpu :: struct
{
    RegisterA : u8,
    RegisterX : u8,
    RegisterY : u8,
    Status : cpu_flags,
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

MemReadu16 :: proc(Cpu : ^cpu, Pos : u16) -> u16
{
    Lo := cast(u16)MemRead(Cpu, Pos);
    Hi := cast(u16)MemRead(Cpu, Pos + 1);
    return (Lo << 8) | (cast(u16)Hi); // NOTE(Barret5Ocal): Be careful about this. It's different than the tutorial because it made the program work
}

MemWriteu16 :: proc(Cpu : ^cpu, Pos : u16, Data : u16)
{
    Lo := cast(u8)(Data >> 8);
    Hi := cast(u8)(Data & 0xff);
    MemWrite(Cpu, Pos, Lo);
    MemWrite(Cpu, Pos + 1, Hi)
}

MemRead :: proc(Cpu : ^cpu, Address : u16) -> u8
{
    return Cpu.Memory[Address];
}

MemWrite :: proc(Cpu : ^cpu, Address : u16, Value : u8)
{
    Cpu.Memory[Address] = Value;
}

Reset :: proc(Cpu : ^cpu)
{
    Cpu.RegisterA = 0;
    Cpu.RegisterX = 0;
    //Cpu.RegisterY = 0;
    Cpu.Status = nil;
    
    Cpu.ProgramCounter = MemReadu16(Cpu, 0xFFFC);
}

Load :: proc(Cpu : ^cpu, Program : [dynamic]u8)
{
    copy(Cpu.Memory[0x8000:], Program[:]);
    MemWriteu16(Cpu, 0xFFFC, 0x8000);
    //Cpu.ProgramCounter = 0x8000;
}

LoadAndRun :: proc(Cpu : ^cpu, Program : [dynamic]u8)
{
    Load(Cpu, Program);
    Reset(Cpu);
    Run(Cpu);
}

Run :: proc (Cpu : ^cpu)
{
    OpcodeMap := CreateOpCodeMap();
    defer delete(OpcodeMap);
    
    for 
    {
        Code := MemRead(Cpu, Cpu.ProgramCounter);
        Cpu.ProgramCounter += 1;
        
        ProgramCounterState := Cpu.ProgramCounter;
        
        Opcode := OpcodeMap[Code];
        
        switch Code 
        {
            case 0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71: Adc(Cpu, Opcode.AddressingMode);
            
            case 0xA9 , 0xA5 , 0xAD , 0xBD , 0xB9 , 0xA1 , 0xB1: Lda(Cpu, Opcode.AddressingMode);
            
            case 0x85 , 0x95 , 0x8D , 0x9D , 0x99 , 0x81 , 0x91: Sta(Cpu, Opcode.AddressingMode);
            
            case 0xAA: Tax(Cpu);
            
            case 0xE8: Inx(Cpu);
            
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
            
            case 0x00: return;
            
        }
        
        if ProgramCounterState == Cpu.ProgramCounter 
        {
            Cpu.ProgramCounter += cast(u16)(Opcode.Len - 1);
        }
        
    }
}

SetRegisterA :: proc(Cpu : ^cpu, Result : u8)
{
    Cpu.RegisterA = Result;
    UpdateZeroAndNegativeFlags(Cpu, Result);
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
    Addr := GetOperandAddress(Cpu, AddessingMode);
    Value := MemRead(Cpu, Addr);
    Result := Cpu.RegisterA & Value;
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

Tax :: proc(Cpu : ^cpu)
{
    Cpu.RegisterX = Cpu.RegisterA;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
}

Inx :: proc(Cpu : ^cpu)
{
    Cpu.RegisterX += 1;
    UpdateZeroAndNegativeFlags(Cpu, Cpu.RegisterX);
}

Sta :: proc(Cpu : ^cpu, AddressingMode : addressing_mode)
{
    Addr := GetOperandAddress(Cpu, AddressingMode);
    MemWrite(Cpu, Addr, Cpu.RegisterA);
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
        case addressing_mode.INDIRECT_X:
        {
            Base := MemRead(Cpu, Cpu.ProgramCounter);
            
            Ptr : u8 = (cast(u8) Base) + Cpu.RegisterX; 
            Lo := MemRead(Cpu, cast(u16)Ptr);
            Hi := MemRead(Cpu, cast(u16)Ptr + 1);
            return (cast(u16)Hi) << 8 | (cast(u16)Lo);
        }
        case addressing_mode.INDIRECT_Y:
        {
            Base := MemRead(Cpu, Cpu.ProgramCounter);
            
            Lo := MemRead(Cpu, cast(u16)Base);
            Hi := MemRead(Cpu, cast(u16)((cast(u8)Base) + 1));
            DerefBase := (cast(u16)Hi) << 8 | (cast(u16)Lo);
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

main :: proc()
{
    test();
    test2();
    test3();
    test4();
    test5();
    test6();
}

test :: proc()
{
    Cpu : cpu;
    //MemWrite(&Cpu, 0x10, 0x55);
    //CpuInterpret(&Cpu, Program);
    
    LoadAndRun(&Cpu, {0xa9, 0x05, 0x00});
    
    assert(Cpu.RegisterA == 5);
    assert(Cpu.Status & {.ZERO} == nil);
    assert(Cpu.Status & {.NEGATIV} == nil);
}

test2 :: proc()
{
    Cpu : cpu;
    
    LoadAndRun(&Cpu, {0xa5, 0x10, 0x00});
    
    assert(Cpu.Status - {.ZERO} == nil);
    
}

test3 :: proc()
{
    Cpu : cpu;
    LoadAndRun(&Cpu, {0xa9, 0x0A,0xaa, 0x00});
    assert(Cpu.RegisterX == 10);
}

test4 :: proc() 
{
    Cpu : cpu;
    LoadAndRun(&Cpu, {0xa9, 0xc0, 0xaa, 0xe8, 0x00});
    assert(Cpu.RegisterX == 0xc1);
}

test5 :: proc()
{
    Cpu : cpu;
    LoadAndRun(&Cpu, {0xa9, 0xff, 0xaa,0xe8, 0xe8, 0x00});
    assert(Cpu.RegisterX == 1);
}

test6 :: proc()
{
    Cpu : cpu; 
    MemWrite(&Cpu, 0x10, 0x55);
    LoadAndRun(&Cpu, {0xa5, 0x10, 0x00});
    assert(Cpu.RegisterA == 0x55);
}
