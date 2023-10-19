package NES 

import mu"vendor:microui"
import "vendor:sdl2"
import "core:fmt"

UI_WIDTH :: 540;
UI_HEIGHT :: 700;

debug_state :: enum
{
    STARTUP,
    NORMAL,
    BREAKPOINT,
    STEPONCE,
    RESET,
}

debug_data := struct 
{
    ProgramStart : u16,
    ProgramCounter : u16,
    State : debug_state,
}{}

debug_code_data_entry :: struct 
{
    Code : u8,
    Len : u8,
    Arg1 : u8,
    Arg2 : u8,
    RealPosition : u16,
    LineNumber : int,
    Breakpoint : bool,
}

// TODO(Barret5Ocal): Need to find a way to get the size of this array
DebugCodeData : [dynamic]debug_code_data_entry;

state := struct
{
	mu_ctx: mu.Context,
	log_buf:         [1<<16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg: mu.Color,
	
	atlas_texture: ^sdl2.Texture,
}{
	bg = {90, 95, 100, 255},
}

UIRender : ^sdl2.Renderer; 

CreateUIWindow :: proc()
{
    
    UiWindow:= sdl2.CreateWindow("UI Window",  50, sdl2.WINDOWPOS_CENTERED, UI_WIDTH, UI_HEIGHT, {.SHOWN});
    if UiWindow == nil 
    {
		fmt.eprintln(sdl2.GetError());
        return;
	}
    ///*
    backend_idx: i32 = -1;
    if n := sdl2.GetNumRenderDrivers(); n <= 0 
    {
		fmt.eprintln("No render drivers available");
        return;
	} 
    else 
    {
		for i in 0..<n {
			info: sdl2.RendererInfo
                if err := sdl2.GetRenderDriverInfo(i, &info); err == 0
            {
				// NOTE(bill): "direct3d" seems to not work correctly
				if info.name == "opengl"
                {
					backend_idx = i;
                    break;
				}
			}
		}
	}
    
    renderer : ^sdl2.Renderer = sdl2.CreateRenderer(UiWindow, -1, {.ACCELERATED, .PRESENTVSYNC});
    if renderer == nil 
    {
		fmt.eprintln("SDL.CreateRenderer:", sdl2.GetError());
        return;
	}
    UIRender = renderer;
    
    //sdl2.RenderSetLogicalSize(renderer, WIN_WIDTH, WIN_HEIGHT);
    
    state.atlas_texture = sdl2.CreateTexture(renderer, u32(sdl2.PixelFormatEnum.RGBA32), .TARGET, mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT);
    assert(state.atlas_texture != nil);
    if err := sdl2.SetTextureBlendMode(state.atlas_texture, .BLEND); err != 0 
    {
		fmt.eprintln("sdl2.SetTextureBlendMode:", err);
        return;
	}
	
    pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH*mu.DEFAULT_ATLAS_HEIGHT);
    for alpha, i in mu.default_atlas_alpha 
    {
		pixels[i].rgb = 0xff;
        pixels[i].a   = alpha;
	}
    
    if err := sdl2.UpdateTexture(state.atlas_texture, nil, raw_data(pixels), 4*mu.DEFAULT_ATLAS_WIDTH); err != 0
    {
		fmt.eprintln("SDL.UpdateTexture:", err);
        return;
	}
    
    ctx := &state.mu_ctx;
    mu.init(ctx);
    
    ctx.text_width = mu.default_atlas_text_width;
    ctx.text_height = mu.default_atlas_text_height;
    
}

UISetup :: proc(Rom : ^rom)
{
    r : int =0;
    for i := 0; i < len(Rom.Prg_rom); i += 1 //for g in Game 
    {
        g := Rom.Prg_rom[i];
        Opcode := OpcodeMap[g];
        
        Arg1 : u8;
        Arg2 : u8;
        if Opcode.Len == 2 
        {
            Arg1 = Rom.Prg_rom[i + 1];
        }
        else if Opcode.Len == 3 
        {
            Arg1 = Rom.Prg_rom[i + 1]; 
            Arg2 = Rom.Prg_rom[i + 2];
        }
        
        append(&DebugCodeData, cast(debug_code_data_entry){Opcode.Code, Opcode.Len, Arg1, Arg2, cast(u16)i, r, false});
        
        
        i += cast(int)(Opcode.Len - 1); 
        
        r += 1; 
        
    }
    
    //debug_data.State = debug_state.BREAKPOINT; 
}

