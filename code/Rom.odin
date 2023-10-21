package NES

import "core:slice"

NES_TAG : [4]u8 = {0x4E, 0x45, 0x53, 0x1A};
PRG_ROM_PAGE_SIZE :: 16384;
CHR_ROM_PAGE_SIZE :: 8192;

morroring :: enum
{
    VERTICAL, 
    HORIZONTAL,
    FOUR_SCREEN,
}

rom :: struct 
{
    Prg_rom : []u8,
    Chr_rom : []u8,
    Mapper : u8,
    Mirroring : morroring, 
}

NewRom :: proc(Rom : ^rom, Raw : []u8) -> (Result : string)
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
    
    Prg_Rom_Size := cast(uint)Raw[4] * PRG_ROM_PAGE_SIZE;
    Chr_Rom_Size := cast(uint)Raw[5] * CHR_ROM_PAGE_SIZE;
    
    Skip_Trainer := Raw[6] & 0b100 != 0;
    
    Prg_Rom_Start : uint = 16;
    if Skip_Trainer {Prg_Rom_Start += 512;} else {Prg_Rom_Start += 0;}
    
    Chr_Rom_Start := Prg_Rom_Start + Prg_Rom_Size; 
    
    // NOTE(Barret5Ocal): this is not copying correctly
    Rom.Prg_rom = Raw[Prg_Rom_Start:(Prg_Rom_Start + Prg_Rom_Size)];
    //append(&Rom.Prg_rom, ..src);
    Rom.Chr_rom = Raw[Chr_Rom_Start:(Chr_Rom_Start + Chr_Rom_Size)];
    //append(&Rom.Chr_rom, ..src);
    Rom.Mapper = Mapper;
    Rom.Mirroring = screen_mirroring; 
    
    return "It worked";
    
}