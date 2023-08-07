package NES

import "vendor:sdl2"

import "core:math/rand"
import "core:fmt"
import "core:time"

sdl_package :: struct
{
    Window : ^sdl2.Window,
    Renderer : ^sdl2.Renderer,
    Texture : ^sdl2.Texture,
}

main :: proc()
{
    
    SdlPackage : sdl_package; 
    
    Flags : sdl2.InitFlags = {.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}; 
    SdlContext := sdl2.Init(Flags);
    
    SdlPackage.Window = sdl2.CreateWindow("Snake Game",  sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, (32.0 * 10.0), (32.0 * 10.0), {.SHOWN});
    
    
    SdlPackage.Renderer = sdl2.CreateRenderer(SdlPackage.Window, -1, {.ACCELERATED});
    SdlPackage.Texture = sdl2.CreateTexture(SdlPackage.Renderer, sdl2.PIXELTYPE_PACKED32, sdl2.TextureAccess.STREAMING, (32.0 * 10.0), (32.0 * 10.0));
    
    Game : [dynamic]u8 = {
        0x20, 0x06, 0x06, // jump to subroutine init 0x0600
        0x20, 0x38, 0x06, // jump to subroutine loop 
        // init: 
        0x20, 0x0d, 0x06, // jump to subroutine initSnake 0x0606
        0x20, 0x2a, 0x06, // jump to subroutine generateApplePosition
        0x60, // rts
        
        // initSnake: 
        0xa9, 0x02, // start direction, put the dec number 2 in register A
        0x85, 0x02, // store value of register A at address $02
        
        0xa9, 0x04, // start length, put the dec number 4 (the snake is 4 bytes long) in register A
        0x85, 0x03, // store value of register A at address $03
        
        0xa9, 0x11, // put the hex number $11 (dec 17) in register A
        0x85, 0x10, // store value of register A at address hex 10
        
        0xa9, 0x10, // put the hex number $10 (dec 16) in register A
        0x85, 0x12, // store value of register A at address hex $12
        0xa9, 0x0f, // put the hex number $0f (dec 15) in register A
        0x85, 0x14, // store value of register A at address hex $14
        
        
        0xa9, 0x04, // put the hex number $04 in register A
        0x85, 0x11, // store value of register A at address hex 11
        0x85, 0x13, // store value of register A at address hex 13
        0x85, 0x15, // store value of register A at address hex 15
        0x60, // rts
        
        // generateApplePosition: 
        0xa5, 0xfe, // load a random number between 0 and 255 from address $fe into register A
        0x85, 0x00, // store value of register A at address hex 00
        
        0xa5, 0xfe, //load a random number from address $fe into register A
        
        0x29, 0x03, // mask out lowest 2 bits
        0x18, // clear carry flag 
        0x69, 0x02, // add to register A, using carry bit for overflow.
        0x85, 0x01, // store value of y coordinate from register A into address $01
        0x60, // rts
        
        // loop:
        0x20, 0x4d, 0x06, // jump to subroutine readKeys
        0x20, 0x8d, 0x06, // jump to subroutine checkCollision
        0x20, 0xc3, 0x06, // jump to subroutine updateSnake
        0x20, 0x19, 0x07, // jump to subroutine drawApple
        0x20, 0x20, 0x07, // jump to subroutine drawSnake
        0x20, 0x2d, 0x07, // jump to subroutine spinWheels
        0x4c, 0x38, 0x06, // jump to loop (this is what makes it loop)
        
        // readKeys:
        0xa5, 0xff, // load the value of the latest keypress from address $ff into register A
        0xc9, 0x77, // compare value in register A to hex $77 (W)
        0xf0, 0x0d, // Branch On Equal, to upKey
        0xc9, 0x64, // compare value in register A to hex $64 (D)
        0xf0, 0x14, // Branch On Equal, to rightKey
        0xc9, 0x73, // Branch On Equal, to rightKey
        0xf0, 0x1b, // Branch On Equal, to downKey
        0xc9, 0x61, // compare value in register A to hex $61 (A)
        0xf0, 0x22, //Branch On Equal, to leftKey
        0x60, // rts
        
        // upKey:
        0xa9, 0x04, //load value 4 into register A, correspoding to the value for DOWN
        0x24, 0x02, // AND with value at address $02 (the current direction), setting the zero flag if the result of ANDing the two values is 0. So comparing to 4 (bin 0100) only sets zero flag if current direction is 4 (DOWN). So for an illegal move (current direction is DOWN), the result of an AND would be a non zero value so the zero flag would not be set. For a legal move the bit in the new direction should not be the same as the one set for DOWN, so the zero flag needs to be set
        0xd0, 0x26, // Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x01, // Ending up here means the move is legal, load the value 1 (UP) into register A
        0x85, 0x02, // Store the value of A (the new direction) into register A
        0x60, // rts
        
        // rightKey: 
        0xa9, 0x08, // load value 8 into register A, corresponding to the value for LEFT
        0x24, 0x02, // AND with current direction at address $02 and check if result is zero
        0xd0, 0x1b, // Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x02, // Ending up here means the move is legal, load the value 2 (RIGHT) into register A
        0x85, 0x02, // Store the value of A (the new direction) into register A
        0x60, // rts
        
        // downKey:
        0xa9, 0x01, // load value 1 into register A, correspoding to the value for UP
        0x24, 0x02, // AND with current direction at address $02 and check if result is zero
        0xd0, 0x10, // Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x04, // Ending up here means the move is legal, load the value 4 (DOWN) into register A
        0x85, 0x02, // Store the value of A (the new direction) into register A
        0x60, // rts
        
        // leftKey:
        0xa9, 0x02, // load value 1 into register A, correspoding to the value for RIGHT
        0x24, 0x02, // AND with current direction at address $02 and check if result is zero
        0xd0, 0x05, // Branch If Not Equal: meaning the zero flag is not set.
        0xa9, 0x08, // Ending up here means the move is legal, load the value 8 (LEFT) into register A
        0x85, 0x02, // Store the value of A (the new direction) into register A
        0x60, // rts
        
        // illegalMove:
        0x60, // rts
        
        // checkCollision:
        0x20, 0x94, 0x06, // jump to subroutine checkAppleCollision
        0x20, 0xa8, 0x06, // jump to subroutine checkSnakeCollision
        0x60, // rts
        
        // checkAppleCollision:
        0xa5, 0x00, // load value at address $00 (the least significant byte of the apple's position) into register A
        0xc5, 0x10, // compare to the value stored at address $10 (the least significant byte of the position of the snake's head)
        0xd0, 0x0d, // if different, branch to doneCheckingAppleCollision
        0xa5, 0x01, // load value of address $01 (the most significant byte of the apple's position) into register A
        0xc5, 0x11, // compare the value stored at address $11 (the most significant byte of the position of the snake's head)
        0xd0, 0x07, // if different, branch to doneCheckingAppleCollision Ending up here means the coordinates of the snake head are equal to that of the apple: eat apple
        0xe6, 0x03, // increment the value held in memory $03 (snake length)
        0xe6, 0x03, // twice because we're adding two bytes for one segment
        
        0x20, 0x2a, 0x06, //jump to subroutine generateApplePosition
        
        // doneCheckingAppleCollision:
        0x60, 
        
        // checkSnakeCollision:
        0xa2, 0x02,
        
        // snakeCollisionLoop:
        0xb5, 0x10, // ;load the value stored at address $10 (the least significant byte of the location of the snake's head) plus the value of the x register (2 in the first iteration) to get the least significant byte of the position of the next snake segment
        0xc5, 0x10, // compare to the value at address $10 (the least significant byte of the position of the snake's head
        0xd0, 0x06, // if not equals, we haven't found a collision yet, branch to continueCollisionLoop to continue the loop
        
        // maybeCollided:
        0xb5, 0x11, //load the value stored at address $11 (most significant byte of the location of the snake's head) plus the value of the x register (2 in the first iteration) to get the most significant byte of the position of the next snake segment
        0xc5, 0x11, // compare to the value at address $11 (the most significant byte of the position of the snake head)
        0xf0, 0x09, // both position bytes of the compared segment of the snake bodyare equal to those of the head, so we have a collision of the snake's head with its own body.
        
        // continueCollisionLoop:
        0xe8, // increment the value of the x register
        0xe8, // increment the value of the x register
        0xe4, 0x03, // compare the value in the x register to the value stored at address $03 (snake length).
        0xf0, 0x06, // if equals, we got to last section with no collision: branch to didntCollide
        0x4c, 0xaa, 0x06, // jump to snakeCollisionLoop to continue the loop
        
        // didCollide:
        0x4c, 0x35, 0x07, // jump to gameOver
        
        // didntCollide:
        0x60, // rts
        
        // updateSnake: 
        0xa6, 0x03, // load the value stored at address $03 (snake length) into register X
        0xca, // decrement the value in the X register
        0x8a, // transfer the value stored in the X register into the A register. WHY?
        
        // updateloop:
        0xb5, 0x10, // load the value stored at address $10 + x into register A
        0x95, 0x12, // store the value of register A into address $12  plus the value of register X
        0xca, // decrement X, and set negative flag if value becomes negative
        0x10, 0xf9, // branch to updateLoop if positive (negative flag not set) now determine where to move the head, based on the direction of the snake lsr:Logical Shift Right. Shift all bits in register A one bit to the right the bit that "falls off" is stored in the carry flag
        0xa5, 0x02, // load the value from address $02 (direction) into register A
        0x4a, // shift to right
        0xb0, 0x09, // if a 1 "fell off", we started with bin 0001, so the snakes needs to go up
        0x4a, // shift to right
        0xb0, 0x19, // if a 1 "fell off", we started with bin 0010, so the snakes needs to go right
        0x4a, // shift to right
        0xb0, 0x1f, // if a 1 "fell off", we started with bin 0100, so the snakes needs to go down
        0x4a, // shift to right
        0xb0, 0x2f, // if a 1 "fell off", we started with bin 1000, so the snakes needs to go left
        
        // up:
        0xa5, 0x10, // ;put value stored at address $10 (the least significant byte, meaning the position in a 8x32 strip) in register A
        0x38, // set carry flag
        0xe9, 0x20, // ;Subtract with Carry: subtract hex $20 (dec 32) together with the NOT of the carry bit from value in register A. If overflow occurs the carry bit is clear. This moves the snake up one row in its strip and checks for overflow
        0x85, 0x10, // store value of register A at address $10 (the least significant byte of the head's position)
        0x90, 0x01, // If the carry flag is clear, we had an overflow because of the subtraction, so we need to move to the strip above the current one
        0x60, // rts 
        
        // upup:
        0xc6, 0x11, //decrement the most significant byte of the snake's head's position to move the snake's head to the next up 8x32 strip
        0xa9, 0x01, // load hex value $1 (dec 1) into register A
        0xc5, 0x11, // compare the value at address $11 (snake head's most significant byte, determining which strip it's in). If it's 1, we're one strip too (the first one has a most significant byte of $02), which means the snake hit the top of the screen
        0xf0, 0x28, // branch if equal to collision
        0x60, // rts
        
        // right: 
        0xe6, 0x10, // increment the value at address $10 (snake head's least significant byte, determining where in the 8x32 strip the head is located) to move the head to the right
        0xa9, 0x1f, // load value hex $1f (dec 31) into register A
        0x24, 0x10, // the value stored at address $10 (the snake head coordinate) is ANDed with hex $1f (bin 11111), meaning all multiples of hex $20 (dec 32)zwill be zero (because they all end with bit patterns ending in 5 zeros) if it's zero, it means we hit the right of the screen
        0xf0, 0x1f, // branch to collision if zero flag is set
        0x60, // rts
        
        // down: 
        0xa5, 0x10, //put value from address $10 (the least significant byte, meaning theposition in a 8x32 strip) in register A
        0x18, //clear carry flag
        0x69, 0x20, // add hex $20 (dec 32) to the value in register A and set the carry flag if overflow occurs
        0x85, 0x10, // store the result at address $10 
        0xb0, 0x01, // if the carry flag is set, an overflow occurred when adding hex $20 to the least significant byte of the location of the snake's head, so we need to move the next 8x3 strip
        0x60, // rts
        
        // downdown:
        0xe6, 0x11, //increment the value in location hex $11, holding the most significatnt byte of the location of the snake's head.
        0xa9, 0x06, // load the value hex $6 into the A register
        0xc5, 0x11, // if the most significant byte of the head's location is equals to 6, we're one strip to far down (the last one was hex $05)
        0xf0, 0x0c, // if equals to 6, the snake collided with the bottom of the screen
        0x60, // rts
        
        // left:
        0xc6, 0x10, // subtract one from the value held in memory position $10 (least significant byte of the snake head position) to make it move left. 
        0xa5, 0x10, // load value held in memory position $10 (least significant byte of the snake head position) into register A
        0x29, 0x1f, // AND the value hex $1f (bin 11111) with the value in register A
        0xc9, 0x1f, // compare the ANDed value above with bin 11111.
        0xf0, 0x01, // branch to collision if equals
        0x60, // rts 
        
        // collision:
        0x4c, 0x35, 0x07, //jump to gameOver
        
        // drawApple:
        0xa0, 0x00, // load the value 0 into the Y register
        0xa5, 0xfe, // load the value stored at address $fe (the random number generator) into register A
        0x91, 0x00, // dereference to the address stored at address $00 and $01 (the address of the apple on the screen) and set the value to the value of register A and add the value of Y (0) to it. This results in the apple getting a random color
        0x60, // rts 
        
        // NOTE(Barret5Ocal): this is different from the snake source. check for errors
        // drawSnake:
        0xa6, 0x03, // ;set the value of the x register to the value stored in memory at location $03 (the length of the snake) 
        0xa9, 0x00, // set the value of the A register to 0
        0x81, 0x10, // dereference to the memory address that's stored at address $10 (the two bytes for the location of the head of the snake) and set its value to the one stored in register A
        0xa2, 0x00, // set the value of the X register to 0 
        0xa9, 0x01, // dereference to the memory address that's stored at address$10, add the length of the snake to it, and store the value of  register A (0) in the resulting address. This draws a black pixel on the tail. Because the snake is moving, the head "draws" on the screen in white as it moves, and the tail works as an eraser, erasing the white trail using black pixels
        0x81, 0x10, //  dereference to the memory address that's stored at address $10 (the two bytes for the location of the head of the snake) and set its value to the one stored in register A
        0x60, // rts
        
        // spinWheels:
        0xa6, 0xff,
        
        // spinloop:
        0xea, // no operation, just skip a cycle
        0xea, // no operation, just skip a cycle
        0xca, // subtract one from the value stored in register x
        0xd0, 0xfb, // if the zero flag is clear, loop. The first dex above wrapped the value of x to hex $ff, so the next zero value is 255 (hex $ff) loops later.
        0x60, // rts
    };
    
    // TODO(Barret5Ocal): I need to be able to know where in this code I am at. I might be able to subtract the 0x0600 from the ProgramCounter to be able to get an index into game.
    
    Cpu : cpu; 
    Load(&Cpu, Game);
    Reset(&Cpu);
    
    RunWithCallback(&Cpu, &SdlPackage, true);
    //sdl2.UpdateWindowSurface(SdlPackage.Window);
    
    
}

