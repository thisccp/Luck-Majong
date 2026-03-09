# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 70.0  
**Última Atualização:** 09/03/2026

---

## 📈 1. Roadmap Integral de Desenvolvimento

### ✅ Fase 1: Fundação e Estrutura Básica (Concluído)
* [x] **Setup da Engine**: Configuração do ambiente Godot para mobile.
* [x] **Arquitetura de Classes**: Estrutura `BoardManager` e `MahjongTile`.
* [x] **Atlas de Texturas**: Lógica de carregamento e gestão do `image_0.png`.
* [x] **Layout Turtle**: Implementação inicial da estrutura clássica.

### ✅ Fase 2: Mecânicas e Regras de Jogo (Concluído)
* [x] **Geração Reversa**: Algoritmo para tabuleiros 100% solucionáveis.
* [x] **Sistema de Inventário**: Implementação dos 4 slots de armazenamento.
* [x] **Regra 90/10**: Lógica de bloqueio por pixel (10% de cobertura).
* [x] **Bloqueio Lateral**: Validação de peças livres através das bordas.

### ✅ Fase 3: Renderização e Imersão (Concluído)
* [x] **3.1 - 3.4**: Sincronização via `await`, Escala Dinâmica e Maximização de Sprites.
* [x] **3.5 Neko Block (Verticalização)**: Transição para layout Portrait (Pillar de 6 colunas) validado para escala premium no S25.
* [x] **3.6 Ajuste de Contato**: Implementação do encaixe "Beijo de Pixel", sobreposição tátil (Z+1) e correção do Drop Shadow.

### ✅ Fase 4: Sistemas de Apoio e Economia (Concluído)
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar slots, persistência visual e trava anti-spam. Correção visual para desligar dica no Game Over.
* [x] **4.2 Reverse (Undo)**: Retorno ao grid com animação de voo e Z-index dinâmico.
* [x] **4.3 Drag & Peek (Arrasto Livre)**: Mecânica tátil com retorno elástico, protegendo o estado visual.
* [x] **4.4 UI de Cargas e Ads**: Remoção de bloqueio visual, adição de labels numéricos e popup genérico de recarga (+2 usos) individual por poder.

### ✅ Pré-Fase 5: Refatoração e Otimização Arquitetural (Concluído)
* [x] **Separação de Responsabilidades**: Refatoração da interface de Ads/Popups para cenas independentes (`.tscn`), blindando a lógica principal de UI gerada por código.

### 🚀 Fase 5: Progressão Procedural e Flow (EM EXECUÇÃO)
* [x] **5.1 Gerador Determinístico de Formatos**: Algoritmo utilizando a "Seed" do nível para garantir layouts fixos por fase.
* [x] **5.2 Curva de Dificuldade Controlada (Refatoração do Gerador)**: Implementação da dificuldade infinita por "Mundos" (curva senoidal baseada no `world_index`). Escalonamento da variedade de gatos (`cat_variety`) e verticalidade através da injeção de pares extras (`layer_boost_pairs`). Regra de Oclusão (90/10) corrigida para o eixo Y.
* [x] **5.5 Feedback Visual de Hint (UX)**: Implementação de Toast Message devidamente centralizada e com trava anti-spam.
* [x] **5.6 Novo Power-up (Shuffle) & Refatoração da HUD**: Implementação do 3º botão de poder (Shuffle) com animação em onda diagonal (0.5s). Ordem ajustada na UI e texturas unificadas.
* [x] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação com overlay escuro, mensagem dinâmica de nível, aviso em destaque para "Níveis Difíceis" (baseado na curva senoidal) e transições suaves (Fade-In/Fade-Out) via Tweens. Aplicado Fade-In/Out também ao Popup de Vitória.
* [ ] **5.7 Sistema de Pontuação e Combos (HUD)**: Lógica de pontuação em tempo real. *Pendente de Definição de Game Design:* Estabelecer a pontuação base por formar um par normal, as circunstâncias exatas de tempo para ativar o combo e a tabela de multiplicadores (ex: x2, x3, x4). Inclusão do contador de Score (Label) e barra de tempo no topo da tela do gameplay.
* [ ] **5.4 Fluxo de Vitória/Derrota**: Telas de conclusão definitivas. Implementar condição de Derrota (Slots cheios sem pares possíveis) com Popup de Game Over e integração do botão "Reviver". Finalizar a transição lógica de nível (salvar progresso e carregar o próximo nível) no fluxo de Vitória.

