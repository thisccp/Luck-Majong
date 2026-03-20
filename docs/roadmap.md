# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 84.5
**Última Atualização:** 20/03/2026
**Status Atual:** Vacina do Match & Vitória Física CONCLUÍDA (Arquitetura Mega Bake)

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
* [x] **6.13 Atmosfera Zen Contínua (Seamless)** — **[Gemini 3 Flash]**: Remover `Timer` de silêncio e implementar loop ininterrupto de sons ambientes com transições suaves (crossfade) para maior imersão.
* [x] **6.17 Otimização Extrema de GPU (POCO X3 e Mid-ranges) [PIVOT MEGA BAKE]** — **[Gemini 3.1 Pro (High)]**:
    * [x] **Pivô de Arquitetura**: Abandono da montagem dinâmica de peças. Transição completa para a Arquitetura "Mega Bake" (1 Peça = 1 Imagem única contendo Sombra + Base + Gato achatados no Photoshop) reduzindo Overdraw em 75%.
    * [x] **Downscale de Assets**: Redução drástica da resolução das peças para aliviar banda de GPU e VRAM.
    * [x] **Sincronia de Render**: Adição de `await process_frame` no GameManager para evitar flashes de tabuleiro vazio na intro.
    * [x] **Calibragem Visual**: Ajuste de `TILE_W/H` para garantir o "Beijo de Pixel" com a nova arte.
    * [x] **Blindagem de UI**: Uso de Z-Index/CanvasLayer no Menu de Pausa para cobrir peças nos slots.
* [x] **6.18 Calibragem de Proporção (Peças "Gordinhas")** — **[Gemini 3 Flash]**: Concluído. Proporção final ajustada para 108x130 (Aspect Ratio ~1.2) com CELL_H em 58.0, restaurando a silhueta premium das peças Mega Bake.
* [x] **6.12 Vacina do Match & Vitória Física (Prioridade 0)** — **[Gemini 3.1 Pro (High)]**: Concluído. Resolvido o bug crítico de "Match Zumbi" e "Vitória Fantasma" que ocorria ao reiniciar a partida. A causa raiz era uma ilusão de ótica gerada pelo Object Pooling (Fase 6.8), onde as peças recicladas não atualizavam suas texturas nativas. Corrigido com a chamada de `update_sticker()` no setup do `Tile.gd`, garantindo sincronia perfeita entre lógica e renderização.Implementar checagem rigorosa de instâncias físicas e casting seguro de IDs.
* [ ] **6.14 Revisão de Áudio (Limpeza de Fim de Jogo)** — **[Gemini 3 Flash]**: Remoção completa dos efeitos sonoros felinos (miados) disparados ao abrir as telas de Vitória e Game Over, garantindo que o fim da partida seja limpo e não conflite com a futura trilha de conclusão.
* [ ] **6.15 Sistema de Áudio Zen Procedural e Barramentos (Buses)** — **[Gemini 3.1 Pro High]**: *Substitui e atualiza as antigas etapas de background e efeitos felinos.* Implementação de áudio dinâmico e otimizado utilizando Audio Buses nativos do Godot 4.6 (`Ambient`, `Cats`, `SFX`). Inclui gerador procedural de miados/ronronados aleatórios (.wav leves) sobrepostos a faixas contínuas de fundo (.ogg), permitindo que o jogador silencie cada camada de forma independente.
* [ ] **6.16 Fever Mode Dinâmico (Áudio e Efeitos)** — **[Gemini 3 Flash]**: Escalonar complexidade sonora e impacto visual do Fever Mode baseado progressivamente no Tier atingido.
* [x] **6.19 Refatoração da Perspectiva Isométrica (Estilo Bloco Sólido)** — **[Gemini 3.1 Pro (High)]**: *Substitui a antiga auditoria de oclusão.* Redesenho da geometria da grade (`CELL` e `Z_OFFSET` no BoardManager) para imitar a perspectiva de blocos sólidos empilhados (referência: Vita Mahjong), eliminando a ilusão de sobreposição na mesma camada. Inclui a recalibragem do `Auto-Framing` para suportar o novo tamanho físico do tabuleiro e a atualização definitiva da regra de oclusão vertical e lateral baseada na nova grade.
* [ ] **6.20 Homologação Multi-Device (Aspect Ratios)** — **[Engenheiro de QA]**: Bateria de testes de responsividade simulando 3 perfis extremos de tela no Godot (Ultrawide 20:9, Padrão 16:9 e Tablet 4:3). Validação do comportamento das âncoras da HUD e da escala matemática do `Auto-Framing` do BoardManager para garantir experiência idêntica em qualquer aparelho geométrico.
* [ ] **6.21 Polimento Visual dos Sprites (Sombra Global / Oclusão)** — **[Manual / Photoshop]**: *Adição de uma sombra suave e uniforme contornando 100% da borda do bloco (estilo Vita Mahjong).*
    * **Objetivo:** Dar "peso" físico às peças e resolver a ambiguidade visual de profundidade (Z-Index).
    * **Mecânica Visual:** Peças na mesma camada que se encostam terão suas sombras sobrepostas/mescladas, reforçando a ideia de "bloco contínuo e plano". Peças em camadas superiores projetarão essa sombra diretamente sobre a face clara das peças abaixo, criando um contraste imediato que o olho humano reconhece como diferença de altura.
    * **Ação:** Editar o PNG base da peça no Photoshop, exportar e substituir na engine (não requer alteração de código, apenas calibração caso o tamanho total do PNG mude).

