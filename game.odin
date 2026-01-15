#+feature dynamic-literals      // necessario para permitir dynamic allocators, com risco de memory leak
package game

import rl "vendor:raylib"
import "core:mem"               // necessario para previnir memory leak rastreando uso de allocators pra devolver pro OS
import "core:fmt"               // necessario para formatar strings do debug de memory allocator
import "core:encoding/json"     // necessario pra exportar o nivel como json
import "core:os"                // necessario pra interagir com os, como escrever o arquivo json de nivel

Animation_Name :: enum {
    Idle,
    Run,
}

Animation :: struct {                               // Arruma as variaveis do objeto animação numa struct
    texture: rl.Texture2D,
    num_frames: int,
    frame_timer: f32,
    current_frame: int,
    frame_length: f32,
    name: Animation_Name,
}

update_animation :: proc(a: ^Animation) {
    a.frame_timer += rl.GetFrameTime()              // Calcula do frame da animação do personagem

    if a.frame_timer > a.frame_length {
       a.current_frame += 1
       a.frame_timer = 0

       if a.current_frame == a.num_frames {
           a.current_frame = 0
       }
   }
}

draw_animation :: proc(a: Animation, pos: rl.Vector2, flip: bool) {
   width := f32(a.texture.width)        // Calcula e arruma a escala do personagem
   height := f32(a.texture.height)      // Calcula e arruma a escala do personagem

   source := rl.Rectangle {             // Posiciona o personagem
       x = f32(a.current_frame) * width / f32(a.num_frames),  // Anima o personagem substituindo pelo frame do png
       y = 0,
       width = width / f32(a.num_frames),
       height = height,
   }

   if flip {                                        // Testa se tem de inverter o frame do personagem
       source.width = -source.width     // Espelha o frame do personagem desenhando invertido
   }

   dest := rl.Rectangle {               // Anima o personagem com os quadros do png
       x = pos.x,
       y = pos.y,
       width = width / f32(a.num_frames),
       height = height                  // Ajusta a escala do personagem
   }

   rl.DrawTexturePro(a.texture, source, dest, {dest.width/2, dest.height}, 0, rl.WHITE)  // Desenha um frame do personagem na raiz
}

PixelWindowHeight :: 180

Level :: struct {
    platforms: [dynamic]rl.Vector2
}

platform_collider :: proc(pos: rl.Vector2) -> rl.Rectangle {
    return {
        pos.x, pos.y,
        96, 16
    }
}

