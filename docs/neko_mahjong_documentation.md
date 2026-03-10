# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 75.0  
**Última Atualização:** 10/03/2026

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
* [x] **Regra 55/45 (Antiga 90/10)**: Lógica de bloqueio vertical recalibrada. A tolerância de sobreposição foi aumentada para 45% para suportar offsets agressivos de perspectiva 3D (estilo cascata/Vita Mahjong) sem gerar falsos bloqueios.
* [x] **Bloqueio Lateral**: Validação de peças livres através das bordas na mesma camada (Z-index).

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
* [x] **5.2 Curva de Dificuldade Controlada (Refatoração do Gerador)**: Implementação da dificuldade infinita por "Mundos" (curva senoidal baseada no `world_index`). Escalonamento da variedade de gatos (`cat_variety`) e verticalidade através da injeção de pares extras (`layer_boost_pairs`). Regra de Oclusão corrigida para o eixo Y.
* [x] **5.5 Feedback Visual de Hint (UX)**: Implementação de Toast Message devidamente centralizada e com trava anti-spam.
* [x] **5.6 Novo Power-up (Shuffle) & Refatoração da HUD**: Implementação do 3º botão de poder (Shuffle) com animação em onda diagonal (0.5s). Ordem ajustada na UI e texturas unificadas.
* [x] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação com overlay escuro, mensagem dinâmica de nível, aviso em destaque para "Níveis Difíceis" (baseado na curva senoidal) e transições suaves (Fade-In/Fade-Out) via Tweens. Aplicado Fade-In/Out também ao Popup de Vitória.
* [x] **5.7 Sistema Avançado de Score e Combos (HUD)**: Matemática de Score com teto (Base 250, sobe +35, máx 600). Sistema de Tiers (1 a 6) com evolução baseada em ciclos de 5 combos. Regra de Perdão Inteligente (Tier 1 perdoa tudo; Tier 2+ perdoa 1 errada, falhas quebram combo). Punição Late-Game (-70 pontos por 2 erros seguidos no Tier 3+). Adição de texto animado "Combo X" e "Fever Mode" visual (vinheta de tela inteira em degradê). Reset de pontuação e combo na transição de nível.
* [x] **5.8 Readequação da Interface (Contadores de Power-ups)**: Reposicionamento dos números (labels) de usos restantes para o padrão "Notification Badge" (canto superior direito) usando âncoras da Godot, e aumento ergonômico da área de toque dos botões.
* [x] **5.9 Polimento Sistêmico e UX (Quality of Life)**: 
    * **Safe Area & UI:** Placar de Score descido e reajustado (Fonte 30, Offset 70) para fugir do *notch*/câmera frontal. Adição de margem de "respiro" no texto de Combo.
    * **Auditoria de Combos:** Regras blindadas para Power-ups.
    * **Integração Hint vs Shuffle:** O uso do Shuffle agora cancela instantaneamente as dicas ativas com fix de escala para o inventário.
    * **Feedback Anti-Spam:** Adicionada Toast Message ("Sem peças válidas") ao usar o botão Undo com o inventário vazio.
* [x] **5.4 Fluxo de Vitória/Derrota (Greybox)**: Core loop fechado com telas funcionais de transição de nível (Vitória) e Game Over com Revive. *(Nota: O polimento visual e retrabalho de UI destas telas ocorrerá na Fase 7.5).*
* [x] **5.10 Remoção do Estado "Acinzentado" & Shake Visual**: O tabuleiro passa a ser 100% colorido. Remoção do escurecimento das peças bloqueadas. Em substituição, implementado feedback visual de erro com animação de tremor (Shake no eixo X) ao clicar numa peça presa, com Hitbox expandida via padding (+10px) para garantir precisão no toque mobile (Regra do Dedo Gordo). **(Nota de Design: Esta animação servirá como âncora para sincronização com o som de erro na Fase 6.2 e o Feedback Háptico na Fase 7.11).**
* [ ] **5.11 Auto-Framing (Zoom Dinâmico)**: Ajuste automático do tamanho das peças/câmera baseado no layout gerado proceduralmente, garantindo que níveis avançados e muito largos não vazem da tela.
* [ ] **5.12 Sistema de Revive F2P com Ads**: Lógica avançada do botão Reviver no Game Over (contador de 2 usos gratuitos, mudando para botão de Vídeo/Ad quando esgotado).