### 🏗️ Fase R: Refatoração e Desacoplamento Arquitetural (Estratégico)
* [ ] **R.1 Extração de Responsabilidades** — **[Claude Sonnet 4.6 (Thinking)]**: Mover Score, Inventário e Ads para Singletons/Nodes independentes.
* [ ] **R.2 Finite State Machine (FSM)** — **[Claude Opus 4.6 (Thinking)]**: Controle rígido de estados (IDLE, PIECE_FLYING, MATCH_ANIM, PAUSED).
* [ ] **R.3 Barramento de Sinais** — **[Gemini 3.1 Pro (High)]**: Substituição de caminhos diretos (`get_node`) por sinais para UI modular.

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)** — **[Gemini 3.1 Pro (High)]**: Área de galeria onde o jogador desbloqueia novos tipos de gatos.
* [ ] **7.2 Progressão Temática e Expansão de Peças** — **[Gemini 3 Flash]**: Mudança de tema visual e introdução de novas peças baseadas em raças de gatos.
* [ ] **7.3 Refatoração e Expansão do Level Design (Estilo Isométrico Realista)** — **[Gemini 3.1 Pro (High)]**: *Revisão total das matrizes de geração de fases para alinhar com a nova física de Bloco Sólido (Estilo Vita Mahjong) e expandir o catálogo de diversão.*
    * **Regra de Ouro Geométrica (Anti-Sobreposição):** Eliminar o uso de passos ímpares (`y+1` ou `x+1`) na MESMA camada (Z). Peças no mesmo andar devem usar espaçamento par (`y+2`, `x+2`) para garantir que sejam lidas visualmente como uma base perfeitamente plana e coesa, sem "fundir" ou esmagar umas às outras.
    * **Física de Empilhamento Rígida:** Peças em camadas superiores (Z+1, Z+2) devem ser posicionadas com ancoragem realista. Não haverá peças "flutuando" ou empilhadas de forma instável. O empilhamento deve respeitar a gravidade estrutural (apoiadas perfeitamente no centro de 1 bloco, ou dividindo o peso simetricamente sobre 2 ou 4 blocos da base).
    * **Tentativa de mudança específica na regra 25% de sobreposição:**  As peças nao devem "somar" a sobreposição na regra dos 25% de sobreposição, se nenhuma peça cobre 25% a peça esta liberada. testar, se ficar bom mantemos, se ficar ruim ou estranho, abandonamos a ideia.
    * **Diferencial Competitivo (Fases Temáticas):** Criação de layouts divertidos e visuais (ex: formas de animais, objetos, símbolos). O jogador deve olhar para a mesa e reconhecer "Opa, isso é um avião!" ou "Isso é um coração!", quebrando a monotonia dos blocos quadrados tradicionais, focar também na ''diversão'' no sentido de desempilhamento linear, imagine um layout redondo com camadas onde a solução para desempilhar o tabuleiro force o jogador a ir desempilhando no formato redondo (girando) forçando o jogador a ir encontrando peças par desempilhar indo em direção de cículo até terminar cada camada e vencer a partida.
    * **Curva de Pacing (Respiro vs. Boss):** * *Fases Respiro:* Layouts mais espalhados, planos (poucas camadas Z) e com alta taxa de peças expostas, focados em relaxamento e fluxo rápido.
        * *Fases Boss:* Layouts densos, com estruturas verticais altas (Z=4 ou Z=5), exigindo escavação estratégica e memória, testando o limite da engine de oclusão.
