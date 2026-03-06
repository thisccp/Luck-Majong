# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 55.0  
**Última Atualização:** 06/03/2026

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

### 🚀 Fase 4: Sistemas de Apoio (EM EXECUÇÃO)
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar slots, persistência visual e trava anti-spam.
* [x] **4.2 Reverse (Undo)**: Retorno ao grid com animação de voo e Z-index dinâmico.
* [x] **4.3 Drag & Peek (Arrasto Livre)**: Mecânica tátil com retorno elástico, protegendo o estado visual.
* [ ] **4.4 UI de Cargas e Ads (Placeholder)**: **[ATIVO]** Remoção de bloqueio visual, adição de labels numéricos e popup genérico de recarga (+2 usos) individual por poder.

### ⏳ Fase 5: Progressão e Níveis (Planejamento)
* [ ] **5.1 Gerador de Níveis**: Suporte a múltiplos layouts e aumento de dificuldade.
* [ ] **5.2 Fluxo de Vitória/Derrota**: Telas de conclusão e transição de fase.

### ⏳ Fase 6: Refinamento, Identidade e UX (Futuro)
* [ ] **6.1 Assets Finais**: Integração das artes definitivas de gatos e cenários.
* [ ] **6.2 Menu de Título**: Tela inicial e interface de navegação (Start/Config).
* [ ] **6.3 Splash Screens & Logos**: Apresentação da empresa e identidade do jogo.
* [ ] **6.4 Sistema de Loading**: Tela de carregamento para ocultar a inicialização do tabuleiro.
* [ ] **6.5 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **6.6 UI de Monetização (Artes)**: Criação das artes definitivas para os popups de carregamento por Ads (Hint e Undo).
* [ ] **6.7 Retrabalho de Menus e HUD**: Refatoração visual (artes e botões) do Menu de Pausa, Popup de Vitória e dos botões principais da HUD (Undo, Hint e Menu Hambúrguer).

---

## 🛠️ 2. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Centralização Dinâmica**: UI responsiva (HBoxContainer) e tabuleiro posicionado com sincronização de frame (`await`).
* **Economia de Poderes**: Sistema de cargas integrado para futura monetização (Ads F2P) e balanceamento de dificuldade, com recarga independente por habilidade.

---

### 👨‍💼 Notas do Diretor
> "O jogo agora respira e interage com o jogador. A mecânica de Drag & Peek trouxe a fisicalidade premium que procurávamos, enquanto a arquitetura do Undo e Hint V2 foi blindada contra *edge cases*. O tabuleiro não é apenas um puzzle, é uma interface tátil e reativa, pronta para sustentar a economia de F2P do jogo."