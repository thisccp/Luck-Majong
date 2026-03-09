# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 66.0  
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
* [x] **5.1 Gerador Determinístico de Formatos**: Algoritmo com "Seed".
* [x] **5.2 Curva de Dificuldade Controlada**: Dificuldade infinita por "Mundos" (curva senoidal via `world_index`), injeção de pares extras e correção de oclusão no eixo Y (2.5D).
* [x] **5.5 Feedback Visual de Hint (UX)**: Toast Messages.
* [x] **5.6 Novo Power-up (Shuffle)**: Botão de embaralhar com onda diagonal (0.5s). Ordem ajustada na UI e texturas unificadas.
* [ ] **5.7 Sistema de Pontuação e Combos (HUD)**: Lógica de pontuação em tempo real. Cada par gera uma pontuação base. *Matches* rápidos em sequência ativam uma barra de tempo e um multiplicador de Combo. Inclusão do contador de Score (Label) no topo da tela do *gameplay*.
* [ ] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação com Desfoque (Blur), mensagem temática e transição visual.
* [ ] **5.4 Fluxo de Vitória/Derrota**: Telas de conclusão, cálculo final de estrelas/pontuação e transição para o próximo nível.

### 🎵 Fase 6: Áudio e Sonoplastia (Sound Design)
* [ ] **6.1 Gerenciador de Áudio (Audio Manager)**: Singleton para canais paralelos.
* [ ] **6.2 Efeitos Sonoros do Tabuleiro (SFX)**: Cliques, erros e voo de peças.
* [ ] **6.3 Efeitos Sonoros de Interface (UI SFX)**: Botões, alertas e popups.
* [ ] **6.4 Música de Fundo (BGM)**: 3 faixas Lo-fi *Samurai Champloo* (~3 min loop). Versão especial com miados suaves na batida. Opções de controle de volume (Mudo/Ativo) no menu de pausa.
* [ ] **6.5 Sincronia de Áudio e Animação**: Som de *match* no frame exato da colisão.
* [ ] **6.6 Locução de Feedback (Announcer)**: Implementação de vozes de incentivo ("Good!", "Nice!", "Perfect!", "Awesome!") disparadas ao atingir marcos específicos do sistema de Combos (Fase 5.7).

### ⏳ Fase 7: Backlog, Retenção e UX (Futuro)
* [ ] **7.1 Meta-Jogo**: Galeria de coleção de gatos.
* [ ] **7.2 Progressão Temática**: Troca de fundo/raça a cada 10 níveis com nova peça permanente.
* [ ] **7.3 Expansão de Formatos**: "Fases de respiro" com designs divertidos.
* [ ] **7.4 Recursos Visuais Finais**: Assets definitivos e Splash Screen.
* [ ] **7.5 UI e Menus**: Menu Principal, Loading e Pausa (com número do nível).
* [ ] **7.6 Onboarding**: Tutorial interativo.
* [ ] **7.7 Funcionalidades Online**: Placares globais.
* [ ] **7.8 Recompensas por Marcos**: Baús de poderes a cada X níveis.
* [ ] **7.9 Revive F2P com Ads**: Conversão do botão Reviver para Ad após 2 usos.
* [ ] **7.10 Auto-Framing**: Zoom dinâmico no layout.
* [ ] **7.11 Save/Load**: Persistência de sessão.
* [ ] **7.12 Nova Animação de Match**: Colisão física entre os 2 gatos no slot.
* [ ] **7.13 Feedback Tátil (Vibração)**: Níveis sutil, médio e impacto de match.
* [ ] **7.14 Modificadores de Regra**: Peças viradas para baixo (Gatos Dorminhocos).
* [ ] **7.15 Modos Alternativos**: Gatos Dourados e Time Attack.

---

## 🚨 2. Problemas Conhecidos (Lista de Bugs Ativos)
* **Bug do Hint (Spam de Mensagem):** Múltiplos cliques no botão Hint (quando não há jogadas) disparam várias Toast Messages sobrepostas. Necessita trava (cooldown).

---

## 🛠️ 3. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones.
* **Flow de Dificuldade**: Curva infinita por Mundos (Match-2 Perfeito).
* **Economia F2P Híbrida**: Monetização baseada em pontos de estrangulamento nos níveis altos.