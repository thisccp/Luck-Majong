📈 1. Roadmap Integral de Desenvolvimento
✅ Fase 1: Fundação e Estrutura Básica (Concluído)
[x] Setup da Engine: Configuração do ambiente Godot para mobile.

[x] Arquitetura de Classes: Estrutura BoardManager e MahjongTile.

[x] Atlas de Texturas: Lógica de carregamento e gestão do image_0.png.

[x] Layout Turtle: Implementação inicial da estrutura clássica.

✅ Fase 2: Mecânicas e Regras de Jogo (Concluído)
[x] Geração Reversa: Algoritmo para tabuleiros 100% solucionáveis.

[x] Sistema de Inventário: Implementação dos 4 slots de armazenamento.

[x] Regra 90/10: Lógica de bloqueio por pixel (10% de cobertura).

[x] Bloqueio Lateral: Validação de peças livres através das bordas.

✅ Fase 3: Renderização e Imersão (Concluído)
[x] 3.1 - 3.4: Sincronização via await, Escala Dinâmica e Maximização de Sprites.

[x] 3.5 Neko Block (Verticalização): Transição para layout Portrait (Pillar de 6 colunas) validado para escala premium no S25.

[x] 3.6 Ajuste de Contato: Implementação do encaixe "Beijo de Pixel", sobreposição tátil (Z+1) e correção do Drop Shadow.

🚀 Fase 4: Sistemas de Apoio (EM EXECUÇÃO)
[x] 4.1 Hint V2 (Dica Inteligente): Sistema de persistência visual, trava de estado anti-spam e economia de 4 cargas.

[x] 4.2 Reverse (Undo): Retorno com animação de voo, Z-index dinâmico, blindagem de instâncias fantasmas e economia de 3 cargas.

[x] 4.3 Drag & Peek (Arrasto Livre): Mecânica de espiar camadas inferiores com retorno elástico, protegendo o estado visual da Dica.

[ ] 4.4 Lapidação Final de UI/UX: [ATIVO] Refinamentos finais de comportamento e regras para os botões Hint e Undo antes do avanço estrutural.

⏳ Fase 5: Progressão e Níveis (Planejamento)
[ ] 5.1 Gerador de Níveis: Suporte a múltiplos layouts e aumento de dificuldade.

[ ] 5.2 Fluxo de Vitória/Derrota: Telas de conclusão e transição de fase.

⏳ Fase 6: Refinamento, Identidade e UX (Futuro)
[ ] 6.1 Assets Finais: Integração das artes definitivas de gatos e cenários.

[ ] 6.2 Menu de Título: Tela inicial e interface de navegação (Start/Config).

[ ] 6.3 Splash Screens & Logos: Apresentação da empresa e identidade do jogo.

[ ] 6.4 Sistema de Loading: Tela de carregamento para ocultar a inicialização do tabuleiro.

[ ] 6.5 Onboarding (Tutorial): Mini-tabuleiro interativo para ensinar as regras ao jogador.

🛠️ 2. Especificações Técnicas Atuais
Portrait-First: Estratégia de design para smartphones de tela longa (ex: Galaxy S25).

Centralização Dinâmica: UI responsiva (HBoxContainer) e tabuleiro posicionado com sincronização de frame (await).

Economia de Poderes: Sistema de cargas integrado para futura monetização (Ads) e balanceamento de dificuldade.

👨‍💼 Notas do Diretor
"O jogo agora respira e interage com o jogador. A mecânica de Drag & Peek trouxe a fisicalidade premium que procurávamos, enquanto a arquitetura do Undo e Hint V2 foi blindada contra edge cases. O tabuleiro não é apenas um puzzle, é uma interface tátil e reativa."