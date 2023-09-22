package NES

import "vendor:sdl2"

import "core:math/rand"
import "core:fmt"
import "core:time"
import "core:mem"

sdl_package :: struct
{
    Window : ^sdl2.Window,
    Renderer : ^sdl2.Renderer,
    Texture : ^sdl2.Texture,
}

WIN_WIDTH :: 32;
WIN_HEIGHT :: 32;

DEBUG_ON :: true; 

Game : [dynamic]u8; 

main :: proc()
{
    fmt.eprintln("ProgramStart");
    
    SdlPackage : sdl_package; 
    
    Flags : sdl2.InitFlags = {.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}; 
    SdlContext := sdl2.Init(Flags);
    
    SdlPackage.Window = sdl2.CreateWindow("Snake Game",  sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, (WIN_WIDTH * 10.0), (WIN_HEIGHT * 10.0), {.SHOWN});
    
    
    RenderFlags : sdl2.RendererFlags  = sdl2.RENDERER_ACCELERATED | sdl2.RENDERER_PRESENTVSYNC;
    
    SdlPackage.Renderer = sdl2.CreateRenderer(SdlPackage.Window, -1, RenderFlags);
    
    sdl2.RenderSetLogicalSize(SdlPackage.Renderer, WIN_WIDTH, WIN_HEIGHT);
    
    SdlPackage.Texture = sdl2.CreateTexture(SdlPackage.Renderer, cast(u32)sdl2.PixelFormatEnum.RGB24, sdl2.TextureAccess.STREAMING, WIN_WIDTH, WIN_HEIGHT);
    
    if DEBUG_ON do CreateUIWindow();
    
    // TODO(Barret5Ocal): There are two things that i want to look into. I need to make sure the inputs are being registered correctly and i need to make sure the apples are spawning correctly
    Game = {
        0x20, 0x06, 0x06, // 0: jump to subroutine init 0x0600
        0x20, 0x38, 0x06, // 1: jump to subroutine loop 
        // init: 
        0x20, 0x0d, 0x06, // 2: jump to subroutine initSnake 0x0606
        0x20, 0x2a, 0x06, // 3: jump to subroutine generateApplePosition
        0x60, // 4: rts
        
        // initSnake: 
        0xa9, 0x01, // 5: start direction, put the dec number 1 in register A
        0x85, 0x02, // 6: store value of register A at address $02
        
        0xa9, 0x04, // 7: start length, put the dec number 4 (the snake is 4 bytes long) in register A
        0x85, 0x03, // 8: store value of register A at address $03
        
        0xa9, 0x11, // 9: put the hex number $11 (dec 17) in register A
        0x85, 0x10, // 10: store value of register A at address hex 10
        
        0xa9, 0x10, // 11:put the hex number $10 (dec 16) in register A
        0x85, 0x12, // 12: store value of register A at address hex $12
        0xa9, 0x0f, // 13: put the hex number $0f (dec 15) in register A
        0x85, 0x14, // 14: store value of register A at address hex $14
        
        0xa9, 0x04, // 15: put the hex number $04 in register A
        0x85, 0x11, // 16: store value of register A at address hex 11
        0x85, 0x13, // 17: store value of register A at address hex 13
        0x85, 0x15, // 18: store value of register A at address hex 15
        0x60, // 19: rts
        
        // generateApplePosition: 
        0xa5, 0xfe, // 20: load a random number between 0 and 255 from address $fe into register A
        0x85, 0x00, // 21: store value of register A at address hex 00
        
        0xa5, 0xfe, // 22: load a random number from address $fe into register A
        
        0x29, 0x03, // 23: mask out lowest 2 bits
        0x18, // 24: clear carry flag 
        0x69, 0x02, // 25: add to register A, using carry bit for overflow.
        0x85, 0x01, // 26: store value of y coordinate from register A into address $01
        0x60, // 27: rts
        
        // loop:
        0x20, 0x4d, 0x06, // 28: jump to subroutine readKeys
        0x20, 0x8d, 0x06, // 29: jump to subroutine checkCollision
        0x20, 0xc3, 0x06, // 30: jump to subroutine updateSnake
        0x20, 0x19, 0x07, // 31: jump to subroutine drawApple
        0x20, 0x20, 0x07, // 32: jump to subroutine drawSnake
        0x20, 0x2d, 0x07, // 33: jump to subroutine spinWheels
        0x4c, 0x38, 0x06, // 34: jump to loop (this is what makes it loop)
        
        // readKeys:
        0xa5, 0xff, // 35: load the value of the latest keypress from address $ff into register A
        0xc9, 0x77, // 36: compare value in register A to hex $77 (W)
        0xf0, 0x0d, // 37: Branch On Equal, to upKey
        0xc9, 0x64, // 38: compare value in register A to hex $64 (D)
        0xf0, 0x14, // 39: Branch On Equal, to rightKey
        0xc9, 0x73, // 40: compare value in register A to hex &73 (S)
        0xf0, 0x1b, // 41: Branch On Equal, to downKey
        0xc9, 0x61, // 42: compare value in register A to hex $61 (A)
        0xf0, 0x22, // 43: Branch On Equal, to leftKey
        0x60, // 44: rts
        
        // upKey:
        0xa9, 0x04, // 45: load value 4 into register A, correspoding to the value for DOWN
        0x24, 0x02, // 46: AND with value at address $02 (the current direction), setting the zero flag if the result of ANDing the two values is 0. So comparing to 4 (bin 0100) only sets zero flag if current direction is 4 (DOWN). So for an illegal move (current direction is DOWN), the result of an AND would be a non zero value so the zero flag would not be set. For a legal move the bit in the new direction should not be the same as the one set for DOWN, so the zero flag needs to be set
        0xd0, 0x26, // 47: Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x01, // 48: Ending up here means the move is legal, load the value 1 (UP) into register A
        0x85, 0x02, // 49: Store the value of A (the new direction) into memory location $02
        0x60, // 50: rts
        
        // rightKey: 
        0xa9, 0x08, // 51: load value 8 into register A, corresponding to the value for LEFT
        0x24, 0x02, // 52: AND with current direction at address $02 and check if result is zero
        0xd0, 0x1b, // 53: Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x02, // 54: Ending up here means the move is legal, load the value 2 (RIGHT) into register A
        0x85, 0x02, // 55: Store the value of A (the new direction) into memory location $02
        0x60, // 56: rts
        
        // downKey:
        0xa9, 0x01, // 57: load value 1 into register A, correspoding to the value for UP
        0x24, 0x02, // 58: AND with current direction at address $02 and check if result is zero
        0xd0, 0x10, // 59: Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x04, // 60: Ending up here means the move is legal, load the value 4 (DOWN) into register A
        0x85, 0x02, // 61: Store the value of A (the new direction) into memory location $02
        0x60, // 62: rts
        
        // leftKey:
        0xa9, 0x02, // 63: load value 2 into register A, correspoding to the value for RIGHT
        0x24, 0x02, // 64: AND with current direction at address $02 and check if result is zero
        0xd0, 0x05, // 65: Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x08, // 66: Ending up here means the move is legal, load the value 8 (LEFT) into register A
        0x85, 0x02, // 67: Store the value of A (the new direction) into memory location $02
        0x60, // 68: rts
        
        // illegalMove:
        0x60, // 69: rts
        
        // checkCollision:
        0x20, 0x94, 0x06, // 70: jump to subroutine checkAppleCollision
        0x20, 0xa8, 0x06, // 71: jump to subroutine checkSnakeCollision
        0x60, // rts
        
        // checkAppleCollision:
        0xa5, 0x00, // 72: load value at address $00 (the least significant byte of the apple's position) into register A
        0xc5, 0x10, // 73: compare to the value stored at address $10 (the least significant byte of the position of the snake's head)
        0xd0, 0x0d, // 74: if different, branch to doneCheckingAppleCollision
        0xa5, 0x01, // 75: load value of address $01 (the most significant byte of the apple's position) into register A
        0xc5, 0x11, // 76: compare the value stored at address $11 (the most significant byte of the position of the snake's head)
        0xd0, 0x07, // 77: if different, branch to doneCheckingAppleCollision Ending up here means the coordinates of the snake head are equal to that of the apple: eat apple
        0xe6, 0x03, // 78: increment the value held in memory $03 (snake length)
        0xe6, 0x03, // 79: twice because we're adding two bytes for one segment
        
        0x20, 0x2a, 0x06, // 80: jump to subroutine generateApplePosition
        
        // doneCheckingAppleCollision:
        0x60, // 81: rts, 
        
        // checkSnakeCollision:
        0xa2, 0x02, // 82: 
        
        // snakeCollisionLoop:
        0xb5, 0x10, // 83: ;load the value stored at address $10 (the least significant byte of the location of the snake's head) plus the value of the x register (2 in the first iteration) to get the least significant byte of the position of the next snake segment
        0xc5, 0x10, // 84: compare to the value at address $10 (the least significant byte of the position of the snake's head
        0xd0, 0x06, // 85: if not equals, we haven't found a collision yet, branch to continueCollisionLoop to continue the loop
        
        // maybeCollided:
        0xb5, 0x11, // 86: load the value stored at address $11 (most significant byte of the location of the snake's head) plus the value of the x register (2 in the first iteration) to get the most significant byte of the position of the next snake segment
        0xc5, 0x11, // 87: compare to the value at address $11 (the most significant byte of the position of the snake head)
        0xf0, 0x09, // 88: both position bytes of the compared segment of the snake bodyare equal to those of the head, so we have a collision of the snake's head with its own body.
        
        // continueCollisionLoop:
        0xe8, // 89: increment the value of the x register
        0xe8, // 90: increment the value of the x register
        0xe4, 0x03, // 91: compare the value in the x register to the value stored at address $03 (snake length).
        0xf0, 0x06, // 92: if equals, we got to last section with no collision: branch to didntCollide
        0x4c, 0xaa, 0x06, // 93: jump to snakeCollisionLoop to continue the loop
        
        // didCollide:
        0x4c, 0x35, 0x07, // 94: jump to gameOver
        
        // didntCollide:
        0x60, // 95: rts
        
        // updateSnake: 
        0xa6, 0x03, // 97: load the value stored at address $03 (snake length) into register X
        0xca, // 98: decrement the value in the X register
        0x8a, // 99: transfer the value stored in the X register into the A register. WHY?
        
        // updateloop:
        0xb5, 0x10, // 100: load the value stored at address $10 + x into register A
        0x95, 0x12, // 101: store the value of register A into address $12  plus the value of register X
        0xca, // 102: decrement X, and set negative flag if value becomes negative
        0x10, 0xf9, // 103: branch to updateLoop if positive (negative flag not set) now determine where to move the head, based on the direction of the snake lsr:Logical Shift Right. Shift all bits in register A one bit to the right the bit that "falls off" is stored in the carry flag
        0xa5, 0x02, // 104: load the value from address $02 (direction) into register A
        0x4a, // 105: shift to right // TODO(Barret5Ocal): Check here
        0xb0, 0x09, // 106: if a 1 "fell off", we started with bin 0001, so the snakes needs to go up // TODO(Barret5Ocal): check here
        0x4a, // 107: shift to right
        0xb0, 0x19, // 108: if a 1 "fell off", we started with bin 0010, so the snakes needs to go right
        0x4a, // 109: shift to right
        0xb0, 0x1f, // 110: if a 1 "fell off", we started with bin 0100, so the snakes needs to go down
        0x4a, // 111: shift to right
        0xb0, 0x2f, // 112: if a 1 "fell off", we started with bin 1000, so the snakes needs to go left
        
        // up:
        0xa5, 0x10, // 113: ;put value stored at address $10 (the least significant byte, meaning the position in a 8x32 strip) in register A
        0x38, // 114: set carry flag
        0xe9, 0x20, // 115: ;Subtract with Carry: subtract hex $20 (dec 32) together with the NOT of the carry bit from value in register A. If overflow occurs the carry bit is clear. This moves the snake up one row in its strip and checks for overflow
        0x85, 0x10, // 116: store value of register A at address $10 (the least significant byte of the head's position)
        0x90, 0x01, // 117: If the carry flag is clear, we had an overflow because of the subtraction, so we need to move to the strip above the current one
        0x60, // 118: rts 
        
        // upup:
        0xc6, 0x11, // 119: decrement the most significant byte of the snake's head's position to move the snake's head to the next up 8x32 strip
        0xa9, 0x01, // 120: load hex value $1 (dec 1) into register A
        0xc5, 0x11, // 121: compare the value at address $11 (snake head's most significant byte, determining which strip it's in). If it's 1, we're one strip too (the first one has a most significant byte of $02), which means the snake hit the top of the screen
        0xf0, 0x28, // 122: branch if equal to collision
        0x60, // 123: rts
        
        // right: 
        0xe6, 0x10, // 124: increment the value at address $10 (snake head's least significant byte, determining where in the 8x32 strip the head is located) to move the head to the right
        0xa9, 0x1f, // 125: load value hex $1f (dec 31) into register A
        0x24, 0x10, // 126: the value stored at address $10 (the snake head coordinate) is ANDed with hex $1f (bin 11111), meaning all multiples of hex $20 (dec 32)zwill be zero (because they all end with bit patterns ending in 5 zeros) if it's zero, it means we hit the right of the screen
        0xf0, 0x1f, // 127: branch to collision if zero flag is set
        0x60, // 128: rts
        
        // down: 
        0xa5, 0x10, // 129: put value from address $10 (the least significant byte, meaning theposition in a 8x32 strip) in register A
        0x18, // 130: clear carry flag
        0x69, 0x20, // 131: add hex $20 (dec 32) to the value in register A and set the carry flag if overflow occurs
        0x85, 0x10, // 132: store the result at address $10 
        0xb0, 0x01, // 133: if the carry flag is set, an overflow occurred when adding hex $20 to the least significant byte of the location of the snake's head, so we need to move the next 8x3 strip
        0x60, // 134: rts
        
        // downdown:
        0xe6, 0x11, // 135: increment the value in location hex $11, holding the most significatnt byte of the location of the snake's head.
        0xa9, 0x06, // 136: load the value hex $6 into the A register
        0xc5, 0x11, // 137: if the most significant byte of the head's location is equals to 6, we're one strip to far down (the last one was hex $05)
        0xf0, 0x0c, // 138: if equals to 6, the snake collided with the bottom of the screen
        0x60, // 139: rts
        
        // left:
        0xc6, 0x10, // 140: subtract one from the value held in memory position $10 (least significant byte of the snake head position) to make it move left. 
        0xa5, 0x10, // 141: load value held in memory position $10 (least significant byte of the snake head position) into register A
        0x29, 0x1f, // 142: AND the value hex $1f (bin 11111) with the value in register A
        0xc9, 0x1f, // 143: compare the ANDed value above with bin 11111.
        0xf0, 0x01, // 144: branch to collision if equals
        0x60, // 145: rts 
        
        // collision:
        0x4c, 0x35, 0x07, // 146: jump to gameOver
        
        // drawApple:
        0xa0, 0x00, // 147: load the value 0 into the Y register
        0xa5, 0xfe, // 148: load the value stored at address $fe (the random number generator) into register A
        0x91, 0x00, // 149: dereference to the address stored at address $00 and $01 (the address of the apple on the screen) and set the value to the value of register A and add the value of Y (0) to it. This results in the apple getting a random color
        0x60, // 150: rts 
        
        // NOTE(Barret5Ocal): It does not matter which source I get this code from. It does not make any sence. The problem might not be my code but the tutorial. 
        
        // NOTE(Barret5Ocal): You load the length of the tail into register x and then put zero(color black) at the end of the tail to erase it. The code is starting to make a little more sense, but I need to be able to look into the screen data.
        
        // NOTE(Barret5Ocal): Actually this does not make that much sense. How does this code erase the tail for the snake if it is going up or down. The position in the texture goes up or down a stride when that happens. So how does adding the lentgh for the snake to the head position do that. Maybe thats still incorrect thinking. The code does not work when the snake is moving left or right either. 
        
        // drawSnake:
        0xa6, 0x03, // 151: load contends of $03(snake length) to x register
        0xa9, 0x00, // 152: loads 0(color black )into the accumulator 
        0x81, 0x10, // 153: stores contents of accumulator in memory location $10(head location) + x register
        0xa2, 0x00, // 154: loads 0 into x register
        0xa9, 0x01, // 155: loads 1 into the accumlator
        0x81, 0x10, // 156: stores contents of accumulator in memory location $10 + 0 (paint head)
        0x60, // 157: rts
        /*
        0xa2, 0x00, // set the value of the X register to 0 
        0xa9, 0x01, // set the value of the A register to 1
        0x81, 0x10, // dereference to the memory address that's stored at address $10 (the two bytes for the location of the head of the snake) and set its value to the one stored in register A
        0xa6, 0x03, // ;set the value of the x register to the value stored in memory at location $03 (the length of the snake) 
        0xa9, 0x00, // set the value of the A register to 0
        
        0x81, 0x01, // dereference to the memory address that's stored at address$10, add the length of the snake to it, and store the value of  register A (0) in the resulting address. This draws a black pixel on the tail. Because the snake is moving, the head "draws" on the screen in white as it moves, and the tail works as an eraser, erasing the white trail using black pixels
        //0x81, 0x10, //  dereference to the memory address that's stored at address $10 (the two bytes for the location of the head of the snake) and set its value to the one stored in register A
        0x60, // rts
        */
        // spinWheels:
        0xa6, 0x00,
        
        // spinloop:
        0xea, // no operation, just skip a cycle
        0xea, // no operation, just skip a cycle
        0xca, // subtract one from the value stored in register x
        0xd0, 0xfb, // if the zero flag is clear, loop. The first dex above wrapped the value of x to hex $ff, so the next zero value is 255 (hex $ff) loops later.
        0x60, // rts
        
    };
    
    OpcodeMap := CreateOpCodeMap();
    defer delete(OpcodeMap);
    
    
    if DEBUG_ON do UISetup();
    // TODO(Barret5Ocal): I need to be able to know where in this code I am at. I might be able to subtract the 0x0600 from the ProgramCounter to be able to get an index into game.
    
    if DEBUG_ON 
    {
        debug_data.State = debug_state.NORMAL;
        Cpu : cpu; 
        Load(&Cpu, Game);
        Reset(&Cpu);
        
        for
        {
            if debug_data.State == debug_state.NORMAL
            {
                RunOpcode(&Cpu);
            }
            else if debug_data.State == debug_state.STEPONCE
            {
                RunOpcode(&Cpu);
                debug_data.State = debug_state.BREAKPOINT;
            }
            debug_data.ProgramCounter = Cpu.ProgramCounter - debug_data.ProgramStart;
            
            EngineLevel(&Cpu, &SdlPackage);
        }
        
    }
    else 
    {
        Cpu : cpu; 
        Load(&Cpu, Game);
        Reset(&Cpu);
        
        RunWithCallback(&Cpu, &SdlPackage, true);
        //sdl2.UpdateWindowSurface(SdlPackage.Window);
    }
    
}

