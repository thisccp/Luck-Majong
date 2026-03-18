# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 84.4
**Última Atualização:** 18/03/2026
**Status Atual:** Fase de Otimização Mobile CONCLUÍDA (Arquitetura Mega Bake)

---

## 📈 1. Roadmap Integral de Desenvolvimento

### ✅ Fase 1: Fundação e Estrutura Básica (Concluído)
* [x] **Setup da Engine**: Configuração do ambiente Godot para mobile.
* [x] **Arquitetura de Classes**: Estrutura `BoardManager` e `MahjongTile`.
* [x] **Atlas de Texturas**: Lógica de carregamento e gestão do `image_0.png`.
* [x] **Layout Turtle**: Implementação inicial da estrutura clássica.

### ✅ Fase 2: Mecânicas e Regras de Jogo (Concluído)
* [x] **Regra 55/45 (Antiga 90/10)**: Lógica de bloqueio vertical recalibrada. A tolerância de sobreposição foi aumentada para 45% para suportar offsets agressivos de perspectiva 3D (estilo cascata/Vita Mahjong) sem gerar falsos bloqueios.
* [x] **Geração Reversa**: Algoritmo para tabuleiros 100% solucionáveis.
* [x] **Sistema de Inventário**: Implementação dos 4 slots de armazenamento.
* [x] **Bloqueio Lateral**: Validação de peças livres através das bordas na mesma camada (Z-index).

### ✅ Fase 3: Renderização e Imersão (Concluído)
* [x] **3.1 - 3.4**: Sincronização via `await`, Escala Dinâmica e Maximização de Sprites.
* [x] **3.5 Neko Block (Verticalização)**: Transição para layout Portrait (Pillar de 6 colunas) validado para escala premium no S25.
* [x] **3.6 Ajuste de Contato**: Implementação do encaixe "Beijo de Pixel", sobreposição tátil (Z+1) e correção do Drop Shadow.

### ✅ Fase 4: Sistemas de Apoio e Economia (Concluído)
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar slots, persistência visual e trava anti-spam. Correção visual para desligar dica no Game Over.
* [x] **4.2 Reverse (Undo)**: Retorno ao grid com animação de voo e Z-index dinâmico.
* [x] **4.3 Drag & Peek (Arrasto Livre)**: Mecânica tátil com retorno elástico, protegendo o estado visual.
* [x] **4.4 UI de Cargas e Ads**: Remoção de bloqueio visual, adição de labels numéricos e popup de recarga (+2 usos) individual por poder.

### ✅ Pré-Fase 5: Refatoração e Otimização Arquitetural (Concluído)
* [x] **Separação de Responsabilidades**: Refatoração da interface de Ads/Popups para cenas independentes (`.tscn`), blindando a lógica principal de UI gerada por código.

### ✅ Fase 5: Progressão Procedural e Flow (Concluído)
* [x] **5.1 Gerador Determinístico de Formatos**: Algoritmo utilizando a "Seed" do nível para garantir layouts fixos por fase.
* [x] **5.2 Curva de Dificuldade Controlada (Refatoração do Gerador)**: Implementação da dificuldade infinita por "Mundos" (curva senoidal baseada no `world_index`). Escalonamento da variedade de gatos (`cat_variety`) e verticalidade através da injeção de pares extras (`layer_boost_pairs`). Regra de Oclusão corrigida para o eixo Y.
* [x] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação com overlay escuro, mensagem dinâmica de nível, aviso em destaque para "Níveis Difíceis" (baseado na curva senoidal) e transições suaves via Tweens. Aplicado Fade-In/Out também ao Popup de Vitória.
* [x] **5.4 Fluxo de Vitória/Derrota (Greybox)**: Core loop fechado com telas funcionais de transição de nível (Vitória) e Game Over com Revive. 
* [x] **5.5 Feedback Visual de Hint (UX)**: Implementação de Toast Message devidamente centralizada e com trava anti-spam.
* [x] **5.6 Novo Power-up (Shuffle) & Refatoração da HUD**: Implementação do 3º botão de poder (Shuffle) com animação em onda diagonal (0.5s). Ordem ajustada na UI e texturas unificadas.
* [x] **5.7 Sistema Avançado de Score e Combos (HUD)**: Matemática de Score com teto (Base 250, sobe +35, máx 600). Sistema de Tiers (1 a 6) com evolução baseada em ciclos de 5 combos. Regra de Perdão Inteligente e Punição Late-Game. Adição de texto animado "Combo X" e "Fever Mode" visual.
* [x] **5.8 Readequação da Interface (Contadores de Power-ups)**: Reposicionamento dos números (labels) de usos restantes para o padrão "Notification Badge" usando âncoras da Godot, e aumento ergonômico da área de toque dos botões.
* [x] **5.9 Polimento Sistêmico e UX (Quality of Life)**: Safe Area reajustada (Fonte 30, Offset 70). Auditoria de Combos (Power-ups não quebram combo). Shuffle cancela Dicas ativas. Adicionada Toast Message ("Sem peças válidas") ao Undo.
* [x] **5.10 Remoção do Estado "Acinzentado" & Shake Visual**: Tabuleiro 100% colorido. Feedback visual de erro com animação de tremor (Shake no eixo X) ao clicar numa peça bloqueada. Hitbox expandida (+10px padding) para precisão no toque mobile (Regra do Dedo Gordo).
* [x] **5.11 Auto-Framing (Zoom Dinâmico)**: Ajuste automático do tamanho das peças/câmera baseado no layout gerado proceduralmente, com travas matemáticas (`MAX_TILE_SCALE` e `MIN_TILE_SCALE`) para garantir proporções perfeitas na tela.
* [x] **5.12 Sistema de Revive F2P (Bypass Preparatório)**: Implementada a lógica de Revive com 2 usos gratuitos. A opção de Ads atua com bypass direto (sem popup genérica) revivendo a peça imediatamente, mantendo a arquitetura pronta para a injeção do SDK de anúncios reais.

