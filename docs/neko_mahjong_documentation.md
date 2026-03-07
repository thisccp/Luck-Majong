# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 57.0  
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

### ✅ Fase 4: Sistemas de Apoio (Concluído)
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar slots, persistência visual e trava anti-spam.
* [x] **4.2 Reverse (Undo)**: Retorno ao grid com animação de voo e Z-index dinâmico.
* [x] **4.3 Drag & Peek (Arrasto Livre)**: Mecânica tátil com retorno elástico, protegendo o estado visual.
* [x] **4.4 UI de Cargas e Ads**: Remoção de bloqueio visual, adição de labels numéricos e popup genérico de recarga (+2 usos) individual por poder.

### ✅ Pré-Fase 5: Refatoração e Otimização Arquitetural (Concluído)
* [x] **Separação de Responsabilidades**: Refatoração da interface de Ads/Popups para cenas independentes (`.tscn`), removendo instanciação de UI via código para melhor manutenção visual.

### 🚀 Fase 5: Progressão Procedural e Flow (EM EXECUÇÃO)
* [ ] **5.1 Gerador Procedural de Formatos**: **[ATIVO]** Algoritmo de sorteio infinito baseado em 5 a 8 Arquétipos (Shapes). Inclui trava matemática para impedir repetição do mesmo formato em níveis consecutivos.
* [ ] **5.2 Escalonamento de Dificuldade**: Controle de eixo Z (camadas). Níveis Relax (espalhados, Z baixo) misturados aleatoriamente com Níveis Boss (torres concentradas, Z alto).
* [ ] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação do tabuleiro com material de Desfoque (Blur), mensagem temática ("Miado Fofo" vs "Gato Arisco") e efeitos sonoros ditando a dificuldade antes de o nível iniciar.
* [ ] **5.4 Fluxo de Vitória/Derrota**: Telas de conclusão, cálculo de pontuação e transição para o próximo nível procedural.

### ⏳ Fase 6: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **6.1 Meta-Jogo (Sistema de Coleção)**: **[NOVO]** Área de galeria onde o jogador desbloqueia novos tipos de gatos após vencer "X" níveis.
* [ ] **6.2 Expansão do Pool de Peças**: **[NOVO]** Início com 20 tipos de gatos. Injeção progressiva de novos gatos (+1 de cada vez) no tabuleiro à medida que o jogador avança. Requer balanceamento cuidadoso de Z-index para não sobrecarregar a altura do tabuleiro precocemente.
* [ ] **6.3 Assets Finais**: Integração das artes definitivas de gatos e cenários.
* [ ] **6.4 Menu de Título e Navegação**: Tela inicial e configurações (Start/Config).
* [ ] **6.5 Splash Screens & Logos**: Apresentação da empresa e identidade do jogo.
* [ ] **6.6 Sistema de Loading**: Tela de carregamento para inicialização de recursos.
* [ ] **6.7 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **6.8 UI de Monetização (Artes)**: Criação das artes definitivas para os popups de Ads.
* [ ] **6.9 Retrabalho de Menus e HUD**: Refatoração visual (artes e botões) do Menu de Pausa, Popup de Vitória e HUD principal.

---

## 🛠️ 2. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Flow de Dificuldade**: Ciclo de engajamento que intercala relaxamento e tensão, avisado visualmente e sonoramente na introdução do nível.
* **Economia de Poderes**: Sistema de cargas integrado para futura monetização (Ads F2P) e balanceamento de dificuldade.

---

### 👨‍💼 Notas do Diretor
> "O projeto entra agora na sua fase de escalabilidade. Com o Gerador Procedural e a Intro Cinematográfica, transformamos a mecânica num ciclo infinito de diversão. A visão futura para a Fase 6 garante que o jogador terá sempre um novo gatinho para resgatar e colecionar, criando um fator de retenção de longo prazo."