Inputs : inputs; 

EngineLevel :: proc(Cpu : ^cpu, Sdl : ^sdl_package)
{
    // TODO(Barret5Ocal): Figure out how to pass info into anonymous functions
    ScreenState : [WIN_WIDTH * 3 * WIN_HEIGHT]u8 = {};
    
    GetInputs(&Inputs);
    
    
    if DEBUG_ON do UpdateUI(Cpu, &Inputs);
    
    HandleInput(Cpu);
    MemWrite(Cpu, 0xfe, cast(u8)rand.float32_range(1, 16));
    
    if ReadScreenState(Cpu, &ScreenState)
    {
        // TODO(Barret5Ocal): how to pass in sdl stuff
        TexturePitch: i32 = 0;
        TexturePixels : rawptr = nil;
        if (sdl2.LockTexture(Sdl.Texture, nil, &TexturePixels, &TexturePitch) != 0) {
            sdl2.Log("Unable to lock texture: %s", sdl2.GetError());
        }
        else {
            mem.copy(TexturePixels, &ScreenState, cast(int)(TexturePitch * WIN_HEIGHT));
        }
        sdl2.UnlockTexture(Sdl.Texture);
        
        //sdl2.UpdateTexture(Sdl.Texture, nil, &ScreenState, 32 * 3);
        sdl2.RenderClear(Sdl.Renderer);
        
        sdl2.RenderCopy(Sdl.Renderer, Sdl.Texture, nil, nil);
        
        sdl2.RenderPresent(Sdl.Renderer);
    }
    
    if DEBUG_ON do RenderUI();
    
    time.sleep(cast(time.Duration)time.duration_nanoseconds(70000));
}

