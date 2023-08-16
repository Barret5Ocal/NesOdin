package NES 

import mu"vendor:microui"
import "vendor:sdl2"
import "core:fmt"

state := struct {
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
    UiWindow:= sdl2.CreateWindow("UI Window",  50, sdl2.WINDOWPOS_CENTERED, 540, 700, {.SHOWN, .RESIZABLE});
    if UiWindow == nil 
    {
		fmt.eprintln(sdl2.GetError());
        return;
	}
    
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
    
    renderer : ^sdl2.Renderer = sdl2.CreateRenderer(UiWindow, backend_idx, {.ACCELERATED, .PRESENTVSYNC});
    if renderer == nil 
    {
		fmt.eprintln("SDL.CreateRenderer:", sdl2.GetError());
        return;
	}
    UIRender = renderer;
    
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

u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) 
{
	mu.push_id(ctx, uintptr(val));
    
    @static tmp: mu.Real;
    tmp = mu.Real(val^);
    res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER});
    val^ = u8(tmp);
    mu.pop_id(ctx);
    return;
}


write_log :: proc(str: string)
{
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], str);
    state.log_buf_len += copy(state.log_buf[state.log_buf_len:], "\n");
    state.log_buf_updated = true;
}

UpdateUI :: proc()
{
    ctx := &state.mu_ctx;
    
    @static opts := mu.Options{.NO_CLOSE};
	mu.begin(ctx);
    
	if mu.window(ctx, "Demo Window", {40, 40, 300, 450}, opts)
    {
		if .ACTIVE in mu.header(ctx, "Window Info") 
        {
			win := mu.get_current_container(ctx);
            mu.layout_row(ctx, {54, -1}, 0);
            mu.label(ctx, "Position:");
            mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y));
            mu.label(ctx, "Size:");
            mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h));
		}
		
		
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
			sdl2.SetRenderDrawColor(renderer, cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a);
            sdl2.RenderFillRect(renderer, &sdl2.Rect{cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h});
            case ^mu.Command_Icon:
			src := mu.default_atlas[cmd.id];
            x := cmd.rect.x + (cmd.rect.w - src.w)/2;
            y := cmd.rect.y + (cmd.rect.h - src.h)/2;
            render_texture(renderer, &sdl2.Rect{x, y, 0, 0}, src, cmd.color);
            case ^mu.Command_Clip:
			sdl2.RenderSetClipRect(renderer, &sdl2.Rect{cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h});
            case ^mu.Command_Jump: 
			unreachable();
		}
	}
	
	sdl2.RenderPresent(renderer);
}