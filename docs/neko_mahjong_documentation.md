# 🐾 Neko Mahjong - Documentação Técnica Oficial

**Versão:** 60.1  
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

### ✅ Fase 4: Sistemas de Apoio e Economia (Concluído)
* [x] **4.1 Hint V2 (Dica Inteligente)**: Prioridade para esvaziar slots, persistência visual e trava anti-spam. Correção visual para desligar dica no Game Over.
* [x] **4.2 Reverse (Undo)**: Retorno ao grid com animação de voo e Z-index dinâmico.
* [x] **4.3 Drag & Peek (Arrasto Livre)**: Mecânica tátil com retorno elástico, protegendo o estado visual.
* [x] **4.4 UI de Cargas e Ads**: Remoção de bloqueio visual, adição de labels numéricos e popup genérico de recarga (+2 usos) individual por poder.

### ✅ Pré-Fase 5: Refatoração e Otimização Arquitetural (Concluído)
* [x] **Separação de Responsabilidades**: Refatoração da interface de Ads/Popups para cenas independentes (`.tscn`), blindando a lógica principal de UI gerada por código.

### 🚀 Fase 5: Progressão Procedural e Flow (EM EXECUÇÃO)
* [x] **5.1 Gerador Determinístico de Formatos**: Algoritmo baseado em Arquétipos (Shapes), utilizando a "Seed" do nível para garantir layouts fixos por fase (O Nível X é sempre igual para todos).
* [x] **5.2 Curva de Dificuldade Controlada**: Progressão roteirizada (1-5 Fáceis, 6-10 Medianos, 11+ com oscilação de picos de dificuldade e descansos).
* [ ] **5.3 Intro Cinematográfica (Tela de Nível)**: Apresentação do tabuleiro com material de Desfoque (Blur), mensagem temática e efeitos sonoros ditando a dificuldade.
* [ ] **5.4 Fluxo de Vitória/Derrota**: Telas de conclusão, cálculo de pontuação e transição progressiva de nível.

### ⏳ Fase 6: Backlog, Retenção (Meta-Jogo) e UX (Futuro)
* [ ] **6.1 Meta-Jogo (Sistema de Coleção)**: Área de galeria onde o jogador desbloqueia novos tipos de gatos.
* [ ] **6.2 Expansão do Pool de Peças**: Injeção progressiva de novos gatos (+1 de cada vez) no tabuleiro.
* [ ] **6.3 Expansão do Catálogo de Formatos (Shapes)**: Criação de novos layouts de tabuleiro para atualizações futuras.
* [ ] **6.4 Recursos Visuais**: Assets finais (gatos e cenários), Splash Screens e Logos.
* [ ] **6.5 UI e Menus**: Menu de Título, Sistema de Loading, UI de Ads e retrabalho de popups (Vitória/Pausa).
* [ ] **6.6 Onboarding (Tutorial)**: Mini-tabuleiro interativo para ensinar as regras.
* [ ] **6.7 Funcionalidades Online (Low Priority)**: Placares globais/amigos (Leaderboards) baseados na conclusão de níveis de caminho fixo.
* [ ] **6.8 Sistema de Recompensas por Marcos**: **[NOVO]** A cada X níveis (ex: 10), o jogador ganha um "Baú" contendo +1 Hint e +1 Undo. Inclui opção via Ads para dobrar a recompensa (2x).

---

## 🛠️ 2. Especificações Técnicas Atuais
* **Portrait-First**: Estratégia de design para smartphones de tela longa.
* **Flow de Dificuldade**: Ciclo de engajamento que intercala relaxamento e tensão, garantido por seeds determinísticas.
* **Economia F2P Híbrida**: Monetização sustentada por Ads para recarga de poderes e multiplicadores em baús de recompensa.

---

### 👨‍💼 Notas do Diretor
> "Fechamos o núcleo do jogo. Com a geração procedural ancorada em sementes fixas e uma curva de dificuldade em montanha-russa, o Neko Mahjong tem agora uma campanha infinita e estruturada. O sistema de Ads está organicamente enraizado nas mecânicas de sobrevivência e recompensa, pronto para escalar de forma rentável."