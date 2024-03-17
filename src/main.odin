package main

import "core:fmt"

main :: proc()
{
    game_start()
    defer game_stop()

    game_loop()
}
