# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 84.3
**Última Atualização:** 17/03/2026
**Status Atual:** Estabilização Crítica (Pré-Refatoração) e Pivot de Renderização

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
* [x] **4.4 UI de Cargas e Ads**: Remoção de bloqueio visual, adição de labels numéricos e popup genérico de recarga (+2 usos) individual por poder.

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
* [x] **6.9 Otimização de GPU e Térmica**: Movida para o final do projeto (Fase 7.18).
* [x] **6.10 Sistema de Atmosfera Zen (Estrutura Inicial)**: Playlists ambientes (Floresta, Casa, Chuva).
* [x] **6.11 Cleanup de Áudio Legado**: Remoção completa do sistema de BGM Lo-fi e arquivos redundantes.
* [ ] **6.12 Vacina do Match & Vitória Física (Prioridade 0)** — **[Gemini 3.1 Pro (High)]**: Resolução de condição de corrida (Race Condition) que prende peças no slot (na verdade parece ocorrer ao usar os botões 'reiniciar' do menu de pausa e reiniciar do menu de game over, quando estes botões são utilizados as peças param de dar match) e correção do bug de tabuleiro vazio sem tela de vitória. Implementar checagem rigorosa de instâncias físicas e casting seguro de IDs.
* [x] **6.13 Atmosfera Zen Contínua (Seamless)** — **[Gemini 3 Flash]**: Remover `Timer` de silêncio e implementar loop ininterrupto de sons ambientes com transições suaves (crossfade) para maior imersão.
* [ ] **6.14 Revisão de Áudio (Alteração de fim de jogo e derrota)** — **[Gemini 3 Flash]**: Alterar audios de miados e efeitos felinos nas telas de Vitória e Derrota por que agora o som zen de fundo tem esses efeitos, trocar por efeitos satisfatórios e leves.
* [ ] **6.15 Fever Mode Dinâmico (Áudio e Efeitos)** — **[Gemini 3 Flash]**: Escalonar complexidade sonora e impacto visual do Fever Mode baseado progressivamente no Tier atingido.
* [ ] **6.16 Novos Sons Zen (Vitória/Derrota)** — **[Gemini 3 Flash]**: Substituição direta dos sons de fim de jogo para manter a atmosfera imersiva.
* [ ] **6.17 Otimização Extrema de GPU (POCO X3 e Mid-ranges) [PIVOT DE ARQUITETURA]** — **[Gemini 3.1 Pro (High)]**: *Em andamento.* Fase dividida em duas etapas:
    * **Etapa 1 (Concluída):** Código limpo, Z-Index matemático unificado e Draw Calls reduzidos a 15 no PC.
    * **Etapa 2 (Atual):** Resolução do gargalo de *Overdraw* e *Fill Rate* em GPUs mobile intermediárias. Abandono da montagem dinâmica de peças. Transição completa para a Arquitetura "Mega Bake" (1 Peça = 1 Imagem única contendo Sombra + Base + Gato achatados no Photoshop) visando reduzir os cálculos de transparência na tela em até 75%.