### 🔄 Fase 6: Áudio, Performance Mobile e Correções Críticas (Em Andamento)
* [x] **6.1 - 6.5**: Gerenciador de Áudio, SFX do Tabuleiro, Juicy Buttons e SFX de Interface.
* [x] **6.6 Sincronia de Áudio e Impacto Visual**: Animação de choque físico sincronizada com o som de pedras.
* [x] **6.7 SFX de Progressão**: Gatilhos sonoros para Tiers de Combo (ciclos de 5) e Fever Mode.
* [x] **6.8 Blindagem de CPU e Performance (S25)**: Object Pooling, Caching de Bloqueio e Reset de Estado concluídos.
* [x] **6.8.1 Hotfix de Alinhamento (Undo/Revive)**: Correção de coordenadas pós-zoom.
* [x] **6.10 Sistema de Atmosfera Zen (Estrutura Inicial)**: Playlists ambientes (Floresta, Casa, Chuva).
* [x] **6.11 Cleanup de Áudio Legado**: Remoção completa do sistema de BGM Lo-fi e arquivos redundantes.
* [x] **6.13 Atmosfera Zen Contínua (Seamless)**: Remover `Timer` de silêncio e implementar loop ininterrupto de sons ambientes com transições suaves (crossfade) para maior imersão.
* [x] **6.17 Otimização Extrema de GPU (POCO X3 e Mid-ranges) [PIVOT MEGA BAKE]**:
    * [x] **Pivô de Arquitetura**: Abandono da montagem dinâmica de peças (Sombra + Base + Gato).
    * [x] **Arquitetura "Mega Bake"**: Transição para assets únicos (Peça achatada em PNG único contendo Sombra + Base + Gato) visando reduzir o processamento de transparências (Overdraw) em até 75%.
    * [x] **Calibragem de Grade**: Ajuste das constantes `TILE_W/H` no `BoardManager` para garantir o "Beijo de Pixel" com a nova arte.
    * [x] **Sincronia de Render**: Adição de `await process_frame` para evitar flashes de tabuleiro vazio.
* [ ] **6.12 Vacina do Match & Vitória Física (Prioridade 0)** — **[Gemini 3.1 Pro (High)]**: Resolução de condição de corrida (Race Condition) que prende peças no slot ao usar botões 'reiniciar' (Pausa/Game Over) e correção do tabuleiro vazio sem vitória.
* [ ] **6.14 Revisão de Áudio (Alteração de fim de jogo e derrota)** — **[Gemini 3 Flash]**: Trocar miados de Vitória/Derrota por efeitos satisfatórios e leves, integrados à atmosfera zen.
* [ ] **6.15 Fever Mode Dinâmico (Áudio e Efeitos)** — **[Gemini 3 Flash]**: Escalonar impacto sonoro e visual baseado no Tier atingido.
* [ ] **6.16 Novos Sons Zen (Vitória/Derrota)** — **[Gemini 3 Flash]**: Substituição direta de áudios de fim de jogo.

