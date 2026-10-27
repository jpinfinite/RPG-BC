shader_type canvas_item;

// Parâmetros que você pode alterar diretamente no Inspetor do Godot
uniform vec4 cor_contorno : source_color = vec4(0.6, 0.0, 0.1, 1.0); // Vermelho carmesim
uniform vec4 cor_nucleo : source_color = vec4(0.0, 0.0, 0.0, 1.0);    // Preto absoluto
uniform float velocidade_pulso : hint_range(0.1, 10.0) = 3.0;
uniform float intensidade_brilho : hint_range(0.0, 5.0) = 1.5;

// Função que roda para cada pixel da imagem
void fragment() {
    // Pega a textura original do sprite de ataque
    vec4 tex_cor = texture(TEXTURE, UV);
    
    // Se o pixel original for transparente, não faz nada
    if (tex_cor.a == 0.0) {
        discard;
    }
    
    // Cria um efeito de pulso baseado no tempo real do jogo
    float pulso = sin(TIME * velocidade_pulso) * 0.5 + 0.5;
    
    // Calcula a proximidade das bordas usando o canal alpha ou cor original
    float borda = 1.0 - tex_cor.r; 
    
    // Mistura a cor do núcleo (preto) com o contorno (vermelho) baseado no pulso e nas bordas
    vec4 cor_final = mix(cor_nucleo, cor_contorno * intensidade_brilho, borda * pulso);
    
    // Mantém a transparência original do sprite original
    cor_final.a = tex_cor.a;
    
    COLOR = cor_final;
}