ReadScreenState :: proc (Cpu : ^cpu, Frame : ^[WIN_WIDTH * 3 * WIN_HEIGHT]u8) -> bool 
{
    FrameIndex := 0; 
    Update := false;
    for i in 0x0200..<0x600
    {
        ColorIndex := MemRead(Cpu, cast(u16)i);
        Color : sdl2.Color;
        switch ColorIndex
        {
            case 0: Color = {0, 0, 0, 255};
            case 1: Color = {255, 255, 255, 255};
            case 2, 9: Color = {255 / 2, 255 / 2, 255 / 2, 255};
            case 3, 10: Color = {255, 0, 0, 255};
            case 4, 11: Color = {0, 255, 0, 255};
            case 5, 12: Color = {0, 0, 255, 255};
            case 6, 13: Color = {255, 0, 255, 255};
            case 7, 14: Color = {255, 255, 0, 255};
            case: Color = {0, 255, 255, 255};
        }
        
        B1, B2, B3 := Color.r, Color.g, Color.b;
        if Frame[FrameIndex] != B1 || Frame[FrameIndex + 1] != B2 || Frame[FrameIndex + 2] != B3
        {
            Frame[FrameIndex] = B1;
            Frame[FrameIndex + 1] = B2;
            Frame[FrameIndex + 2] = B3;
            Update = true;
        }
        FrameIndex += 3; 
    }
    
    return Update;
}

