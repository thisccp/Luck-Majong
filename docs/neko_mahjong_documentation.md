# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 65.0  
**Última Atualização:** 08/03/2026

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
* [x] **5.5 Feedback Visual de Hint (UX)**: Implementação de Toast Message devidamente centralizada.
* [ ] **5.6 Novo Power-up (Shuffle) & Refatoração da HUD**: **[ATIVO - PRÓXIMA SESSÃO]** Implementação do 3º botão de poder (Shuffle) com animação em onda diagonal. **[Ajustes de UI inclusos: 1. Reorganizar ordem para Shuffle, Hint, Undo; 2. Corrigir cor/opacidade do botão Hint para igualar ao Undo]**.
* [ ] **5.2 Curva de Dificuldade Controlada (Refatoração do Gerador)**: Ajuste das alavancas matemáticas para escalar o desafio real. 1. **Abertura do Pool** (usar todos os 20 gatos em níveis difíceis para lotar o inventário); 2. **Verticalidade** (focar em layouts de "torres" com maior Z-index); 3. **Distância de Geração** (forçar o gerador a espalhar os pares de uma trinca entre o topo e a base oculta do tabuleiro).
* [ ] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação com Desfoque (Blur), mensagem temática e transição visual.
* [ ] **5.4 Fluxo de Vitória/Derrota**: Telas de conclusão, cálculo de pontuação e transição de nível.

### 🎵 Fase 6: Áudio e Sonoplastia (Sound Design)
* [ ] **6.1 Gerenciador de Áudio (Audio Manager)**: Criação de um Singleton na Godot para controlar os canais de áudio sem interromper sons concorrentes (ex: múltiplos *matches* simultâneos).
* [ ] **6.2 Efeitos Sonoros do Tabuleiro (SFX)**: Implementação de sons para interações físicas: clique em peça livre (som de pedra), clique em peça bloqueada (som de erro/recusa), som de embaralhar (Shuffle) e som do voo das peças (Undo).
* [ ] **6.3 Efeitos Sonoros de Interface (UI SFX)**: Sons para botões de menu, abertura de popups, alertas de Toast Message e telas de Vitória/Derrota.
* [ ] **6.4 Música de Fundo (BGM)**: Implementação de 3 variações de música Lo-fi no estilo de *Samurai Champloo*. Cada faixa terá cerca de 3 minutos de duração com transição suave para um loop perfeito. Incluir uma versão especial contendo miados suaves de gato mixados na batida. Opções de controle de volume (Mudo/Ativo) no menu de pausa.
* [ ] **6.5 Sincronia de Áudio e Animação**: Garantir que o som de *match* dispare exatamente no frame de colisão das peças no inventário.

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)**: Área de galeria onde o jogador desbloqueia novos tipos de gatos.
* [ ] **7.2 Progressão Temática e Expansão de Peças**: A cada marco de níveis (ex: a cada 10), o jogo muda o seu tema visual baseando-se numa raça de gato. Uma nova peça inédita da respectiva raça é injetada permanentemente no pool.
* [ ] **7.3 Expansão do Catálogo de Formatos (Shapes)**: Criação de novos layouts. Inclui a criação de **"fases de respiro"** com formatos divertidos e de resolução linear (ex: layout redondo resolvido em espiral).
* [ ] **7.4 Recursos Visuais Finais**: Substituição por assets definitivos (gatos e cenários), Splash Screens e Logos.
* [ ] **7.5 UI e Menus**: Menu de Título, Sistema de Loading, UI de Ads e retrabalho de popups. **(No Menu de Pausa: incluir Label com o número do Nível Atual e Botão de Sair do Jogo)**.
* [ ] **7.6 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **7.7 Funcionalidades Online (Low Priority)**: Placares globais/amigos.
* [ ] **7.8 Sistema de Recompensas por Marcos**: Baú a cada X níveis (+1 Hint, +1 Undo, +1 Revive). Opção de Ads para 2x.
* [ ] **7.9 Sistema de Revive F2P com Ads**: Novo comportamento do botão Reviver no Game Over (contador de 2 usos, mudando para botão de Vídeo/Ad quando esgotado).
* [ ] **7.10 Auto-Framing (Zoom Dinâmico)**: Ajuste do tamanho das peças baseado no layout atual.
* [ ] **7.11 Persistência de Sessão (Save/Load)**: Serialização do estado exato para retomar partidas.
* [ ] **7.12 Nova Animação de Match (Visual)**: Refatoração da animação de destruição das peças ao formar uma trinca no slot do inventário. Adição de um efeito de colisão física/impacto entre as 3 peças antes de desaparecerem.
* [ ] **7.13 Feedback Tátil (Haptic Feedback)**: Vibrações em três níveis: 1. Toque em peça bloqueada (breve); 2. Toque em peça livre (muito sutil); 3. Match de peças no slot (vibração de impacto, estritamente sincronizada com o clímax da animação da Fase 7.12 e o som da Fase 6.5).
* [ ] **7.14 Modificadores de Regra (Hidden Tiles/Gatos Dorminhocos)**: Peças nas camadas inferiores aparecem viradas para baixo (apenas o verso visível). O jogador só descobre a estampa ao remover a peça de cima.
* [ ] **7.15 Modos de Jogo Alternativos**: Quebra da monotonia com novos objetivos:
    * **Modo Resgate (Gatos Dourados)**: Peças douradas espalhadas pelas camadas (coleta instantânea, não vai para o slot).
    * **Modo Time Attack**: Nível clássico com um cronômetro desafiador no topo da tela.

---

## 🚨 2. Problemas Conhecidos (Lista de Bugs Ativos)
* **Nenhum bug crítico ativo no momento.** ---

## 🛠️ 3. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Flow de Dificuldade**: Ciclo de engajamento garantido por seeds determinísticas e controle algorítmico de profundidade/pool.
* **Economia F2P Híbrida**: Monetização sustentada por Ads.