### 🎵 Fase 6: Áudio e Sonoplastia (Sound Design)
* [ ] **6.1 Gerenciador de Áudio (Audio Manager)**: Criação de um Singleton na Godot para controlar os canais de áudio sem interromper sons concorrentes (ex: múltiplos *matches* simultâneos).
* [ ] **6.2 Efeitos Sonoros do Tabuleiro (SFX)**: Implementação de sons para interações físicas: clique em peça livre (som de pedra), clique em peça bloqueada (som de erro/recusa), som de embaralhar (Shuffle) e som do voo das peças (Undo).
* [ ] **6.3 Efeitos Sonoros de Interface (UI SFX)**: Sons para botões de menu, abertura de popups, alertas de Toast Message e telas de Vitória/Derrota.
* [ ] **6.4 Música de Fundo (BGM)**: Implementação de 3 variações de música Lo-fi no estilo de *Samurai Champloo*. Cada faixa terá cerca de 3 minutos de duração com transição suave para um loop perfeito. Incluir uma versão especial contendo miados suaves de gato mixados na batida. Opções de controle de volume (Mudo/Ativo) no menu de pausa.
* [ ] **6.5 Sincronia de Áudio e Animação**: Garantir que o som de *match* dispare exatamente no frame de colisão das peças no inventário.
* [ ] **6.6 Locução de Feedback (Announcer)**: Implementação de vozes de incentivo ("Good!", "Nice!", "Perfect!", "Awesome!") disparadas ao atingir marcos específicos do sistema de Combos (Fase 5.7).

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)**: Área de galeria onde o jogador desbloqueia novos tipos de gatos.
* [ ] **7.2 Progressão Temática e Expansão de Peças**: A cada marco de níveis (ex: a cada 10), o jogo muda o seu tema visual baseando-se numa raça de gato. Uma nova peça inédita da respectiva raça é injetada permanentemente no pool.
* [ ] **7.3 Expansão do Catálogo de Formatos (Shapes)**: Criação de novos layouts. Inclui a criação de **"fases de respiro"** com formatos divertidos e de resolução linear (ex: layout redondo resolvido em espiral).
* [ ] **7.4 Recursos Visuais Finais**: Substituição por assets definitivos (gatos, cenários e UI/Botões), Splash Screens e Logos. *(Nota: A arte dos botões de poder - Hint, Undo, Shuffle - e do Menu Hamburguer já foi substituída e atualizada pelo Diretor).*
* [ ] **7.5 UI e Menus**: Menu de Título, Sistema de Loading, UI de Ads e retrabalho de popups. **(No Menu de Pausa: incluir Label com o número do Nível Atual e implementar o botão de "Voltar ao Título" usando o asset `back title` já disponível na pasta `assets/btn`)**.
* [ ] **7.6 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **7.7 Funcionalidades Online (Low Priority)**: Placares globais/amigos.
* [ ] **7.8 Sistema de Recompensas por Marcos**: Baú a cada X níveis (+1 Hint, +1 Undo, +1 Revive). Opção de Ads para 2x.
* [ ] **7.9 Sistema de Revive F2P com Ads**: Novo comportamento do botão Reviver no Game Over (contador de 2 usos, mudando para botão de Vídeo/Ad quando esgotado).
* [ ] **7.10 Auto-Framing (Zoom Dinâmico)**: Ajuste do tamanho das peças baseado no layout atual.
* [ ] **7.11 Persistência de Sessão (Cloud Save & Local)**: Serialização do estado exato para retomar partidas. Implementação de sistema de Login com a Conta Google (via Google Play Games Services ou Firebase) para habilitar o "Cloud Save". O progresso, o nível atual (`world_index`) e o inventário do jogador serão salvos na nuvem, permitindo a sincronização contínua entre múltiplos dispositivos e a recuperação de dados.
* [ ] **7.12 Nova Animação de Match (Visual)**: Refatoração da animação de destruição das peças ao formar um par no slot do inventário. Adição de um efeito de colisão física/impacto entre as 2 peças antes de desaparecerem.
* [ ] **7.13 Feedback Tátil (Haptic Feedback)**: Vibrações em três níveis: 1. Toque em peça bloqueada (breve); 2. Toque em peça livre (muito sutil); 3. Match de peças no slot (vibração de impacto, estritamente sincronizada com o clímax da animação da Fase 7.12 e o som da Fase 6.5).
* [ ] **7.14 Modos de Jogo Alternativos**: Quebra da monotonia com novos objetivos e mecânicas:
    * **Modo Resgate (Gatos Dourados)**: Peças douradas espalhadas pelas camadas (coleta instantânea, não vai para o slot).
    * **Modo Time Attack**: Nível clássico com um cronômetro desafiador no topo da tela.
    * **Modo Memória (Gatos Escondidos)**: Algumas peças do tabuleiro começam viradas para baixo (mostrando apenas o verso). 
        * **Regra de Espiar:** Ao clicar em uma peça virada, ela gira e revela a estampa.
        * **Limite de Revelação:** Apenas 1 peça dessas pode ficar revelada por vez. Se o jogador espiar uma nova peça virada, a anterior gira de volta escondendo a estampa.
        * **Match Direto:** Se a peça, ao ser revelada, formar um par com outra que já está no gatilho do jogador (sendo a primeira ou a segunda peça do match), o par é validado.
        * **Ir para o Inventário:** Se a peça já estiver revelada (mostrando a frente) e o jogador clicar nela novamente, ela sobe fisicamente para ocupar um dos 4 slots do inventário.