### 🏗️ Fase R: Refatoração e Desacoplamento Arquitetural (Estratégico)
* [ ] **R.1 Extração de Responsabilidades** — **[Claude Sonnet 4.6 (Thinking)]**: Mover Score, Inventário e Ads para Singletons/Nodes independentes.
* [ ] **R.2 Finite State Machine (FSM)** — **[Claude Opus 4.6 (Thinking)]**: Controle rígido de estados (IDLE, PIECE_FLYING, MATCH_ANIM, PAUSED).
* [ ] **R.3 Barramento de Sinais** — **[Gemini 3.1 Pro (High)]**: Substituição de caminhos diretos (`get_node`) por sinais para UI modular.

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)** — **[Gemini 3.1 Pro (High)]**: Área de galeria onde o jogador desbloqueia novos tipos de gatos.
* [ ] **7.2 Progressão Temática e Expansão de Peças** — **[Gemini 3 Flash]**: Mudança de tema visual e introdução de novas peças baseadas em raças de gatos.
* [ ] **7.3 Expansão do Catálogo de Formatos** — **[Gemini 3.1 Pro (High)]**: Criação de novos layouts (Fases Respiro vs. Fases Boss).
* [ ] **7.4 Recursos Visuais Finais** — **[Gemini 3 Flash]**: Assets definitivos, Splash Screens e Logos.
* [ ] **7.5 UI e Menus** — **[Gemini 3.1 Pro (Low)]**: Menu de Título, Sistema de Loading e retrabalho final dos popups.
* [ ] **7.6 Onboarding (Tutorial)** — **[Gemini 3.1 Pro (High)]**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **7.7 Funcionalidades Online** — **[Claude Sonnet 4.6 (Thinking)]**: Placares globais/amigos.
* [ ] **7.8 Sistema de Recompensas por Marcos** — **[Gemini 3.1 Pro (High)]**: Conceder cargas permanentes de poderes ao completar milestones.
* [ ] **7.9 Persistência de Sessão** — **[Gemini 3.1 Pro (High)]**: Cloud Save e Local State.
* [x] **7.10 Nova Animação de Match**: Integrada com sucesso na Fase 6.6.
* [ ] **7.11 Feedback Tátil (Haptic Feedback)** — **[Gemini 3 Flash]**: Vibrações sincronizadas (Android/iOS).
* [ ] **7.12 Modos de Jogo Alternativos** — **[Claude Sonnet 4.6 (Thinking)]**: Gatos Dourados, Time Attack, Modo Memória.
* [ ] **7.13 Recompensas e Vitórias Diárias** — **[Gemini 3.1 Pro (High)]**: Sistema de login diário.
* [ ] **7.14 Sistema de Moeda In-Game** — **[Gemini 3.1 Pro (High)]**: "Soft Currency" para a Galeria.
* [ ] **7.15 Polimento Visual (Fever Mode)** — **[Gemini 3 Flash]**: Partículas no "Fever Mode" para níveis altos de combo.
* [ ] **7.16 Integração do SDK de Monetização** — **[Gemini 3.1 Pro (High)]**: Substituição do simulador pelo plugin real (AdMob/AppLovin).
* [ ] **7.17 Modelo de Monetização Premium** — **[Gemini 3.1 Pro (High)]**: Versão paga para remoção de anúncios.
* [ ] **7.18 Polimento de Sombras e GPU** — **[Gemini 3 Flash]**: Estudo de sombras premium sem custo excessivo de GPU (Foco Térmico).
* [ ] **7.19 Lembrete de Inatividade (Idle Reminder)** — **[Gemini 3.1 Pro (Low)]**: Acionar som indicativo e efeito visual (piscar) nos botões de Hint e Shuffle se o jogador ficar inativo por tempo determinado.
* [ ] **7.20 Poder de Match Automático via Ads** — **[Gemini 3.1 Pro (High)]**: Botão flutuante deslizante que aparece após inatividade com um timer. Exige visualizar anúncio e recompensa o jogador levando automaticamente 1 ou 2 pares disponíveis no tabuleiro para os slots.
* [ ] **7.21 Smart Hint V3 (Segurança e Camadas)** — **[Claude Opus 4.6 (Thinking)]**: Evitar Game Over garantindo que a dica de tabuleiro só aconteça se houver `vagas >= 2` ou `vagas >= 3`. Adicionar verificação algorítmica profunda para sugerir remoção de peças obstruindo pares na camada inferior (resolução espacial 3D) (desde que existam vagas suficientes). lembrando que a regra atual de hint deve ser mantida e melhorada (na ordem de prioridade, hint verifica primeiro se alguma peça nos slots caso haja alguma, da match do alguma do tabuleiro, depois se alguma peça dos slots caso haja alguma peça nos slots da match com a camada de baixo de acordo com as vagas nos slots, se não há peças nos slots ou não há matsh a serem feitos nas condições anteriores, aí ele começa verificar o tabuleiro, se tem jogadas disponiveis de acordo com as vagas de slots, primeiro visando a camada de cima e depois podendo considerar a próxima camada de baixo também).
* [ ] **7.22 Recompensa de "Caminho Perfeito" (BAIXA PRIORIDADE)** — **[Claude Opus 4.6 (Thinking)]**: Desenvolver algoritmo de comparação de grafos para dar feedback visual sazonal para jogadas que seguem exatamente a rota original de resolução gerada pelo algoritmo reverso.

