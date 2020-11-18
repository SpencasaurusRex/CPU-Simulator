package main

import "core:fmt"
import "../raylib"


io : struct 
{
    state : bool,
    id : i64
};


main :: proc()
{
    using raylib;

    // Initialization
    //--------------------------------------------------------------------------------------
    screenWidth :i32 = 800;
    screenHeight :i32 = 450;

    set_config_flags(.WINDOW_RESIZABLE);
    init_window(screenWidth, screenHeight, "CPU Simulator");
    
    set_target_fps(60);
    //--------------------------------------------------------------------------------------

    text_color := LIGHTGRAY;
    background := BLACK;

    // Main game loop
    for !window_should_close()    // Detect window close button or ESC key
    {
        is_window_resized();

        {
            begin_drawing();
            defer end_drawing();

            clear_background(background);
            draw_text("You did the thing", 190, 200, 20, text_color);
        }
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------   
    close_window();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}