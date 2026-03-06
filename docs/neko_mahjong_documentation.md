# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 53.0  
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
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar os slots com feedback visual contínuo e sincronizado.
* [x] **4.2 Reverse (Undo)**: Sistema de retrocesso de jogada e devolução de peças ao grid.
* [ ] **4.3 Drag & Peek (Arrasto Livre)**: **[ATIVO]** Permitir arrastar a peça pelo ecrã para evitar miss clicks e espiar camadas inferiores, retornando à origem ao soltar.

### ⏳ Fase 5: Progressão e Níveis (Planejamento)
* [ ] **5.1 Gerador de Níveis**: Suporte a múltiplos layouts e aumento de dificuldade.
* [ ] **5.2 Fluxo de Vitória/Derrota**: Telas de conclusão e transição de fase.

### ⏳ Fase 6: Refinamento, Identidade e UX (Futuro)
* [ ] **6.1 Assets Finais**: Integração das artes definitivas de gatos e cenários.
* [ ] **6.2 Menu de Título**: Tela inicial e interface de navegação (Start/Config).
* [ ] **6.3 Splash Screens & Logos**: Apresentação da empresa e identidade do jogo.
* [ ] **6.4 Sistema de Loading**: Tela de carregamento para ocultar a inicialização do tabuleiro.
* [ ] **6.5 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras ao jogador.

---

## 🛠️ 2. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa (ex: Galaxy S25).
* **Centralização Dinâmica**: Tabuleiro posicionado entre a `InventoryBar` e o `HintBtn`, com sincronização de frame (`await`).
* **Escala Premium**: Fator de escala maximizado através da limitação para 6 colunas para detalhes nítidos.

---

### 👨‍💼 Notas do Diretor
> "O repositório agora reflete um projeto estruturado para o mercado. Da fundação técnica às Splash Screens, cada passo é planejado para o prazer visual do jogador. Com a Fase 3 vencida, o foco agora é a inteligência estratégica dos sistemas de apoio."