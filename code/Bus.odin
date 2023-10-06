package NES

import "core:fmt"

bus :: struct
{
    CpuVRam : [2048]u8,
}

RAM : u16 : 0x0000;
RAM_MIRRORS_END : u16 : 0x1FFF; 
PPU_REGISTERS : u16 : 0x2000;
PPU_REGISTERS_MIRRORS_END : u16 : 0x3FFF; 

BusMemRead :: proc(Bus : ^bus, Addr : u16) -> u8
{
    switch Addr 
    {
        case RAM ..= RAM_MIRRORS_END: 
        {
            MirrorDownAddr := Addr & 0b00000111_11111111;
            return Bus.CpuVRam[MirrorDownAddr];
        }
        case PPU_REGISTERS ..= PPU_REGISTERS_MIRRORS_END:
        {
            MirrorDownAddr := Addr & 0b00100000_00000111;
            // TODO(Barret5Ocal): No PPU yet
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
        case : 
        {
            fmt.println("Ignoring mem write access at {}", Addr);
        }
    }
}