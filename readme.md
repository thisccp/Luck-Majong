# 🐾 Neko Mahjong

**Neko Mahjong** é um jogo de puzzle mobile desenvolvido em **Godot 4.x**, focado em oferecer uma experiência relaxante, tátil e visualmente encantadora para amantes de gatos. 

O projeto é otimizado especificamente para dispositivos android, garantindo que as artes das peças sejam o destaque absoluto da tela, aliados a uma performance térmica estável e áudio imersivo.

## ✨ Diferenciais do Projeto
* **Sistema de 4 Slots**: Mecânica de inventário dinâmico (estilo Match-3D/Solitaire) que exige estratégia para gerenciar espaço.
* **Algoritmo Determinístico**: Sistema de "Geração Reversa" garantindo que **100% dos tabuleiros são solucionáveis**, sem situações de beco sem saída.
* **Layouts Portrait-First**: Tabuleiros desenhados verticalmente ("Neko Block") para maximizar a escala das peças em smartphones.
* **Regra 55/45 de Colisão**: Lógica de bloqueio vertical com 45% de tolerância de sobreposição, suportando offsets agressivos de perspectiva 3D sem gerar falsos bloqueios.
* **Atmosfera Zen e Feedback Tátil**: Trilha sonora contínua (Floresta, Casa, Chuva) que se adapta ao mundo atual, combinada com "Juicy Buttons" e sons físicos satisfatórios no impacto das peças.
* **Sistema de Tiers (Fever Mode)**: Progressão de combos (1 a 6) que escala visualmente a interface e a recompensa em pontos.

## 🛠️ Tecnologias
* **Engine**: Godot 4.x
* **Linguagem**: GDScript
* **Target**: Mobile (Otimizado para Android)
* **Monetização**: Híbrida (F2P Focado em Rewarded Video, zero Banners)

## 🚀 Status do Desenvolvimento
**Versão Atual:** 84.2
O projeto concluiu as Fases de Core Loop, Progressão e UI. Atualmente encontra-se na **Fase 6: Áudio, Performance Mobile e Correções Críticas**, com foco na estabilização absoluta da mecânica de Match (resolução de *Race Conditions*) para iniciar a **Fase R: Refatoração Arquitetural** (Singletons e Máquina de Estados).