EngineLevel :: proc(Cpu : ^cpu, Sdl : ^sdl_package)
{
    // TODO(Barret5Ocal): Figure out how to pass info into anonymous functions
    ScreenState : [32 * 3 * 32]u8 = {};
    
    HandleInput(Cpu);
    MemWrite(Cpu, 0xfe, cast(u8)rand.float32_range(1, 16));
    
    if ReadScreenState(Cpu, &ScreenState)
    {
        // TODO(Barret5Ocal): how to pass in sdl stuff
        sdl2.UpdateTexture(Sdl.Texture, nil, &ScreenState, 32 * 3);
        sdl2.RenderClear(Sdl.Renderer);
        
        sdl2.RenderCopy(Sdl.Renderer, Sdl.Texture, nil, nil);
        
        sdl2.RenderPresent(Sdl.Renderer);
    }
    
    time.sleep(70000);
}

ReadScreenState :: proc (Cpu : ^cpu, Frame : ^[32 * 3 * 32]u8) -> bool 
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


HandleInput :: proc (Cpu : ^cpu)
{
    Event : sdl2.Event;
    // NOTE(Barret5Ocal): PollEvent returns a different type depending whether im on pc or my laptop. maybe different versions of odin?
    for sdl2.PollEvent(&Event) == true
    {
#partial switch Event.type
        {
            case sdl2.EventType.QUIT:
            {
                sdl2.Quit();
            }
            
            case sdl2.EventType.KEYDOWN:
            {
                Keycode := Event.key.keysym.sym; 
                if Keycode == sdl2.Keycode.ESCAPE
                {
                    sdl2.Quit();
                }
                else if Keycode == sdl2.Keycode.w
                {
                    MemWrite(Cpu, 0xff, 0x77);
                }
                else if Keycode == sdl2.Keycode.s
                {
                    MemWrite(Cpu, 0xff, 0x73);
                }
                else if Keycode == sdl2.Keycode.a
                {
                    MemWrite(Cpu, 0xff, 0x61);
                }
                else if Keycode == sdl2.Keycode.d
                {
                    MemWrite(Cpu, 0xff, 0x64);
                }
                
            }
        }
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
