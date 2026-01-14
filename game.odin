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

        player_run_width := f32(current_anim.texture.width)   // Calcula e arruma a escala do personagem
        player_run_height := f32(current_anim.texture.height) // Calcula e arruma a escala do personagem

        current_anim.frame_timer += rl.GetFrameTime()     // Calcula do frame da animação do personagem

        if current_anim.frame_timer > current_anim.frame_length {
            current_anim.current_frame += 1
            current_anim.frame_timer = 0

            if current_anim.current_frame == current_anim.num_frames {
                current_anim.current_frame = 0
            }
        }

        draw_player_source := rl.Rectangle {            // Posiciona o personagem
//            x = 0,
            x = f32(current_anim.current_frame) * player_run_width / f32(current_anim.num_frames),  // Anima o personagem substituindo pelo frame do png
            y = 0,
            width = player_run_width / f32(current_anim.num_frames),
            height = player_run_height,
        }

        if player_flip {                                // Testa se tem de inverter o frame do personagem
            draw_player_source.width = -draw_player_source.width    // Espelha o frame do personagem desenhando invertido
        }

        draw_player_dest := rl.Rectangle {              // Anima o personagem com os quadros do png
            x = player_pos.x,
            y = player_pos.y,
            width = player_run_width * 4 / f32(current_anim.num_frames),
            height = player_run_height * 4              // Ajusta a escala do personagem
        }

//        rl.DrawRectangleV(player_pos, {64, 64}, rl.GREEN)  // Espaço do personagem como um simples quadrado verde pleno
//        rl.DrawTextureEx(current_anim.texture, player_pos, 0, 4, rl.WHITE)  // Desenha o png do personagem (estranho e super pequeno)
//        rl.DrawTextureRec(current_anim.texture, draw_player_source, player_pos, rl.WHITE)  // Desenha o png do personagem (estranho)
        rl.DrawTexturePro(current_anim.texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)  // Desenha um frame personagem
        rl.EndDrawing()
    }

    rl.CloseWindow()                                    // Fecha a janela
}

