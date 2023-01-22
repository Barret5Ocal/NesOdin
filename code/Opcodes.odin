package NES 

opcode :: struct 
{
    Code : u8,
    Mnemonic : string,
    Len : u8,
    Cycles : u8,
    AddressingMode : addressing_mode,
}

Opcodes : []opcode = 
{
    {0x00, "BRK", 1, 7, addressing_mode.NONEADDRESSING},
    {0xaa, "TAX", 1, 2, addressing_mode.NONEADDRESSING},
    {0xe8, "INX", 1, 2, addressing_mode.NONEADDRESSING},
    
    {0xa9, "LDA", 2, 2, addressing_mode.IMMEDIATE},
    {0xa5, "LDA", 2, 3, addressing_mode.ZEROPAGE},
    {0xb5, "LDA", 2, 4, addressing_mode.ZEROPAGE_X},
    {0xad, "LDA", 3, 4, addressing_mode.ABSOLUTE},
    {0xbd, "LDA", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_X},
    {0xb9, "LDA", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_Y},
    {0xa1, "LDA", 2, 6, addressing_mode.INDIRECT_X},
    {0xb1, "LDA", 2, 5/*+1 if page crossed*/, addressing_mode.INDIRECT_Y},
    
    {0x85, "STA", 2, 3, addressing_mode.ZEROPAGE},
    {0x95, "STA", 2, 4, addressing_mode.ZEROPAGE_X},
    {0x8d, "STA", 3, 4, addressing_mode.ABSOLUTE},
    {0x9d, "STA", 3, 5, addressing_mode.ABSOLUTE_X},
    {0x99, "STA", 3, 5, addressing_mode.ABSOLUTE_Y},
    {0x81, "STA", 2, 6, addressing_mode.INDIRECT_X},
    {0x91, "STA", 2, 6, addressing_mode.INDIRECT_Y},
    
    //ADC
    {0x69, "ADC", 2, 2, addressing_mode.IMMEDIATE},
    {0x65, "ADC", 2, 3, addressing_mode.ZEROPAGE},
    {0x75, "ADC", 2, 4, addressing_mode.ZEROPAGE_X},
    {0x6D, "ADC", 3, 4, addressing_mode.ABSOLUTE},
    {0x7D, "ADC", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_X},
    {0x79, "ADC", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_Y},
    {0x61, "ADC", 2, 6, addressing_mode.INDIRECT_X}, 
    {0x71, "ADC", 2, 5/*+1 if page crossed*/, addressing_mode.INDIRECT_Y},
    
    //AND
    {0x29, "AND", 2, 2, addressing_mode.IMMEDIATE},
    {0x25, "AND", 2, 3, addressing_mode.ZEROPAGE},
    {0x35, "AND", 2, 4, addressing_mode.ZEROPAGE_X},
    {0x2D, "AND", 2, 4, addressing_mode.ABSOLUTE},
    {0x3D, "AND", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_X},
    {0x39, "AND", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_Y},
    {0x21, "AND", 2, 6, addressing_mode.INDIRECT_X},
    {0x31, "AND", 2, 5/*+1 if page crossed*/, addressing_mode.INDIRECT_Y},
    
    //ASL
    {0x0A, "ASL", 1, 2, addressing_mode.NONEADDRESSING},
    {0x06, "ASL", 2, 5, addressing_mode.ZEROPAGE},
    {0x16, "ASL", 2, 6, addressing_mode.ZEROPAGE_X},
    {0x0E, "ASL", 3, 6, addressing_mode.ABSOLUTE},
    {0x1E, "ASL", 3, 7, addressing_mode.ABSOLUTE_X},
    
    //Branching
    {0x90, "BCC", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    {0xB0, "BCS", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    {0xF0, "BEQ", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    
    {0x24, "BIT", 2, 3, addressing_mode.ZEROPAGE},
    {0x2C, "BIT", 3, 4, addressing_mode.ABSOLUTE},
    
    {0x30, "BMI", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    {0xD0, "BNE", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    {0x10, "BPL", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    {0x50, "BVC", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    {0x70, "BVS", 2, 2/*(+1 if branch succeeds +2 if to a new page)*/, addressing_mode.NONEADDRESSING},
    
    {0x18, "CLC", 1, 2, addressing_mode.NONEADDRESSING},
    {0xD8, "CLD", 1, 2, addressing_mode.NONEADDRESSING},
    {0x58, "CLI", 1, 2, addressing_mode.NONEADDRESSING},
    {0xB8, "CLV", 1, 2, addressing_mode.NONEADDRESSING},
    
    {0xC9, "CMP", 2, 2, addressing_mode.IMMEDIATE},
    {0xC5, "CMP", 2, 3, addressing_mode.ZEROPAGE},
    {0xD5, "CMP", 2, 4, addressing_mode.ZEROPAGE_X},
    {0xCD, "CMP", 3, 4, addressing_mode.ABSOLUTE},
    {0xDD, "CMP", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_X},
    {0xD9, "CMP", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_Y},
    {0xC1, "CMP", 2, 6, addressing_mode.INDIRECT_X},
    {0xD1, "CMP", 2, 5/*+1 if page crossed*/, addressing_mode.INDIRECT_Y},
    
    {0xE0, "CPX", 2, 2, addressing_mode.IMMEDIATE},
    {0xE4, "CPX", 2, 3, addressing_mode.ZEROPAGE},
    {0xEC, "CPX", 3, 4, addressing_mode.ABSOLUTE},
    
    {0xC0, "CPY", 2, 2, addressing_mode.IMMEDIATE},
    {0xC4, "CPY", 2, 3, addressing_mode.ZEROPAGE},
    {0xCC, "CPY", 3, 4, addressing_mode.ABSOLUTE},
    
    {0xC6, "DEC", 2, 5, addressing_mode.ZEROPAGE},
    {0xD6, "DEC", 2, 6, addressing_mode.ZEROPAGE_X},
    {0xCE, "DEC", 3, 6, addressing_mode.ABSOLUTE},
    {0xDE, "DEC", 3, 7, addressing_mode.ABSOLUTE_X},
    {0xCA, "DEX", 1, 2, addressing_mode.NONEADDRESSING},
    {0x88, "DEY", 1, 2, addressing_mode.NONEADDRESSING},
    
    {0x49, "EOR", 2, 2, addressing_mode.IMMEDIATE},
    {0x45, "EOR", 2, 3, addressing_mode.ZEROPAGE},
    {0x55, "EOR", 2, 4, addressing_mode.ZEROPAGE_X},
    {0x4D, "EOR", 3, 4, addressing_mode.ABSOLUTE},
    {0x5D, "EOR", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_X},
    {0x59, "EOR", 3, 4/*+1 if page crossed*/, addressing_mode.ABSOLUTE_Y},
    {0x41, "EOR", 2, 6, addressing_mode.INDIRECT_X},
    {0x51, "EOR", 2, 5, addressing_mode.INDIRECT_Y},
};

CreateOpCodeMap :: proc() -> map[u8]opcode
{
    OpcodeMap := make(map[u8]opcode);
    
    for op in Opcodes
    {
        OpcodeMap[op.Code] = op;
    }
    
    return OpcodeMap;
}