* [ ] **7.15 Animação de Bloqueio (Shake Visual)**: Feedback visual ao clicar em uma peça que está bloqueada (pela regra 90/10 ou pelas laterais). A peça deve realizar um *Tween* rápido tremendo no eixo X para indicar recusa. Preparado para sincronizar com o som de erro (Fase 6.2) e a vibração (Fase 7.13).
* [ ] **7.16 Remoção do Estado "Acinzentado" (Em Análise)**: Avaliar a possibilidade de abandonar o escurecimento visual das peças bloqueadas. A indicação de que uma peça está presa passaria a depender exclusivamente da interação do jogador, através do feedback tátil (7.13), do som de erro (6.2) e da animação de recusa/shake (7.15).
* [ ] **7.17 Recompensas e Vitórias Diárias (Lembrete)**: Criar um sistema para incentivar o login e o jogo diário (ex: bônus ao completar a primeira vitória do dia, ou sequência de logins consecutivos). *Pendente de refinamento de Game Design.*
* [ ] **7.18 Sistema de Moeda In-Game (Economia Interna)**: Lembrete para planear a implementação de uma "Soft Currency" (moedas virtuais). Servirá para adquirir novos gatos para a Galeria (Meta-Jogo) ou como métrica para o placar online (caso implementado).

---

## 🚨 2. Problemas Conhecidos (Lista de Bugs Ativos)
* **Nenhum bug crítico ativo no momento.** A matemática de Match-2 está sólida e a interface está estável.

---
## 🛠️ 3. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Flow de Dificuldade**: Curva infinita por Mundos (Match-2 Perfeito).
* **Economia F2P Híbrida**: Monetização sustentada por Ads e pontos de estrangulamento nos níveis altos.