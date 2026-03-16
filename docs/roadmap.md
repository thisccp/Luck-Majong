# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 83.0  
**Última Atualização:** 16/03/2026

---

## 📈 1. Roadmap Integral de Desenvolvimento

### ✅ Fase 1: Fundação e Estrutura Básica (Concluído)
* [x] **Setup da Engine**: Configuração do ambiente Godot para mobile.
* [x] **Arquitetura de Classes**: Estrutura `BoardManager` e `MahjongTile`.
* [x] **Atlas de Texturas**: Lógica de carregamento e gestão do `image_0.png`.
* [x] **Layout Turtle**: Implementação inicial da estrutura clássica.

### ✅ Fase 2: Mecânicas e Regras de Jogo (Concluído)
* [x] **Regra 55/45 (Antiga 90/10)**: Lógica de bloqueio vertical recalibrada para offsets agressivos.
* [x] **Geração Reversa**: Algoritmo para tabuleiros 100% solucionáveis.
* [x] **Sistema de Inventário**: Implementação dos 4 slots de armazenamento.
* [x] **Bloqueio Lateral**: Validação de peças livres através das bordas.

### ✅ Fase 3: Renderização e Imersão (Concluído)
* [x] **3.1 - 3.4**: Sincronização via `await`, Escala Dinâmica e Maximização de Sprites.
* [x] **3.5 Neko Block (Verticalização)**: Transição para layout Portrait (Pillar de 6 colunas).
* [x] **3.6 Ajuste de Contato**: Encaixe "Beijo de Pixel", sobreposição tátil (Z+1) e correção do Drop Shadow.

### ✅ Fase 4: Sistemas de Apoio e Economia (Concluído)
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar slots e trava anti-spam.
* [x] **4.2 Reverse (Undo)**: Retorno ao grid com animação de voo e Z-index dinâmico.
* [x] **4.3 Drag & Peek (Arrasto Livre)**: Mecânica tátil com retorno elástico.
* [x] **4.4 UI de Cargas e Ads**: Labels numéricos e popup de recarga (+2 usos).

### ✅ Pré-Fase 5: Refatoração e Otimização Arquitetural (Concluído)
* [x] **Separação de Responsabilidades**: Interface de Ads/Popups em cenas independentes (`.tscn`).

### ✅ Fase 5: Progressão Procedural e Flow (Concluído)
* [x] **5.1 a 5.3**: Gerador Determinístico, Curva Senoidal e Intro Cinematográfica.
* [x] **5.4 a 5.12**: Sistema de Score/Combos, Auto-Framing e Sistema de Revive F2P.

### 🎵 Fase 6: Áudio e Performance Mobile - [EM ANDAMENTO]
* [x] **6.1 - 6.5**: Audio Manager, SFX de Tabuleiro, Juicy Buttons e BGM Lo-fi.
* [x] **6.8 Blindagem de CPU (S25)**: Object Pooling e Caching de Bloqueio (Redução p/ 5min CPU).
* [ ] **6.9 Otimização de GPU e Térmica**: Static Shader Sharing e Overdraw Reduction. — **[Claude Sonnet 4.6 (Thinking)]**
* [ ] **6.6 Sincronia de Áudio e Animação**: Som de *match* no frame exato de colisão. — **[Gemini 3.1 Pro (High)]**
* [ ] **6.7 Locução de Feedback (Announcer)**: Vozes de incentivo para Combos/Fever. — **[Gemini 3 Flash]**

### 🏗️ Fase R: Refatoração e Desacoplamento Arquitetural (Estratégico)
* [ ] **R.1 Extração de Responsabilidades**: Mover Score, Inventário e Ads para Singletons. — **[Claude Opus 4.6 (Thinking)]**
* [ ] **R.2 Finite State Machine (FSM)**: Controle rígido de estados de jogo. — **[Claude Sonnet 4.6 (Thinking)]**
* [ ] **R.3 Barramento de Sinais**: Substituição de `get_node` por sinal modular. — **[Gemini 3.1 Pro (High)]**

### ⏳ Fase 7: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **7.1 Meta-Jogo (Sistema de Coleção)**: Galeria de gatinhos colecionáveis. — **[GPT-OSS 120B (Medium)]**
* [ ] **7.2 Progressão Temática**: Mudança visual de peças por Mundos. — **[GPT-OSS 120B (Medium)]**
* [ ] **7.3 Expansão de Formatos**: Novos layouts (Respiro vs. Boss). — **[GPT-OSS 120B (Medium)]**
* [ ] **7.4 Recursos Visuais Finais**: Assets definitivos, Splash e Logos. — **[Gemini 3 Flash]**
* [ ] **7.5 UI e Menus (Refatoração)**: Menu de Título e Novo Fluxo de Vitória. — **[Gemini 3.1 Pro (Low)]**
* [ ] **7.6 Onboarding (Tutorial)**: Mini-tabuleiro interativo de ensino. — **[Claude Sonnet 4.6 (Thinking)]**
* [ ] **7.7 Funcionalidades Online**: Placares globais/amigos. — **[Gemini 3.1 Pro (High)]**
* [ ] **7.8 Recompensas por Marcos**: Baú de Fim de Mundo (Poderes Permanentes). — **[Gemini 3.1 Pro (High)]**
* [ ] **7.9 Persistência de Sessão**: Cloud Save e Local State. — **[Gemini 3.1 Pro (High)]**
* [ ] **7.10 Nova Animação de Match**: Refatoração visual de destruição 3D. — **[Claude Sonnet 4.6 (Thinking)]**
* [ ] **7.11 Feedback Tátil (Haptic)**: Vibrações sincronizadas. — **[Gemini 3 Flash]**
* [ ] **7.12 Modos de Jogo Alternativos**: Time Attack e Modo Memória. — **[GPT-OSS 120B (Medium)]**
* [ ] **7.13 Recompensas Diárias**: Sistema de Login Progressivo. — **[GPT-OSS 120B (Medium)]**
* [ ] **7.14 Sistema de Moeda In-Game**: Soft Currency para Galeria. — **[Gemini 3.1 Pro (Low)]**
* [ ] **7.15 Polimento Fever Mode**: Partículas e efeitos visuais extras. — **[Claude Sonnet 4.6 (Thinking)]**
* [ ] **7.16 Integração SDK Monetização**: Injeção de AdMob/AppLovin real. — **[Claude Opus 4.6 (Thinking)]**
* [ ] **7.17 Modelo de Monetização Premium**: Versão paga p/ remoção de ads. — **[Gemini 3.1 Pro (Low)]**
* [ ] **7.18 Polimento de Sombras Final**: Sombras premium sem custo de GPU. — **[Claude Sonnet 4.6 (Thinking)]**

---

## 🚨 2. Problemas Conhecidos
* **Aquecimento Térmico (GPU)**: O jogo apresenta aquecimento leve após 20min devido ao processamento de sombras (Shader Blur). Requer otimização na Fase 6.9 com Claude.

---
## 🛠️ 3. Especificações Técnicas Atuais
* **Portrait-First**: Design otimizado para smartphones (Pillar de 6 colunas).
* **CPU Status**: Otimizada (5min CPU / 20min Tela).
* **Bateria Status**: Estável (1,5% / 20min Tela).
* **FPS**: Travado em 60Hz para estabilidade térmica.
* **Monetização**: Sustentada por Ads (Vídeo Premiado).