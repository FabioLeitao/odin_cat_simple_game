package game

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(1280, 720, "My First Game")       // Cria tela 720p (HD)
    player_pos := rl.Vector2 { 640, 320 }
    player_vel: rl.Vector2
    player_grounded: bool
    player_shinobi: bool
    player_run_texture := rl.LoadTexture("cat_run.png") // Textura dos frames do personagem
    player_run_num_frames := 4
    player_run_frame_timer: f32
    player_run_current_frame: int
    player_run_frame_length := f32(0.1)
    player_flip: bool                               // Sentido do personagem dependendo do sentido do movimento

    for !rl.WindowShouldClose() {                   // Roda o loop enquanto não pedir pra fechar a janela
        rl.BeginDrawing()
//        rl.ClearBackground(rl.BLUE)               // Pinta o fundo de azul pleno
        rl.ClearBackground({110, 184, 168, 255})    // Pinta o fundo de ciano

        if rl.IsKeyDown(.LEFT) {                    // Move pra esquerda
            player_flip = true                      // Inverte o frame do personagem
            player_vel.x = -400                     // 400 pixels por segundo
        } else if rl.IsKeyDown(.RIGHT) {            // Move pra direita
            player_flip = false                     // Normaliza o frame do personagem
            player_vel.x = 400                      // 400 pixels por segundo
        } else {                                    // Para
            player_vel.x = 0
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

        player_run_width := f32(player_run_texture.width)   // Calcula e arruma a escala do personagem
        player_run_height := f32(player_run_texture.height) // Calcula e arruma a escala do personagem

        player_run_frame_timer += rl.GetFrameTime()     // Calcula do frame da animação do personagem

        if player_run_frame_timer > player_run_frame_length {
            player_run_current_frame += 1
            player_run_frame_timer = 0

            if player_run_current_frame == player_run_num_frames {
                player_run_current_frame = 0
            }
        }

        draw_player_source := rl.Rectangle {            // Posiciona o personagem
//            x = 0,
            x = f32(player_run_current_frame) * player_run_width / f32(player_run_num_frames),  // Anima o personagem substituindo pelo frame do png
            y = 0,
            width = player_run_width / f32(player_run_num_frames),
            height = player_run_height,
        }

        if player_flip {                                // Testa se tem de inverter o frame do personagem
            draw_player_source.width = -draw_player_source.width    // Espelha o frame do personagem desenhando invertido
        }

        draw_player_dest := rl.Rectangle {              // Anima o personagem com os quadros do png
            x = player_pos.x,
            y = player_pos.y,
            width = player_run_width * 4 / f32(player_run_num_frames),
            height = player_run_height * 4              // Ajusta a escala do personagem
        }

//        rl.DrawRectangleV(player_pos, {64, 64}, rl.GREEN)  // Espaço do personagem como um simples quadrado verde pleno
//        rl.DrawTextureEx(player_run_texture, player_pos, 0, 4, rl.WHITE)  // Desenha o png do personagem (estranho e super pequeno)
//        rl.DrawTextureRec(player_run_texture, draw_player_source, player_pos, rl.WHITE)  // Desenha o png do personagem (estranho)
        rl.DrawTexturePro(player_run_texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)  // Desenha um frame personagem
        rl.EndDrawing()
    }

    rl.CloseWindow()                                    // Fecha a janela
}

