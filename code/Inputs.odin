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
    Space : digital_button,
    B : digital_button,
    MouseMotion : v2,
    MouseWheel : v2,
}

Mousepersist : v2;
//Wheelpersist : v2;

GetInputs :: proc(Inputs : ^inputs) -> bool
{
    Inputs^ = inputs{};
    Inputs.MouseMotion = Mousepersist;
    //Inputs.MouseWheel = Wheelpersist;
    
    for e : sdl2.Event; sdl2.PollEvent(&e) == true;
    {
#partial switch e.type
        {
            case .QUIT:
            {
                sdl2.Quit();
            }
            
            case .KEYDOWN:
            {
#partial switch e.key.keysym.scancode
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
                    case .SPACE: 
                    {
                        Inputs.Space.Down = true;
                    }
                    case .B:
                    Inputs.B.Down = true;
                }
                
            }
            case .KEYUP:
            {
#partial switch e.key.keysym.scancode
                {
                    case sdl2.Scancode.W: 
                    fallthrough;
                    case sdl2.Scancode.UP: 
                    {
                        Inputs.W.Up = true;
                        Inputs.Up.Up = true;
                    }
                    case sdl2.Scancode.A: 
                    fallthrough;
                    case sdl2.Scancode.LEFT: 
                    {
                        Inputs.A.Up = true;
                        Inputs.Left.Up = true;
                    }
                    case sdl2.Scancode.S: 
                    fallthrough;
                    case sdl2.Scancode.DOWN:
                    {
                        Inputs.S.Up = true;
                        Inputs.Down.Up = true;
                    }
                    case sdl2.Scancode.D: 
                    fallthrough;
                    case sdl2.Scancode.RIGHT: 
                    {
                        Inputs.D.Up = true;
                        Inputs.Right.Up = true;
                    }
                    case .SPACE: 
                    {
                        Inputs.Space.Up = true;
                    }
                    case .B:
                    Inputs.B.Up = true;
                }
                
            }
            
            case .MOUSEMOTION:
            {
                Mousepersist.a = [2]i32{e.motion.x, e.motion.y}
                Inputs.MouseMotion = Mousepersist;
            }
            case .MOUSEWHEEL:
            Inputs.MouseWheel.a = [2]i32{e.wheel.x, e.wheel.y};
            
            case .MOUSEBUTTONDOWN:
            {
                switch e.button.button
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
                switch e.button.button
                {
                    case sdl2.BUTTON_LEFT:  
                    Inputs.MouseLeft.Up = true;
                    case sdl2.BUTTON_MIDDLE: 
                    Inputs.MouseMiddle.Up = true;
                    case sdl2.BUTTON_RIGHT:  
                    Inputs.MouseRight.Up = true;
                }
            }
            
            case .WINDOWEVENT:
            {
                if e.window.event == sdl2.WindowEventID.CLOSE
                {
                    return false;
                }
            }
        }
    }
    
    return true;
    
}