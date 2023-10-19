package NES

import "core:fmt"

bus :: struct
{
    CpuVRam : [2048]u8,
    Rom : rom,
}

RAM : u16 : 0x0000;
RAM_MIRRORS_END : u16 : 0x1FFF; 
PPU_REGISTERS : u16 : 0x2000;
PPU_REGISTERS_MIRRORS_END : u16 : 0x3FFF; 

ReadPrgRom :: proc(Cpu : ^cpu, Addr : u16) -> u8
{
    Addr := Addr;
    Addr -= 0x8000;
    // NOTE(Barret5Ocal): what up with len(Cpu.Bus.Rom.Prg_rom) == 0x4000
    if len(Cpu.Bus.Rom.Prg_rom) == 0x4000 && Addr >= 0x4000
    {
        Addr = Addr % 0x4000;
    }
    return Cpu.Bus.Rom.Prg_rom[Addr];
}

BusMemRead :: proc(Cpu: ^cpu, Addr : u16) -> u8
{
    switch Addr 
    {
        case RAM ..= RAM_MIRRORS_END: 
        {
            MirrorDownAddr := Addr & 0b00000111_11111111;
            return Cpu.Bus.CpuVRam[MirrorDownAddr];
        }
        case PPU_REGISTERS ..= PPU_REGISTERS_MIRRORS_END:
        {
            MirrorDownAddr := Addr & 0b00100000_00000111;
            // TODO(Barret5Ocal): No PPU yet
        }
        case 0x8000..=0xFFFF:
        {
            ReadPrgRom(Cpu, Addr);
        }
        case : 
        {
            fmt.println("Ignoring mem access at {}", Addr);
            return 0;
        }
    }
    
    return 0;
}

BusMemWrite :: proc(Bus : ^bus, Addr : u16, Data : u8)
{
    switch Addr
    {
        case RAM ..= RAM_MIRRORS_END: 
        {
            MirrorDownAddr := Addr & 0b00000111_11111111;
            Bus.CpuVRam[MirrorDownAddr] = Data;
        }
        case PPU_REGISTERS ..= PPU_REGISTERS_MIRRORS_END:
        {
            MirrorDownAddr := Addr & 0b00100000_00000111;
            // TODO(Barret5Ocal): No PPU yet
        }
        case  0x8000..=0xFFFF:
        {
            fmt.printf("Attempt to write to Cartridge ROM space");
            assert(false);
        }
        case : 
        {
            fmt.println("Ignoring mem write access at {}", Addr);
        }
    }
}