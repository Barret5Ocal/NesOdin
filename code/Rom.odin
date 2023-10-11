package NES

import "core:slice"

NES_TAG : [4]u8 = {0x4E, 0x45, 0x53, 0x1A};

morroring :: enum
{
    VERTICAL, 
    HORIZONTAL,
    FOUR_SCREEN,
}

rom :: struct 
{
    Prg_rom : [dynamic]u8,
    Chr_rom : [dynamic]u8,
    Mapper : u8,
    Mirroring : morroring, 
}

NewRom :: proc(Rom : ^rom, Raw : [dynamic]u8) -> (Result : string)
{
    if !slice.equal(Raw[0:4], NES_TAG[:])
    {
        return "Cannot slice array 'NES_TAG[:]', value is not addressable";
    }
    
    Mapper := (Raw[7] & 0b1111_0000) | (Raw[6] >> 4);
    
    INes_Ver := (Raw[7] >> 2) & 0b11;
    if INes_Ver != 0 do return "NES2.0 format is not supported";
    
    Four_Screen := Raw[6] & 0b1000 != 0;
    Vertical_Mirroring := Raw[6] & 0b1 != 0;
    screen_mirroring := morroring.HORIZONTAL;
    if Four_Screen {
        screen_mirroring = .FOUR_SCREEN
    } else if Vertical_Mirroring {
        screen_mirroring = .VERTICAL
    }
    
    
    
    return;
    
}