// NOTE(Barret5Ocal): spinWheels might get in the way of collecting inputs
HandleInput :: proc (Cpu : ^cpu)
{
    
    if Inputs.W.Down || Inputs.Up.Down
    {
        MemWrite(Cpu, 0xff, 0x77); 
        fmt.eprintln("UP");
    }
    if Inputs.A.Down || Inputs.Left.Down 
    {
        MemWrite(Cpu, 0xff, 0x61); 
        fmt.eprintln("LEFT");
    }
    if Inputs.S.Down || Inputs.Down.Down
    {
        MemWrite(Cpu, 0xff, 0x73);
        fmt.eprintln("DOWN");
    }
    if Inputs.D.Down || Inputs.Right.Down 
    {
        MemWrite(Cpu, 0xff, 0x64); 
        fmt.eprintln("RIGHT");
    }
    
    
}

test :: proc()
{
    Cpu : cpu;
    
    LoadAndRun(&Cpu, {0xa9, 0x05, 0x00});
    
    assert(Cpu.RegisterA == 5);
    assert(Cpu.Status & {.ZERO} == nil);
    assert(Cpu.Status & {.NEGATIV} == nil);
}

test2 :: proc()
{
    Cpu : cpu;
    
    Load(&Cpu, {0xaa, 0x00});
    Reset(&Cpu);
    Cpu.RegisterA = 10;
    Run(&Cpu);
    assert(Cpu.RegisterX == 10);
    
}

