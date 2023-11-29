package NES

import "core:fmt"

//  _______________ $10000  _______________
// | PRG-ROM       |       |               |
// | Upper Bank    |       |               |
// |_ _ _ _ _ _ _ _| $C000 | PRG-ROM       |
// | PRG-ROM       |       |               |
// | Lower Bank    |       |               |
// |_______________| $8000 |_______________|
// | SRAM          |       | SRAM          |
// |_______________| $6000 |_______________|
// | Expansion ROM |       | Expansion ROM |
// |_______________| $4020 |_______________|
// | I/O Registers |       |               |
// |_ _ _ _ _ _ _ _| $4000 |               |
// | Mirrors       |       | I/O Registers |
// | $2000-$2007   |       |               |
// |_ _ _ _ _ _ _ _| $2008 |               |
// | I/O Registers |       |               |
// |_______________| $2000 |_______________|
// | Mirrors       |       |               |
// | $0000-$07FF   |       |               |
// |_ _ _ _ _ _ _ _| $0800 |               |
// | RAM           |       | RAM           |
// |_ _ _ _ _ _ _ _| $0200 |               |
// | Stack         |       |               |
// |_ _ _ _ _ _ _ _| $0100 |               |
// | Zero Page     |       |               |
// |_______________| $0000 |_______________|

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
            return ReadPrgRom(Cpu, Addr);
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