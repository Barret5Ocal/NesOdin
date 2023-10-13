package NES

import "vendor:sdl2"

import "core:math/rand"
import "core:fmt"
import "core:time"
import "core:mem"
import "core:os"

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
    Data, ok := os.read_entire_file("snake.nes", context.allocator);
    defer delete(Data, context.allocator);
    
    OpcodeMap := CreateOpCodeMap();
    defer delete(OpcodeMap);
    
    
    if DEBUG_ON do UISetup();
    // TODO(Barret5Ocal): I need to be able to know where in this code I am at. I might be able to subtract the 0x0600 from the ProgramCounter to be able to get an index into game.
    
    if DEBUG_ON 
    {
        debug_data.State = debug_state.STARTUP;
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
            else if debug_data.State == debug_state.RESET
            {
                debug_data.State = debug_state.STARTUP;
                //Load(&Cpu, Game);
                Reset(&Cpu);
                for i in 0x0200..<0x600
                {
                    MemWrite(&Cpu, cast(u16)i, 0);
                }
                // NOTE(Barret5Ocal): this is wierd. do i even care about this. 
                sdl2.RenderClear(SdlPackage.Renderer);
                sdl2.RenderPresent(SdlPackage.Renderer);
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