test3 :: proc()
{
    Cpu : cpu;
    LoadAndRun(&Cpu, {0xa9, 0xc0, 0xaa, 0xe8, 0x00});
    assert(Cpu.RegisterX == 0xc1);
}

test4 :: proc() 
{
    Cpu : cpu;
    Load(&Cpu, {0xe8, 0xe8, 0x00});
    Reset(&Cpu);
    Cpu.RegisterX = 0xff;
    Run(&Cpu);
    
    assert(Cpu.RegisterX == 1);
}

test5 :: proc()
{
    Cpu : cpu;
    
    MemWrite(&Cpu, 0x10, 0x55);
    LoadAndRun(&Cpu, {0xa5, 0x10, 0x00});
    assert(Cpu.RegisterA == 0x55);
}

test_addressing_accuracy :: proc()
{
    Cpu : cpu;
    
    MemWrite(&Cpu, 0x10, 0x01);
    MemWrite(&Cpu, 0x11, 0x10);
    MemWrite(&Cpu, 0x12, 0x20);
    MemWriteu16(&Cpu, 0x1010, 0x01);
    MemWriteu16(&Cpu, 0x1020, 0x01);
    
    
    //MemWriteu16(&Cpu, 0x12, 0x01);
    LoadAndRun(&Cpu, {0xa9, 0x01, 0xa5, 0x10, 0xb5, 0x10, 0xad, 0x10, 0x10, 0xbd, 0x10, 0x10, 0xb9, 0x10, 0x10, 0xa1, 0x11, 0xb1, 0x11});
    
}
