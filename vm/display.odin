package vm

import "core:fmt"
import "vendor:sdl2"

WIDTH :: 128
HEIGHT :: 128
PIXEL_COUNT :: WIDTH * HEIGHT
VRAM_START_ADDR :: (MEMORY_CAPACITY - 1) - (PIXEL_COUNT)
SCALE_FACTOR :: 4
SCREEN_WIDTH :: WIDTH * SCALE_FACTOR
SCREEN_HEIGHT :: HEIGHT * SCALE_FACTOR
SCREEN_FPS :: 60
SCREEN_TPS :: 1000 / SCREEN_FPS
WINDOW_FLAGS :: sdl2.WINDOW_SHOWN
RENDER_FLAGS :: sdl2.RENDERER_ACCELERATED

Display :: struct {
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
}

new_display :: proc() -> Display {
    w := sdl2.CreateWindow(
        "OASM Display",
        sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, 
        SCREEN_WIDTH, SCREEN_HEIGHT, 
        WINDOW_FLAGS,
    )

    r := sdl2.CreateRenderer(w, -1, RENDER_FLAGS)
    sdl2.RenderSetLogicalSize(r, SCREEN_WIDTH, SCREEN_HEIGHT)
    sdl2.SetRenderDrawColor(r, 0, 0, 0, 0)
    sdl2.RenderClear(r)
    sdl2.RenderPresent(r)

    return Display{window = w, renderer = r}
}

display_draw :: proc(v: ^VM, pixles: []byte) {
    for j := 0; j < HEIGHT; j += 1 {
        for i := 0; i < WIDTH; i += 1 {
            index := j*WIDTH + i // Note the swap of indices here
            r, g, b, a := byte_to_color(pixles[index])
            rect := &sdl2.Rect{i32(i*SCALE_FACTOR), i32(j*SCALE_FACTOR), i32(SCALE_FACTOR), i32(SCALE_FACTOR)}
    
            sdl2.SetRenderDrawColor(v.display.renderer, r, g, b, a)
            sdl2.RenderFillRect(v.display.renderer, rect)
        }
    }
    
    sdl2.RenderPresent(v.display.renderer)
}

@(private)
byte_to_color :: proc(value: byte) -> (r, g, b, a: u8) {
    switch value {
        case 1: return 0xff, 0x00, 0x00, 0xff // red
        case 2: return 0x00, 0xff, 0x00, 0xff // green
        case 3: return 0x00, 0x00, 0xff, 0xff // blue
        case 4: return 0xfe, 0xfe, 0xfe, 0xff // white
    }

    return 0x00, 0x00, 0x00, 0xff // black
}