### 🎵 Fase 6: Áudio e Sonoplastia (Sound Design)
* [ ] **6.1 Gerenciador de Áudio (Audio Manager)**: Criação de um Singleton na Godot para controlar os canais de áudio sem interromper sons concorrentes.
* [ ] **6.2 Efeitos Sonoros do Tabuleiro (SFX)**: Implementação de sons para interações físicas: clique em peça livre (pedra), clique em peça bloqueada (erro/recusa sincronizado com a animação 5.10), Shuffle e Undo.
* [ ] **6.3 Efeitos Sonoros de Interface (UI SFX)**: Sons para botões de menu, popups, Toast Message e telas finais.
* [ ] **6.4 Música de Fundo (BGM)**: Implementação de 3 variações de música Lo-fi (*Samurai Champloo* style) com opções de controle (Mudo/Ativo).
* [ ] **6.5 Sincronia de Áudio e Animação**: Som de *match* disparado no frame exato de colisão no inventário.
* [ ] **6.6 Locução de Feedback (Announcer)**: Vozes de incentivo ("Good!", "Perfect!") atreladas aos Combos.

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)**: Área de galeria onde o jogador desbloqueia novos tipos de gatos.
* [ ] **7.2 Progressão Temática e Expansão de Peças**: Mudança de tema visual e introdução de novas peças baseadas em raças de gatos a cada X níveis.
* [ ] **7.3 Expansão do Catálogo de Formatos (Level Design & Variedade)**: Criação de novos layouts focando em duas filosofias de ritmo de jogo:
    * **1. O Nosso Diferencial (Fases de Respiro & Formatos Divertidos):** Layouts artísticos e relaxantes projetados para quebrar a tensão. Formatos divertidos e de resolução linear (ex: layout redondo resolvido em espiral, silhuetas de patas ou peixes), onde o fluxo de jogo é rápido e altamente satisfatório (Dopamine hit).
    * **2. Inspiração Estratégica (Estilo Vita Mahjong):** Níveis desafiadores para as fases "Boss". Inclui *O Fosso (The Well)* (torres altas nas bordas e centro raso), *Tijolos Intercalados* (usando `pixel_offset` para criar paredes de bloqueio duplo) e *Pontes (Bridges)* (ilhas isoladas conectadas por arcos em Z superior).
* [ ] **7.4 Recursos Visuais Finais**: Substituição por assets definitivos, Splash Screens e Logos.
* [ ] **7.5 UI e Menus**: Menu de Título, Sistema de Loading, UI de Ads e retrabalho final dos popups de Vitória/Derrota.
* [ ] **7.6 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **7.7 Funcionalidades Online (Low Priority)**: Placares globais/amigos.
* [ ] **7.8 Sistema de Recompensas por Marcos**: Baú a cada X níveis (+1 Hint, +1 Undo, +1 Revive).
* [ ] **7.9 Persistência de Sessão (Cloud Save & Local)**: Serialização do estado exato para retomar partidas e integração com Google Play Games/Firebase.
* [ ] **7.10 Nova Animação de Match (Visual)**: Refatoração da animação de destruição com efeito de impacto físico.
* [ ] **7.11 Feedback Tátil (Haptic Feedback)**: Vibrações sincronizadas em três níveis (bloqueio, toque livre e impacto de match).
* [ ] **7.12 Modos de Jogo Alternativos**: Gatos Dourados, Time Attack, Modo Memória (Gatos Escondidos).
* [ ] **7.13 Recompensas e Vitórias Diárias (Lembrete)**: Sistema de login diário.
* [ ] **7.14 Sistema de Moeda In-Game (Economia Interna)**: "Soft Currency" para a Galeria.
* [ ] **7.15 Polimento Visual (Fever Mode)**: Partículas no "Fever Mode" para níveis altos de combo.

---

## 🚨 2. Problemas Conhecidos (Lista de Bugs Ativos)
* **Nenhum bug crítico ativo no momento.** Matemática de Match-2, Hitbox Lógica e Regra 55/45 estáveis e validadas.

---
## 🛠️ 3. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Flow de Dificuldade**: Curva infinita por Mundos (Match-2 Perfeito).
* **Economia F2P Híbrida**: Monetização sustentada por Ads e pontos de estrangulamento nos níveis altos.