CurrentStepData : ^debug_code_data_entry;

UpdateUI :: proc(Cpu : ^cpu, Inputs : ^inputs)
{
    ctx := &state.mu_ctx;
    
    mu.input_mouse_move(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y);
    
    mu.input_scroll(ctx, Inputs.MouseWheel.x * 30, Inputs.MouseWheel.y * -30);
    
    if Inputs.MouseLeft.Down do mu.input_mouse_down(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y, .LEFT);
    
    if Inputs.MouseLeft.Up do mu.input_mouse_up(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y, .LEFT);
    if Inputs.MouseMiddle.Down do mu.input_mouse_down(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y, .MIDDLE);
    if Inputs.MouseMiddle.Up do mu.input_mouse_up(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y, .MIDDLE);
    if Inputs.MouseRight.Down do mu.input_mouse_down(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y, .LEFT);
    if Inputs.MouseRight.Up do mu.input_mouse_up(ctx, Inputs.MouseMotion.x, Inputs.MouseMotion.y, .RIGHT);
    
    if Inputs.Space.Down 
    {
        if debug_data.State == debug_state.NORMAL do debug_data.State = debug_state.BREAKPOINT;
        else if debug_data.State == debug_state.BREAKPOINT do debug_data.State = debug_state.NORMAL;
    }
    if Inputs.B.Down 
    {
        if debug_data.State  == debug_state.BREAKPOINT
        {
            debug_data.State = debug_state.STEPONCE;
        }
    }
    
    @static opts := mu.Options{.NO_CLOSE};
    mu.begin(ctx);
    
    if mu.window(ctx, "Game Code", {40, 40, 350, 450}, opts)
    {
        
        for e, i in DebugCodeData
        {
            mu.layout_row(ctx, {54, 25, 100, 54, 54}, 0);
            mu.checkbox(ctx, "", &DebugCodeData[i].Breakpoint);
            mu.label(ctx, fmt.tprintf("%i", i));
            Opcode := OpcodeMap[e.Code];
            mu.label(ctx, fmt.tprintf("%s", Opcode.Mnemonic));
            if e.Len == 2 
            {
                mu.label(ctx, fmt.tprintf("0x%X", e.Arg1));
            }
            else if e.Len == 3 
            {
                mu.label(ctx, fmt.tprintf("0x%X 0x%X", e.Arg1, e.Arg2));
            }
            
            if e.RealPosition == debug_data.ProgramCounter
            {
                mu.label(ctx, "Current");
                //CurrentStepData = e;
                CurrentStepData = &DebugCodeData[i];
                
                if e.Breakpoint && debug_data.State == debug_state.NORMAL do debug_data.State = debug_state.BREAKPOINT;
            }
            
        }
        
    }
    
    if mu.window(ctx, "Screen Data", {400, 40, 100, 400}, opts)
    {
        
        
        for i in 0x0200..<0x600
        {
            ColorIndex := MemRead(Cpu, cast(u16)i);
            if ColorIndex > 0 
            {
                mu.layout_row(ctx, {54, 25, 100, -1}, 0);
                mu.label(ctx, fmt.tprintf("0x%X", i));
                mu.label(ctx, fmt.tprintf("%i", ColorIndex));
            }
        }
        
    }
    
    // TODO(Barret5Ocal): need to be able to put breakpoints on individual points in the code. 
    if mu.window(ctx, "Interface", {40, 500, 200, 150}, opts) 
    {
        if debug_data.State == debug_state.STARTUP
        {
            if .SUBMIT in mu.button(ctx, "Run Code")
            {
                if debug_data.State == debug_state.STARTUP do debug_data.State = debug_state.NORMAL;
            }
        }
        else 
        {
            if .SUBMIT in mu.button(ctx, "Break Code")
            {
                if debug_data.State == debug_state.NORMAL do debug_data.State = debug_state.BREAKPOINT;
                else if debug_data.State == debug_state.BREAKPOINT do debug_data.State = debug_state.NORMAL;
                
            }
            
            if .SUBMIT in mu.button(ctx, "Step")
            {
                if debug_data.State  == debug_state.BREAKPOINT
                {
                    debug_data.State = debug_state.STEPONCE;
                }
            }
            
            if .SUBMIT in mu.button(ctx, "Reset")
            {
                
                debug_data.State = debug_state.RESET;
            }
            
        }
        
        mu.layout_row(ctx, {64, -1}, 0);
        
        if CurrentStepData != nil
        {
            Opcode := OpcodeMap[CurrentStepData.Code];
            mu.label(ctx, fmt.tprintf("%i", CurrentStepData.LineNumber));
            mu.label(ctx, fmt.tprintf("%s", Opcode.Mnemonic));
            
            mu.layout_row(ctx, {54}, 0);
            mu.label(ctx, fmt.tprintf("%s", debug_data.State));
            //mu.label(ctx, fmt.tprintf("%s", Opcode.Mnemonic));
        }
    }
    
    if mu.window(ctx, "Watch", {300, 500, 200, 200}, opts)
    {
        mu.layout_row(ctx, {64, -1}, 0);
        mu.label(ctx, fmt.tprintf("Register A"));
        mu.label(ctx, fmt.tprintf("%i", Cpu.RegisterA));
        
        mu.layout_row(ctx, {64, -1}, 0);
        mu.label(ctx, fmt.tprintf("Register X"));
        mu.label(ctx, fmt.tprintf("%i", Cpu.RegisterX));
        
        mu.layout_row(ctx, {64, -1}, 0);
        mu.label(ctx, fmt.tprintf("Register Y"));
        mu.label(ctx, fmt.tprintf("%i", Cpu.RegisterY));
        
        Inputs := MemRead(Cpu, 0xff);
        mu.layout_row(ctx, {100}, 0);
        mu.label(ctx, fmt.tprintf("Inputs: 0x%X", Inputs));
        
        mu.layout_row(ctx, {100}, 0);
        mu.label(ctx, fmt.tprintf("Snake Head: 0x%X", MemReadu16(Cpu, 0x10)));
        
        mu.layout_row(ctx, {100}, 0);
        mu.label(ctx, fmt.tprintf("Snake Length: 0x%X", MemRead(Cpu, 0x03)));
        
        mu.layout_row(ctx, {100}, 0);
        mu.label(ctx, fmt.tprintf("Direction: 0x%X", MemRead(Cpu, 0x02)));
        
    }
    
    mu.end(ctx);
    
}

