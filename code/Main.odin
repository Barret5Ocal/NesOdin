package NES

import "vendor:sdl2"

import "core:math/rand"

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
    
    Game : [dynamic]u8 = {0x20, 0x06, 0x06, 0x20, 0x38, 0x06, 0x20, 0x0d, 0x06, 0x20, 0x2a, 0x06, 0x60, 0xa9, 0x02,
        0x85, 0x02, 0xa9, 0x04, 0x85, 0x03, 0xa9, 0x11, 0x85, 0x10, 0xa9, 0x10, 0x85, 0x12, 0xa9,
        0x0f, 0x85, 0x14, 0xa9, 0x04, 0x85, 0x11, 0x85, 0x13, 0x85, 0x15, 0x60, 0xa5, 0xfe, 0x85,
        0x00, 0xa5, 0xfe, 0x29, 0x03, 0x18, 0x69, 0x02, 0x85, 0x01, 0x60, 0x20, 0x4d, 0x06, 0x20,
        0x8d, 0x06, 0x20, 0xc3, 0x06, 0x20, 0x19, 0x07, 0x20, 0x20, 0x07, 0x20, 0x2d, 0x07, 0x4c,
        0x38, 0x06, 0xa5, 0xff, 0xc9, 0x77, 0xf0, 0x0d, 0xc9, 0x64, 0xf0, 0x14, 0xc9, 0x73, 0xf0,
        0x1b, 0xc9, 0x61, 0xf0, 0x22, 0x60, 0xa9, 0x04, 0x24, 0x02, 0xd0, 0x26, 0xa9, 0x01, 0x85,
        0x02, 0x60, 0xa9, 0x08, 0x24, 0x02, 0xd0, 0x1b, 0xa9, 0x02, 0x85, 0x02, 0x60, 0xa9, 0x01,
        0x24, 0x02, 0xd0, 0x10, 0xa9, 0x04, 0x85, 0x02, 0x60, 0xa9, 0x02, 0x24, 0x02, 0xd0, 0x05,
        0xa9, 0x08, 0x85, 0x02, 0x60, 0x60, 0x20, 0x94, 0x06, 0x20, 0xa8, 0x06, 0x60, 0xa5, 0x00,
        0xc5, 0x10, 0xd0, 0x0d, 0xa5, 0x01, 0xc5, 0x11, 0xd0, 0x07, 0xe6, 0x03, 0xe6, 0x03, 0x20,
        0x2a, 0x06, 0x60, 0xa2, 0x02, 0xb5, 0x10, 0xc5, 0x10, 0xd0, 0x06, 0xb5, 0x11, 0xc5, 0x11,
        0xf0, 0x09, 0xe8, 0xe8, 0xe4, 0x03, 0xf0, 0x06, 0x4c, 0xaa, 0x06, 0x4c, 0x35, 0x07, 0x60,
        0xa6, 0x03, 0xca, 0x8a, 0xb5, 0x10, 0x95, 0x12, 0xca, 0x10, 0xf9, 0xa5, 0x02, 0x4a, 0xb0,
        0x09, 0x4a, 0xb0, 0x19, 0x4a, 0xb0, 0x1f, 0x4a, 0xb0, 0x2f, 0xa5, 0x10, 0x38, 0xe9, 0x20,
        0x85, 0x10, 0x90, 0x01, 0x60, 0xc6, 0x11, 0xa9, 0x01, 0xc5, 0x11, 0xf0, 0x28, 0x60, 0xe6,
        0x10, 0xa9, 0x1f, 0x24, 0x10, 0xf0, 0x1f, 0x60, 0xa5, 0x10, 0x18, 0x69, 0x20, 0x85, 0x10,
        0xb0, 0x01, 0x60, 0xe6, 0x11, 0xa9, 0x06, 0xc5, 0x11, 0xf0, 0x0c, 0x60, 0xc6, 0x10, 0xa5,
        0x10, 0x29, 0x1f, 0xc9, 0x1f, 0xf0, 0x01, 0x60, 0x4c, 0x35, 0x07, 0xa0, 0x00, 0xa5, 0xfe,
        0x91, 0x00, 0x60, 0xa6, 0x03, 0xa9, 0x00, 0x81, 0x10, 0xa2, 0x00, 0xa9, 0x01, 0x81, 0x10,
        0x60, 0xa6, 0xff, 0xea, 0xea, 0xca, 0xd0, 0xfb, 0x60,};
    
    Cpu : cpu; 
    Load(&Cpu, Game);
    Reset(&Cpu);
    
    RunWithCallback(&Cpu, &SdlPackage, proc(Cpu : ^cpu, Sdl : ^sdl_package)
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
                    });
    
    //sdl2.UpdateWindowSurface(SdlPackage.Window);
    
    
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
            // TODO(Barret5Ocal): Why can't i assign to these values
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
