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
   player_run_width := f32(a.texture.width)   // Calcula e arruma a escala do personagem
   player_run_height := f32(a.texture.height) // Calcula e arruma a escala do personagem

   draw_player_source := rl.Rectangle {            // Posiciona o personagem
       x = f32(a.current_frame) * player_run_width / f32(a.num_frames),  // Anima o personagem substituindo pelo frame do png
       y = 0,
       width = player_run_width / f32(a.num_frames),
       height = player_run_height,
   }

   if flip {                                        // Testa se tem de inverter o frame do personagem
       draw_player_source.width = -draw_player_source.width    // Espelha o frame do personagem desenhando invertido
   }

   draw_player_dest := rl.Rectangle {              // Anima o personagem com os quadros do png
       x = pos.x,
       y = pos.y,
       width = player_run_width * 4 / f32(a.num_frames),
       height = player_run_height * 4              // Ajusta a escala do personagem
   }

//   rl.DrawRectangleV(pos, {64, 64}, rl.GREEN)  // Espaço do personagem como um simples quadrado verde pleno
//   rl.DrawTextureEx(a.texture, pos, 0, 4, rl.WHITE)  // Desenha o png do personagem (estranho e super pequeno)
//   rl.DrawTextureRec(a.texture, draw_player_source, pos, rl.WHITE)  // Desenha o png do personagem (estranho)
   rl.DrawTexturePro(a.texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)  // Desenha um frame personagem
}

main :: proc() {
    rl.InitWindow(1280, 720, "My First Game")       // Cria tela 720p (HD)
    player_pos := rl.Vector2 { 640, 320 }
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

    for !rl.WindowShouldClose() {                   // Roda o loop enquanto não pedir pra fechar a janela
        rl.BeginDrawing()
//        rl.ClearBackground(rl.BLUE)               // Pinta o fundo de azul pleno
        rl.ClearBackground({110, 184, 168, 255})    // Pinta o fundo de ciano

        if rl.IsKeyDown(.LEFT) {                    // Move pra esquerda
            player_flip = true                      // Inverte o frame do personagem
            player_vel.x = -400                     // 400 pixels por segundo

            if current_anim.name != .Run {
                current_anim = player_run
            }

        } else if rl.IsKeyDown(.RIGHT) {            // Move pra direita
            player_flip = false                     // Normaliza o frame do personagem
            player_vel.x = 400                      // 400 pixels por segundo

            if current_anim.name != .Run {
                current_anim = player_run
            }

        } else {                                    // Para
            player_vel.x = 0
            if current_anim.name != .Idle {
                current_anim = player_idle
            }

        }

        player_vel.y += 2000 * rl.GetFrameTime()    // Ativa a gravidade, o chão será o limite da tela

        if player_grounded && rl.IsKeyPressed(.SPACE) { // Pula
            player_vel.y = -600                         // 600 pixels por segundo
            player_grounded = false
        }

        if !player_grounded && player_shinobi && rl.IsKeyPressedRepeat(.SPACE) {  // Pulo duplo como ninja
            player_vel.y = -1000                        // 1000 pixles por segundo pra ir bem mais rápido
            player_shinobi = false
        }

        player_pos += player_vel * rl.GetFrameTime()

        if player_pos.y > f32(rl.GetScreenHeight()) - 64 {
            player_pos.y = f32(rl.GetScreenHeight()) - 64
            player_grounded = true
            player_shinobi = true
        }

        update_animation(&current_anim)                 // chama function da animação passando ponteiro pra posição do frame

        draw_animation(current_anim, player_pos, player_flip) // chama function de desenhar passando o quadro do frame, posicao do personagem e se está invertido

        rl.EndDrawing()
    }

    rl.CloseWindow()                                    // Fecha a janela
}