RenderUI :: proc()
{
    
    ctx := &state.mu_ctx;
    renderer: ^sdl2.Renderer = UIRender;
    
    render_texture :: proc(renderer: ^sdl2.Renderer, dst: ^sdl2.Rect, src: mu.Rect, color: mu.Color) 
    {
        dst.w = src.w;
        dst.h = src.h;
        
        sdl2.SetTextureAlphaMod(state.atlas_texture, color.a);
        sdl2.SetTextureColorMod(state.atlas_texture, color.r, color.g, color.b);
        sdl2.RenderCopy(renderer, state.atlas_texture, &sdl2.Rect{src.x, src.y, src.w, src.h}, dst);
    }
    
    viewport_rect := &sdl2.Rect{};
    sdl2.GetRendererOutputSize(renderer, &viewport_rect.w, &viewport_rect.h);
    sdl2.RenderSetViewport(renderer, viewport_rect);
    sdl2.RenderSetClipRect(renderer, viewport_rect);
    sdl2.SetRenderDrawColor(renderer, state.bg.r, state.bg.g, state.bg.b, state.bg.a);
    sdl2.RenderClear(renderer);
    
    command_backing: ^mu.Command;
    for variant in mu.next_command_iterator(ctx, &command_backing) 
    {
        switch cmd in variant 
        {
            case ^mu.Command_Text:
            dst := sdl2.Rect{cmd.pos.x, cmd.pos.y, 0, 0};
            for ch in cmd.str do if ch&0xc0 != 0x80
            {
                r := min(int(ch), 127);
                src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r];
                render_texture(renderer, &dst, src, cmd.color);
                dst.x += dst.w;
            }
            
            case ^mu.Command_Rect:
            {
                sdl2.SetRenderDrawColor(renderer, cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a);
                sdl2.RenderFillRect(renderer, &sdl2.Rect{cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h});
            }
            
            case ^mu.Command_Icon:
            {
                src := mu.default_atlas[cmd.id];
                x := cmd.rect.x + (cmd.rect.w - src.w)/2;
                y := cmd.rect.y + (cmd.rect.h - src.h)/2;
                render_texture(renderer, &sdl2.Rect{x, y, 0, 0}, src, cmd.color);
            }
            
            case ^mu.Command_Clip:
            {
                sdl2.RenderSetClipRect(renderer, &sdl2.Rect{cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h});
            }
            
            case ^mu.Command_Jump: 
            {unreachable();}
            
        }
    }
    
    sdl2.RenderPresent(renderer);
}