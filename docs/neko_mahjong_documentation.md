# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 52.0  
**Última Atualização:** 05/03/2026

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

### 🚀 Fase 3: Renderização e Imersão (EM EXECUÇÃO)
* [x] **3.1 - 3.4**: Sincronização via `await`, Escala Dinâmica e Maximização de Sprites.
* [ ] **3.5 Neko Block (Verticalização)**: **[ATIVO]** Transição para layout Portrait para escala premium.
* [ ] **3.6 Ajuste de Contato**: **[ATIVO]** Implementação do encaixe "Beijo de Pixel" e sombras de profundidade.

### ⏳ Fase 4: Sistemas de Apoio (Pendente)
* **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar os 4 slots antes de sugerir peças novas.
* **4.2 Reverse (Undo)**: Sistema de retrocesso de jogada e devolução de peças ao grid.

### ⏳ Fase 5: Progressão e Níveis (Planejamento)
* **5.1 Gerador de Níveis**: Suporte a múltiplos layouts e aumento de dificuldade.
* **5.2 Fluxo de Vitória/Derrota**: Telas de conclusão e transição de fase.

### ⏳ Fase 6: Refinamento, Identidade e UX (Futuro)
* **6.1 Assets Finais**: Integração das artes definitivas de gatos e cenários.
* **6.2 Menu de Título**: Tela inicial e interface de navegação (Start/Config).
* **6.3 Splash Screens & Logos**: Apresentação da empresa e identidade do jogo.
* **6.4 Sistema de Loading**: Tela de carregamento para ocultar a inicialização do tabuleiro.
* **6.5 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras ao jogador.

---

## 🛠️ 2. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Centralização Dinâmica**: Tabuleiro posicionado entre a `InventoryBar` e o `HintBtn`.
* **Escala Premium**: Fator de escala visando > 1.25 para detalhes nítidos.

---

### 👨‍💼 Notas do Diretor
> "O repositório agora reflete um projeto estruturado para o mercado. Da fundação técnica às Splash Screens, cada passo é planejado para o prazer visual do jogador."