package main

import "core:fmt"
import "../raylib"
import "core:math"

IO :: struct 
{
    on : bool,
    id : int,
    x : i32,
    y : i32
};

Nand :: struct
{
    in0 : int,
    in1 : int,
    out : int,
    x: i32,
    y: i32
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

create_nand :: proc(state: ^State, x: i32, y: i32) -> (int,int,int)
{
    nand : Nand;
    nand.in0 = create_io(state);
    nand.in1 = create_io(state);
    nand.out = create_io(state);

    move_nand(state, &nand, x, y);

    // TODO this won't exactly work if we're removing
    // nands dynamically in middle of list
    nand_id := len(&state.nands);

    append(&state.nands, nand);
    state.nand_lookup[nand.in0] = nand_id;
    state.nand_lookup[nand.in1] = nand_id;

    return nand.in0, nand.in1, nand.out;
}

move_nand :: proc(state: ^State, nand: ^Nand, x: i32, y: i32)
{
    // TODO: More robust transform system to replace this
    state.ios[nand.in0].x = x + 0;
    state.ios[nand.in0].y = y + 50;

    state.ios[nand.in1].x = x + 0;
    state.ios[nand.in1].y = y + 100;

    state.ios[nand.out].x = x + 190;
    state.ios[nand.out].y = y + 75;

    nand.x = x;
    nand.y = y;
}

set_io :: proc(state: ^State, id: int, on: bool)
{
    if state.ios[id].on != on 
    {
        append(&state.changed, id);
    }

    state.ios[id].on = on;
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
    
    i2,i3,i4 := create_nand(state, 350, 150);

    i5 := create_io(state);

    create_connection(state, i0, i2);
    create_connection(state, i1, i3);
    create_connection(state, i4, i5);
}

self_not_scenario :: proc(state: ^State)
{
    i0,i1,out := create_nand(state, 350, 150);

    create_connection(state, out, i0);
    create_connection(state, out, i1);
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

    
}

draw_connection :: proc(x1: i32, y1: i32, x2: i32, y2: i32)
{
    using raylib;
    color := ORANGE;

    draw_line(x1, y1, x2, y2, color);
}

draw_nand :: proc(x: i32, y: i32)
{
    using raylib;
    color := RED;

    draw_rectangle(x, y, 100, 150, color);
    draw_circle(x+100, y+75, 75, color);
    draw_circle(x+190, y+75, 20, color);
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
    //basic_nand_scenario(&state);
    self_not_scenario(&state);

    frame := 0;

    for !window_should_close()
    {
        if is_key_pressed(.A) 
        {
            toggle_io(&state, 0);
        }
        if is_key_pressed(.D) 
        {
            toggle_io(&state, 1);
        }

        process_state(&state);

        begin_drawing();
        defer end_drawing();

        clear_background(background);
        
        for nand in state.nands
        {
            draw_nand(nand.x, nand.y);
        }

        for io in state.ios 
        {
            IO_RADIUS :: 10;
            color := SKYBLUE if io.on else DARKGRAY;
            draw_circle(io.x, io.y, IO_RADIUS, color);
        }

        theta : f32 = f32(frame) * f32(.1);
        move_nand(&state, &state.nands[0], 
            i32(350 + math.cos(theta) * 20), 
            i32(150 + math.sin(theta) * 20)
        );

        frame = frame + 1;
    }

    close_window();
}