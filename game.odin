package game

import rl "vendor:raylib"

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

main :: proc() {
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

    platforms := []rl.Rectangle {
        {-20, 20, 96, 16},
        {90, -10, 96, 16},
        {100, -50, 96, 16},
    }

    platform_texture := rl.LoadTexture("platform.png")

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
        
        for platform in platforms {
            if rl.CheckCollisionRecs(player_feet_collider, platform) && player_vel.y > 0 {
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
        for platform in platforms {
            rl.DrawTextureV(platform_texture, {platform.x, platform.y}, rl.WHITE)
        }
        rl.EndMode2D()

        rl.EndDrawing()
    }

    rl.CloseWindow()                                    // Fecha a janela
}