main :: proc() {
    track: mem.Tracking_Allocator                   // rastrando momory allocators pra previnir memory leak
    mem.tracking_allocator_init(&track, context.allocator)  // inicializando o default
    context.allocator = mem.tracking_allocator(&track)

    defer { // força o proximo bloco de codigo {} a rodar depois que terminar o main :: proc() {}, ou seja, qndo for terminar o programa
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)  // loga pra debug onde e quanto houve memory leak
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)  // loga pra debug em qual array houve memory leak sem liberar de qq array
        }
        mem.tracking_allocator_destroy(&track)     // destroy o allocator pra apagar a memory leak detectada na marra
    }

    rl.InitWindow(1280, 720, "My First Game")       // Cria tela 720p (HD)
    rl.SetWindowPosition(200,200)
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(500)
    player_pos: rl.Vector2 
    player_vel: rl.Vector2
    player_grounded: bool
    player_shinobi: bool
    player_flip: bool                               // Sentido do personagem dependendo do sentido do movimento

    player_run := Animation {                       // Popula a struct do objeto com valores relevantes pra animação
        texture = rl.LoadTexture("cat_run.png"),    // Textura dos frames do personagem correndo
        num_frames = 4,
        frame_length = 0.1,                         // Temporiza os frames
        name = .Run
    }

    player_idle := Animation {
        texture = rl.LoadTexture("cat_idle.png"),   // Textura dos frames do personagem parado
        num_frames = 2,
        frame_length = 0.5,                         // Temporiza os frames
        name = .Idle,
    }

    current_anim := player_idle

    level: Level

    if level_data, ok := os.read_entire_file("level.json", context.temp_allocator); ok {
        if json.unmarshal(level_data, &level) != nil {     // tenta alocar o conteudo do json no array level se for compativel
            append(&level.platforms, rl.Vector2 { -20, 20 }) // cria uma plataforma minima em caso de falha
        }
    } else {
        append(&level.platforms, rl.Vector2 { -20, 20 }) // cria uma plataforma minima em caso de falha
    }

    platform_texture := rl.LoadTexture("platform.png")

    editing := false

    for !rl.WindowShouldClose() {                   // Roda o loop enquanto não pedir pra fechar a janela
        rl.BeginDrawing()
        rl.ClearBackground({110, 184, 168, 255})    // Pinta o fundo de ciano

        if rl.IsKeyDown(.LEFT) {                    // Move pra esquerda
            player_flip = true                      // Inverte o frame do personagem
            player_vel.x = -100                     // 100 pixels por segundo

            if current_anim.name != .Run {
                current_anim = player_run
            }

        } else if rl.IsKeyDown(.RIGHT) {            // Move pra direita
            player_flip = false                     // Normaliza o frame do personagem
            player_vel.x = 100                      // 100 pixels por segundo

            if current_anim.name != .Run {
                current_anim = player_run
            }

        } else {                                    // Para
            player_vel.x = 0
            if current_anim.name != .Idle {
                current_anim = player_idle
            }

        }

        player_vel.y += 1000 * rl.GetFrameTime()    // Ativa a gravidade, o chão será o limite da tela

        if player_grounded && rl.IsKeyPressed(.SPACE) { // Pula
            player_vel.y = -300                         // 300 pixels por segundo
//            player_shinobi = true
        }

//        if player_shinobi && rl.IsKeyPressedRepeat(.SPACE) {  // Pulo duplo como ninja
//            player_vel.y = -1000                        // 1000 pixles por segundo pra ir bem mais rápido
//        }

        player_pos += player_vel * rl.GetFrameTime()

        player_feet_collider := rl.Rectangle {
            player_pos.x - 4,
            player_pos.y - 4,
            8,
            4,
        }

        player_grounded = false
        player_shinobi = false
        
        for platform in level.platforms {
            if rl.CheckCollisionRecs(player_feet_collider, platform_collider(platform)) && player_vel.y > 0 {
                player_vel.y = 0
                player_pos.y = platform.y
                player_grounded = true
//              player_shinobi = true
            }
        }

        update_animation(&current_anim)                 // chama function da animação passando ponteiro pra posição do frame

        screen_height := f32(rl.GetScreenHeight())

        camera := rl.Camera2D {
            zoom = screen_height/PixelWindowHeight,
            offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
            target = player_pos,
        }

        rl.BeginMode2D(camera)
        draw_animation(current_anim, player_pos, player_flip) // chama function de desenhar passando o quadro do frame, posicao do personagem e se está invertido
//        rl.DrawRectangleRec(player_feet_collider, {0, 255, 0, 100})   // Descomentar para debugar se necessario
        for platform in level.platforms {
            rl.DrawTextureV(platform_texture, platform, rl.WHITE)
        }

        if rl.IsKeyPressed(.F2) {
            editing = !editing
        }

        if editing {
           mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)  // mouse position

           rl.DrawTextureV(platform_texture, mp, rl.WHITE)

           if rl.IsMouseButtonPressed(.LEFT) {
                append(&level.platforms, mp)    // adiciona o vector2 da plataforma nova no dynamic array
           }

           if rl.IsMouseButtonPressed(.RIGHT) {
                for p, idx in level.platforms {
                    if rl.CheckCollisionPointRec(mp, platform_collider(p)) {
                        unordered_remove(&level.platforms, idx)
                        break                   // para o loop pq ja achamos a plataform a ser apagada, e mudamos o tamanho do array
                    }
                }
           }
        }

        rl.EndMode2D()

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    rl.CloseWindow()                                    // Fecha a janela

    if level_data, err := json.marshal(level, allocator = context.temp_allocator); err == nil {   // exporta o level pra json se nao houver err
        os.write_entire_file("level.json", level_data)
    }

    free_all(context.temp_allocator)
    delete(level.platforms)                             // apaga o array de plataformas para evitar o memory leak

//    rl.UnloadTexture(platform_texture)
//    rl.UnloadTexture(player_run.texture)
//    rl.UnloadTexture(player_idle.texture)
}