* [ ] **7.4 Recursos Visuais Finais** — **[Gemini 3 Flash]**: Assets definitivos, Splash Screens e Logos.
* [ ] **7.5 UI e Menus** — **[Gemini 3.1 Pro (Low)]**: Menu de Título, Sistema de Loading e retrabalho final dos popups.
* [ ] **7.6 Onboarding e Tutorial Dinâmico** — **[Gemini 3.1 Pro (High)]**: Mini-tabuleiro interativo pré-nível 1 ensinando bloqueio lateral e regra 55/45. No Nível 1: Poderes Undo e Hint gratuitos (Shuffle travado). Exibir aviso de segurança ("Cuidado para não encher os espaços") na primeira vez que o jogador acumular 3 peças sem match no slot.
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
* [ ] **7.18 Polimento de Sombras e GPU** — **[Gemini 3 Flash]**: Estudo de sombras premium sem custo excessivo de GPU (Foco Térmico pós Mega-Bake).
* [ ] **7.19 Lembrete de Inatividade (Idle Reminder)** — **[Gemini 3.1 Pro (Low)]**: Acionar som indicativo e efeito visual (piscar) nos botões de Hint e Shuffle se o jogador ficar inativo.
* [ ] **7.20 Poder de Match Automático via Ads** — **[Gemini 3.1 Pro (High)]**: Botão flutuante pós-inatividade para match automático.
* [ ] **7.21 Smart Hint V3 (Segurança e Camadas)** — **[Claude Opus 4.6 (Thinking)]**: Evitar Game Over garantindo que a dica de tabuleiro só aconteça se houver `vagas >= 2`. Adicionar verificação algorítmica profunda para sugerir remoção de peças obstruindo pares na camada inferior (resolução espacial 3D).
* [ ] **7.22 Desbloqueio Progressivo de Power-ups** — **[Gemini 3.1 Pro (Low)]**: Travar o uso do Shuffle no início do jogo e liberá-lo na HUD apenas após o Nível 10, criando sensação de progressão e evitando sobrecarga cognitiva no jogador iniciante.
* [ ] **7.23 Perspectiva 3D Dinâmica (Offsets Variáveis) (SOMENTE SE FOR COMPATÍVEL COM A ALTERAÇÃO ROBUSTA DE LAYOUTS QUE VAMOS FAZER NA 7.3)** — **[Gemini 3.1 Pro (High)]**: Refatorar `Z_OFFSET_X` e `Z_OFFSET_Y` no `BoardManager` de `const` para `var`. Permitir que a geração procedural crie layouts com ângulos de câmera variados (ex: torres vistas mais de cima ou mais de lado).
* [ ] **7.24 Polimento de Game Feel (Tempos de Animação)** — **[Gemini 3 Flash]** *(Prioridade Baixa)*: Ajuste fino nas curvas e durações dos `Tweens`. Reduzir o tempo de voo das peças para a barra de inventário (garantindo que o input não fique travado) e acelerar a animação de fusão/match (afastamento, batida e sumiço) para deixar a jogabilidade mais ágil, "snappy" e recompensadora para jogadores rápidos.

* [ ] **B.1 Monitor de Performance HUD (Contingência)** — **[Engenheiro de QA]**: Criação de um script "Raio-X" descartável (`DebugMonitor.gd`) para ser instanciado no CanvasLayer superior. Deve exibir FPS atual e consumo de Memória RAM na tela do aparelho físico, caso sejam reportados gargalos de lentidão ou aquecimento durante as fases finais de teste.

---

## 🚨 2. Problemas Conhecidos e Prioridades Críticas

---

## 🛠️ 3. Especificações Técnicas: Sistema de Atmosfera (V84.4)

| Mundo | Faixa de Níveis | Tema Atmosférico | Arquivos (res://assets/audio/bgm/) |
| :--- | :--- | :--- | :--- |
| **0** | 1-10, 31-40... | Floresta (Forest) | `bgs_forest_1` a `4` |
| **1** | 11-20, 41-50... | Casa Zen (House) | `bgs_house_1` |
| **2** | 21-30, 51-60... | Jardim de Chuva (Rain) | `bgs_rain_1` e `2` |

* **Lógica de Playlist**: Shuffle inteligente dentro do tema do mundo. (PENDENTE)
* **Persistência**: O áudio não reinicia ao carregar novos níveis do mesmo mundo.
* **Contínuo e Sem Fim**: Trilhas sonoras encadeadas em loop infinito, sem espaços de silêncio (crossfade suave ja existe nas faixas).

---

## 📱 4. Status de Hardware (Benchmark)
* **Portrait-First**: Design otimizado para smartphones (Pillar de 6 colunas).
* **CPU Status**: Otimizada (5min CPU / 20min Tela).
* **Bateria Status**: Estável (1,5% / 20min Tela).
* **FPS**: Travado em 60Hz para controle de estabilidade térmica testes: Galaxy S25.
* **Monetização**: Sustentada por Ads (Emulação de Sucesso).
* **FPS**: 60Hz Estável (Status: Concluído via Mega Bake) testes: POCO X3 NFC.

---

## 🧠 5. Modelos Disponíveis no Antigravity (Guia de Eficiência)
Para economia de cota e precisão arquitetural, a execução de prompts deve sempre obedecer ao balanceamento abaixo:
* **Gemini 3 Flash**: *Eficiência e Velocidade.* Ideal para substituições pontuais, lógica de UI simples, configuração de áudio, tweaks visuais e Haptic Feedback.
* **Gemini 3.1 Pro (Low)**: *Interfaces e Lógica Leve.* Bom para lidar com estruturação de menus e eventos simples (ex: Idle Reminder).
* **Gemini 3.1 Pro (High)**: *Resolução de Conflitos e Sistemas Base.* Otimizado para manipular mecânicas core, corrigir race conditions severas, implementar SDKs ou gerenciar APIs locais.
* **Claude Sonnet 4.6 (Thinking)**: *Arquitetura Profunda.* Reservado estritamente para grandes refatorações sistêmicas (Fase R), Máquina de Estados (FSM) e integrações complexas.