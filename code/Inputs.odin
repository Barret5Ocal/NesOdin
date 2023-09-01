package NES

import "vendor:sdl2"

v2 :: struct #raw_union
{
    using _: struct {x, y: i32 },
    a : [2]i32,
}

digital_button :: struct 
{
    Down : bool,
    Up : bool,
}

inputs :: struct
{
    W : digital_button,
    Up: digital_button,
    A : digital_button,
    Left : digital_button,
    S: digital_button,
    Down : digital_button,
    D : digital_button,
    Right : digital_button,
    MouseLeft : digital_button,
    MouseMiddle : digital_button,
    MouseRight : digital_button,
    MouseMotion : v2,
    MouseWheel : v2,
}

GetInputs :: proc(Inputs : ^inputs)
{
    Inputs^ = inputs{};
    
    Event : sdl2.Event;
    
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
#partial switch Event.key.keysym.scancode
                {
                    case sdl2.Scancode.W: 
                    fallthrough;
                    case sdl2.Scancode.UP: 
                    {
                        Inputs.W.Down = true;
                        Inputs.Up.Down = true;
                    }
                    case sdl2.Scancode.A: 
                    fallthrough;
                    case sdl2.Scancode.LEFT: 
                    {
                        Inputs.A.Down = true;
                        Inputs.Left.Down = true;
                    }
                    case sdl2.Scancode.S: 
                    fallthrough;
                    case sdl2.Scancode.DOWN:
                    {
                        Inputs.S.Down = true;
                        Inputs.Down.Down = true;
                    }
                    case sdl2.Scancode.D: 
                    fallthrough;
                    case sdl2.Scancode.RIGHT: 
                    {
                        Inputs.D.Down = true;
                        Inputs.Right.Down = true;
                    }
                }
                
                
                
            }
            
            // TODO(Barret5Ocal): figure out how to put this in inputs
            case .MOUSEMOTION:
            Inputs.MouseMotion.a = [2]i32{Event.motion.x, Event.motion.y};
            case .MOUSEWHEEL:
            Inputs.MouseWheel.a = [2]i32{Event.wheel.x, Event.wheel.y};
            
            case .MOUSEBUTTONDOWN:
            {
                switch Event.button.button
                {
                    case sdl2.BUTTON_LEFT:  
                    Inputs.MouseLeft.Down = true;
                    case sdl2.BUTTON_MIDDLE: 
                    Inputs.MouseMiddle.Down = true;
                    case sdl2.BUTTON_RIGHT:  
                    Inputs.MouseRight.Down = true;
                }
            }
            case .MOUSEBUTTONUP:
            {
                switch Event.button.button
                {
                    case sdl2.BUTTON_LEFT:  
                    Inputs.MouseLeft.Up = true;
                    case sdl2.BUTTON_MIDDLE: 
                    Inputs.MouseMiddle.Up = true;
                    case sdl2.BUTTON_RIGHT:  
                    Inputs.MouseRight.Up = true;
                }
            }
            
            
        }
    }
    
}