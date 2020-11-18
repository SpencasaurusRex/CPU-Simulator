package main

import "core:fmt"
import "../raylib"


IO :: struct 
{
    on : bool,
    id : int
};

Nand :: struct
{
    in0 : int,
    in1 : int,
    out : int
};

State :: struct 
{
    ios:                [dynamic]IO,           // All IOs
    changed:            [dynamic]int,          // IOs that changed in the last process step
    nands:              [dynamic]Nand,         // All Nand gates
    connections:        map[int][dynamic]int,  // Connections between IOs: id -> list of ids
    back_connections:   map[int]int,           // Reverse connection between IOs: end id -> start id
    nand_lookup:        map[int]int            // Lookup for: IO id -> Nand ID
}

create_io :: proc(state: ^State, on: bool = false) -> int
{
    new_io : IO;
    new_io.on = on;
    new_io.id = len(&state.ios);

    append(&state.ios, new_io);

    return new_io.id;
}

create_connection :: proc(state: ^State, from: int, to: int)
{
    exists := from in state.connections;
    if !exists do state.connections[from] = make([dynamic]int);

    append(&state.connections[from], to);
    append(&state.changed, from);
}

create_nand :: proc(state: ^State) -> (int,int,int)
{
    nand : Nand;
    nand.in0 = create_io(state);
    nand.in1 = create_io(state);
    nand.out = create_io(state);

    // TODO this won't exactly work if we're removing
    // nands dynamically in middle of list
    nand_id := len(&state.nands);

    append(&state.nands, nand);
    state.nand_lookup[nand.in0] = nand_id;
    state.nand_lookup[nand.in1] = nand_id;

    return nand.in0, nand.in1, nand.out;
}

set_io :: proc(state: ^State, id: int, on: bool)
{
    state.ios[id].on = on;
    append(&state.changed, id);
}

toggle_io :: proc(state: ^State, id: int)
{
    set_io(state, id, !state.ios[id].on);
}

init_state :: proc(state: ^State)
{
    state.ios = make([dynamic]IO);
    state.nands = make([dynamic]Nand);
    state.changed = make([dynamic]int);
    state.connections = make(map[int][dynamic]int);
    state.back_connections = make(map[int]int);
    state.nand_lookup = make(map[int]int);
}

basic_nand_scenario :: proc(state: ^State)
{
    i0 := create_io(state);
    i1 := create_io(state);
    
    i2,i3,i4 := create_nand(state);

    i5 := create_io(state);

    create_connection(state, i0, i2);
    create_connection(state, i1, i3);
    create_connection(state, i4, i5);
}

process_state :: proc(state: ^State)
{
    // Let's not get fancy until we know the rest works
    // ios := states.ios;
    // conns := states.connections;
    // nand_lookup := states.nand_lookup;

    changed_current := make([dynamic]int);
    for changed_id in state.changed 
    {
        fmt.println(changed_id, "changed");

        // Propagate changes across connections
        end_list, connection_exists := state.connections[changed_id];
        if connection_exists
        {
            for end_id in end_list
            {
                // Sync state
                state.ios[end_id].on = state.ios[changed_id].on;
                fmt.println(end_id, "=", state.ios[end_id].on);    
                append(&changed_current, end_id);
            }
        }

        // Calculate Nand gates
        nand_id, nand_exists := state.nand_lookup[changed_id];
        if nand_exists 
        {
            // TODO: could lead to nand calculation twice if both inputs are changed
            nand := state.nands[nand_id];
            on := !(state.ios[nand.in0].on && state.ios[nand.in1].on);
            set_io(state, nand.out, on);
        }
    }

    delete(state.changed);
    state.changed = changed_current;
}

draw_io :: proc(state: ^State, id: int, x: i32, y: i32)
{
    using raylib;

    IO_RADIUS :: 10;
    color := SKYBLUE if state.ios[id].on else DARKGRAY;

    draw_circle(x, y, IO_RADIUS, color);
}

draw_connection :: proc(x1: i32, y1: i32, x2: i32, y2: i32)
{
    using raylib;
    color := ORANGE;

    draw_line(x1, y1, x2, y2, color);
}

main :: proc()
{
    using raylib;

    screenWidth :i32 = 800;
    screenHeight :i32 = 450;

    set_config_flags(.WINDOW_RESIZABLE); 
    init_window(screenWidth, screenHeight, "CPU Simulator");
    
    set_target_fps(60);

    text_color := LIGHTGRAY;
    background := BLACK;

    state: State;
    init_state(&state);
    basic_nand_scenario(&state);

    for !window_should_close()
    {
        if is_key_pressed(.A) 
        {
            fmt.println("Toggle 0");
            toggle_io(&state, 0);
        }
        if is_key_pressed(.D) 
        {
            fmt.println("Toggle 1");
            toggle_io(&state, 1);
        }

        process_state(&state);

        begin_drawing();
        defer end_drawing();

        clear_background(background);
        
        draw_rectangle(350, 150, 100, 150, RED);
        draw_circle(450, 225, 75, RED);
        draw_circle(545, 225, 20, RED);

        draw_connection(200, 100, 275, 100);
        draw_connection(275, 100, 275, 200);
        draw_connection(275, 200, 350, 200);
        
        draw_connection(200, 350, 275, 350);
        draw_connection(275, 350, 275, 250);
        draw_connection(275, 250, 350, 250);
        
        draw_connection(545, 225, 700, 225);

        draw_io(&state, 0, 200, 100);
        draw_io(&state, 1, 200, 350);

        draw_io(&state, 2, 350, 200);
        draw_io(&state, 3, 350, 250);

        draw_io(&state, 4, 545, 225);

        draw_io(&state, 5, 700, 225);
    }

    close_window();
}