---

## 🚨 2. Problemas Conhecidos e Prioridades Críticas
* **P0 - Match Zumbi (Race Condition)**: Em momentos aleatórios, peças idênticas entram no slot e não disparam a resolução do match, deixando o jogo em estado injogável (Foco do item 6.12).
* **P0 - Vitória Fantasma**: Tabuleiro limpo e inventário vazio, porém o nível não termina pois instâncias residuais seguram as condições de vitória (Foco do item 6.12).
* **Eficiência Térmica (GPU)**: Aquecimento leve persistente devido aos Shaders de Drop Shadow. (Adiado para Fase 7.18).

---

## 🛠️ 3. Especificações Técnicas: Sistema de Atmosfera (V84.3)

| Mundo | Faixa de Níveis | Tema Atmosférico | Arquivos (res://assets/audio/bgm/) |
| :--- | :--- | :--- | :--- |
| **0** | 1-10, 31-40... | Floresta (Forest) | `bgs_forest_1` a `4` |
| **1** | 11-20, 41-50... | Casa Zen (House) | `bgs_house_1` e `2` |
| **2** | 21-30, 51-60... | Jardim de Chuva (Rain) | `bgs_rain_1` e `2` |

* **Lógica de Playlist**: Shuffle inteligente dentro do tema do mundo.
* **Persistência**: O áudio não reinicia ao carregar novos níveis do mesmo mundo.
* **Contínuo e Sem Fim**: Trilhas sonoras encadeadas em loop infinito, sem espaços de silêncio (crossfade suave) para manter imersão imperturbável.

---

## 📱 4. Status de Hardware (S25 Benchmark)
* **Portrait-First**: Design otimizado para smartphones (Pillar de 6 colunas).
* **CPU Status**: Otimizada (5min CPU / 20min Tela).
* **Bateria Status**: Estável (1,5% / 20min Tela).
* **FPS**: Travado em 60Hz para controle de estabilidade térmica.
* **Monetização**: Sustentada por Ads (Emulação de Sucesso).

---

## 🧠 5. Modelos Disponíveis no Antigravity (Guia de Eficiência)
Para economia de cota e precisão arquitetural, a execução de prompts deve sempre obedecer ao balanceamento abaixo:
* **Gemini 3 Flash**: *Eficiência e Velocidade.* Ideal para substituições pontuais, lógica de UI simples, configuração de áudio, tweaks visuais e Haptic Feedback.
* **Gemini 3.1 Pro (Low)**: *Interfaces e Lógica Leve.* Bom para lidar com estruturação de menus e eventos simples (ex: Idle Reminder).
* **Gemini 3.1 Pro (High)**: *Resolução de Conflitos e Sistemas Base.* Otimizado para manipular mecânicas core, corrigir race conditions severas, implementar SDKs ou gerenciar APIs locais.
* **Claude Sonnet 4.6 (Thinking)**: *Arquitetura Profunda.* Reservado estritamente para grandes refatorações sistêmicas (Fase R), Máquina de Estados (FSM) e integrações complexas.
* **Claude Opus 4.6 (Thinking)**: *Força Bruta e Algoritmos Críticos.* O modelo mais robusto (e custoso) do arsenal. Uso estritamente restrito para problemas matemáticos altamente complexos, algoritmos de geração procedural intrincados ou refatorações estruturais que exijam uma capacidade massiva de raciocínio. Utilizar como "bala de prata" para preservação de cota.