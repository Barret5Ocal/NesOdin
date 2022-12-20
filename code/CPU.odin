package NES

cpu :: struct
{
    RegisterA : u8,
    RegisterX : u8,
    RegisterY : u8,
    Status : u8,
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
    Cpu.Status = 0;
    
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
            case 0xA9 , 0xA5 , 0xAD , 0xBD , 0xB9 , 0xA1 , 0xB1:
            {
                Lda(Cpu, Opcode.AddressingMode);
                //Cpu.ProgramCounter += 1;
            }
            case 0x85 , 0x95 , 0x8D , 0x9D , 0x99 , 0x81 , 0x91:
            {
                Sta(Cpu, Opcode.AddressingMode);
                //Cpu.ProgramCounter += 1;
            }
            case 0xAA: 
            {
                Tax(Cpu);
            }
            case 0xE8:
            {
                Inx(Cpu);
            }
            
            
            case 0x00:
            {
                return;
            }
        }
        
        if ProgramCounterState == Cpu.ProgramCounter 
        {
            Cpu.ProgramCounter += cast(u16)(Opcode.Len - 1);
        }
        
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
        Cpu.Status = Cpu.Status | 0b0000_0010;
    }
    else
    {
        Cpu.Status = Cpu.Status & 0b1111_1101;
    }
    
    if Result & 0b1000_0000 != 0
    {
        Cpu.Status = Cpu.Status | 0b1000_0000;
    }
    else 
    {
        Cpu.Status = Cpu.Status & 0b0111_1111;
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
    assert(Cpu.Status & 0b0000_0010 == 0);
    assert(Cpu.Status & 0b1000_0000 == 0);
}

test2 :: proc()
{
    Cpu : cpu;
    
    LoadAndRun(&Cpu, {0xa5, 0x10, 0x00});
    
    assert(Cpu.Status & 0b0000_0010 == 0b10);
    
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