### 🏗️ Fase R: Refatoração e Desacoplamento Arquitetural (Estratégico)
* [ ] **R.1 Extração de Responsabilidades** — **[Claude Sonnet 4.6 (Thinking)]**: Mover Score, Inventário e Ads para Singletons/Nodes independentes.
* [ ] **R.2 Finite State Machine (FSM)** — **[Claude Opus 4.6 (Thinking)]**: Controle rígido de estados (IDLE, PIECE_FLYING, MATCH_ANIM, PAUSED).
* [ ] **R.3 Barramento de Sinais** — **[Gemini 3.1 Pro (High)]**: Substituição de caminhos diretos (`get_node`) por sinais.

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)**: Área de galeria para desbloqueio de gatos.
* [ ] **7.2 Progressão Temática**: Introdução de raças e novos temas visuais.
* [ ] **7.3 Expansão do Catálogo de Formatos**: Novos layouts (Fases Respiro vs. Fases Boss).
* [ ] **7.4 Recursos Visuais Finais**: Splash Screens, Logos e Assets definitivos.
* [ ] **7.5 UI e Menus**: Menu de Título, Loading e retrabalho final dos popups.
* [ ] **7.6 Onboarding (Tutorial)**: Mini-tabuleiro interativo de ensino.
* [ ] **7.7 Funcionalidades Online**: Placares globais e amigos.
* [ ] **7.8 Sistema de Recompensas por Marcos**: Conceder cargas permanentes de poderes.
* [ ] **7.9 Persistência de Sessão**: Cloud Save e Local State.
* [ ] **7.11 Feedback Tátil (Haptic Feedback)**: Vibrações sincronizadas.
* [ ] **7.12 Modos de Jogo Alternativos**: Gatos Dourados, Time Attack, Modo Memória.
* [ ] **7.13 Recompensas e Vitórias Diárias**: Sistema de login diário.
* [ ] **7.14 Sistema de Moeda In-Game**: "Soft Currency" para a Galeria.
* [ ] **7.15 Polimento Visual (Fever Mode)**: Partículas e efeitos de alto nível.
* [ ] **7.16 Integração do SDK de Monetização**: Plugins reais (AdMob/AppLovin).
* [ ] **7.17 Modelo de Monetização Premium**: Versão paga sem anúncios.
* [ ] **7.18 Polimento de Sombras e GPU**: Estudo de sombras premium (Foco Térmico).
* [ ] **7.19 Lembrete de Inatividade**: Feedback visual e sonoro para jogadores parados.
* [ ] **7.20 Poder de Match Automático via Ads**: Botão flutuante pós-inatividade.
* [ ] **7.21 Smart Hint V3 (Segurança e Camadas)**: Algoritmo profundo que evita Game Over e analisa obstruções espaciais 3D nas camadas inferiores.
* [ ] **7.22 Recompensa de "Caminho Perfeito"**: Feedback para jogadas que seguem a rota original do algoritmo reverso.

---

## 🚨 2. Problemas Conhecidos e Prioridades Críticas
* **P0 - Match Zumbi (Race Condition)**: Peças idênticas no slot não resolvem após reiniciar o nível via menu (Foco 6.12).
* **P0 - Vitória Fantasma**: Nível não termina com tabuleiro limpo (Foco 6.12).
* **P1 - Alinhamento Z**: Ajuste fino de `Z_OFFSET_X/Y` pendente (Status: Estável).

---

## 🛠️ 3. Especificações Técnicas: Sistema de Atmosfera (V84.4)

| Mundo | Faixa de Níveis | Tema Atmosférico | Arquivos (res://assets/audio/bgm/) |
| :--- | :--- | :--- | :--- |
| **0** | 1-10, 31-40... | Floresta (Forest) | `bgs_forest_1` a `4` |
| **1** | 11-20, 41-50... | Casa Zen (House) | `bgs_house_1` e `2` |
| **2** | 21-30, 51-60... | Jardim de Chuva (Rain) | `bgs_rain_1` e `2` |

---

## 📱 4. Status de Hardware (POCO X3 NFC / S25 Benchmark)
* **Performance**: 60 FPS Estável (GPU Otimizada via Mega Bake).
* **Eficiência Térmica**: Melhorada (Fim da montagem dinâmica de camadas).
* **Proporção**: Portrait-First (Otimizado para Pillar de 6 colunas).

---

## 🧠 5. Configuração de Modelos (Antigravity)
* **Gemini 3 Flash**: Tweaks visuais, UI simples, Áudio e Haptics.
* **Gemini 3.1 Pro (High)**: Mecânicas Core, Race Conditions (P0) e SDKs.
* **Claude Sonnet/Opus 4.6**: Refatorações sistêmicas (Fase R) e Algoritmos Matemáticos.