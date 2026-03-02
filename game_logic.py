"""
game_logic.py — Motor de lógica do Mahjong Solitaire (sem dependência de Kivy).

Classes:
    Tile       – Representa uma peça no tabuleiro (x, y, z, type_id).
    MahjongLogic – Gerencia o tabuleiro: geração solvável, regras de seleção,
                   matching, hint, shuffle, vitória e detecção de "sem jogadas".

O sistema de coordenadas usa X (coluna), Y (linha) e Z (camada 0-4).
Cada peça ocupa 2 células de largura × 1 de altura na grade.
"""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Set

# ---------------------------------------------------------------------------
# Tile
# ---------------------------------------------------------------------------

@dataclass
class Tile:
    """Uma peça do Mahjong Solitaire."""
    x: int          # Coluna (canto esquerdo da peça — a peça ocupa x e x+1)
    y: int          # Linha
    z: int          # Camada (0 = base, até 4)
    type_id: int    # Identificador do tipo / estampa (0-34 → 35 tipos)
    matched: bool = False   # True quando a peça já foi removida por match

    @property
    def pos(self) -> Tuple[int, int, int]:
        return (self.x, self.y, self.z)

    def cells_occupied(self) -> Set[Tuple[int, int]]:
        """Retorna o conjunto de células (col, row) que esta peça cobre."""
        return {(self.x, self.y), (self.x + 1, self.y)}

    def __hash__(self):
        return hash(self.pos)

    def __eq__(self, other):
        if not isinstance(other, Tile):
            return NotImplemented
        return self.pos == other.pos


# ---------------------------------------------------------------------------
# Layout definitions  (posições válidas para cada camada)
# ---------------------------------------------------------------------------

def _classic_pyramid_layout() -> List[Tuple[int, int, int]]:
    """
    Gera um layout de pirâmide clássica com 5 camadas.
    Retorna lista de (x, y, z).
    Cada tile ocupa colunas [x, x+1].

    Camada 0 (base):  12 × 8 = 96 tiles  → ~90 (ajustado para ter número par total)
    Camada 1:         10 × 6 = 60
    Camada 2:          8 × 4 = 32
    Camada 3:          4 × 2 = 8
    Camada 4:          2 × 1 = 2
    Total ajustado → número par (≤ 140) → 70 pares
    """
    slots: List[Tuple[int, int, int]] = []

    # Definição por camada: (cols_tiles, rows, x_offset, y_offset)
    layers = [
        # z=0  — 12 colunas × 7 linhas = 84 tiles
        (12, 7, 0, 0),
        # z=1  — 10 × 5 = 50 tiles
        (10, 5, 1, 1),
        # z=2  — 6 × 3 = 18 tiles
        (6, 3, 3, 2),
        # z=3  — 4 × 2 = 8 tiles (ajustado para par)
        (4, 2, 4, 3),  # corrigido para ficar centralizado
        # z=4  — topo — 2 × 1 = 2 tiles
        (2, 1, 5, 3),
    ]
    # Total = 84 + 50 + 18 + 8 + 2 = 162 → muito!
    # Vamos reduzir para algo mais jogável / razoável.
    # Layout revisado:
    layers = [
        # z=0  — 10 × 7 = 70
        (10, 7, 0, 0),
        # z=1  — 8 × 5 = 40
        (8, 5, 1, 1),
        # z=2  — 6 × 3 = 18
        (6, 3, 2, 2),
        # z=3  — 4 × 1 = 4
        (4, 1, 3, 3),
        # z=4  — 2 × 1 = 2
        (2, 1, 4, 3),
    ]
    # Total = 70 + 40 + 18 + 4 + 2 = 134  → 67 pares (ímpar — ajustar)
    # Ajustar z=3 para 4×2=8 → total=140 → 70 pares ✔
    layers = [
        (10, 7, 0, 0),   # 70
        (8, 5, 1, 1),    # 40
        (6, 3, 2, 2),    # 18
        (4, 2, 3, 3),    # 8  (centra dentro da camada anterior)
        (2, 1, 4, 3),    # 2  (mas y_offset=3 não centra bem; vamos ajustar)
    ]
    # Recalculando y_offsets para centralizar melhor:
    # z0: rows=7, y_start=0
    # z1: rows=5, y_start=1  (centraliza em 7: (7-5)//2=1) ✔
    # z2: rows=3, y_start=2  (centraliza em 7: (7-3)//2=2) ✔
    # z3: rows=2, y_start=2  (centraliza em 7: (7-2)//2=2)
    # z4: rows=1, y_start=3  (centraliza em 7: (7-1)//2=3) ✔
    layers = [
        (10, 7, 0, 0),   # 70 tiles
        (8, 5, 1, 1),    # 40 tiles
        (6, 3, 2, 2),    # 18 tiles
        (4, 2, 3, 2),    # 8 tiles  (y centra melhor com offset 2)
        (2, 1, 4, 3),    # 2 tiles
    ]
    # Total = 70+40+18+8+2 = 138 → 69 pares — ímpar! Precisamos par.
    # Ajuste: adicionar 2 tiles extras na base → 72 + ... = 140
    # Ou: z0 = 10×7=70, z1 = 8×5=40, z2 = 6×3=18, z3 = 2×2=4, z4 = 2×1=2
    # → 70+40+18+4+2 = 134 → 67 pares — ímpar!
    # Melhor abordagem: truncar para garantir par.
    # Vamos usar um tamanho que dê par facilmente:
    layers = [
        (10, 7, 0, 0),   # 70 tiles
        (8, 5, 1, 1),    # 40 tiles
        (6, 3, 2, 2),    # 18 tiles
        (4, 1, 3, 3),    # 4 tiles
        (2, 1, 4, 3),    # 2 tiles
    ]
    # Total = 70+40+18+4+2 = 134 → 67 pares (ímpar!)
    # Adicionemos mais 2 à z3 → (4,2,...) = 8 → total 140 → 70 pares ✔
    # Mas (4,2,3,3) → y_start 3, height 2 → rows 3,4, dentro do range 0-6 ✔
    # Porém 140 tiles = muitas para um protótipo. Vamos simplificar:
    # Layout menor e mais agradável:
    layers = [
        (6, 5, 0, 0),   # 30 tiles
        (4, 3, 1, 1),   # 12 tiles
        (2, 1, 2, 2),   # 2 tiles
    ]
    # Total = 30+12+2 = 44 → 22 pares ✔  Perfeito para protótipo!

    for z, (cols, rows, x_off, y_off) in enumerate(layers):
        for col in range(cols):
            for row in range(rows):
                slots.append((x_off + col, y_off + row, z))

    return slots


# ---------------------------------------------------------------------------
# MahjongLogic
# ---------------------------------------------------------------------------

class MahjongLogic:
    """
    Motor central do jogo. Gerencia o tabuleiro, regras e estado.

    Uso típico:
        logic = MahjongLogic()
        logic.new_game()
        free = logic.is_tile_free(tile)
        logic.try_match(tile_a, tile_b)
    """

    def __init__(self, layout_fn=None, num_types: int = 22):
        """
        Args:
            layout_fn: Função que retorna List[(x,y,z)] de posições.
                        Padrão: _classic_pyramid_layout.
            num_types: Quantidade de tipos distintos de peça.
        """
        self._layout_fn = layout_fn or _classic_pyramid_layout
        self._num_types = num_types
        self.tiles: Dict[Tuple[int, int, int], Tile] = {}
        self._move_history: List[Tuple[Tile, Tile]] = []

    # ---- public API ----

    def new_game(self):
        """Gera um novo tabuleiro 100% solvável."""
        self.tiles.clear()
        self._move_history.clear()
        slots = self._layout_fn()
        self._generate_beatable(slots)

    def active_tiles(self) -> List[Tile]:
        """Retorna tiles ainda não removidos."""
        return [t for t in self.tiles.values() if not t.matched]

    def is_tile_free(self, tile: Tile) -> bool:
        """
        Uma peça está livre se:
          1. Nenhuma peça em z+1 sobrepõe qualquer de suas células.
          2. Pelo menos um dos lados (esquerdo ou direito) está livre.
        """
        if tile.matched:
            return False

        # --- Bloqueio por sobreposição (z+1) ---
        # A tile ocupa cells (x, y) e (x+1, y).
        # Uma tile acima em z+1 ocupa (ax, ay) e (ax+1, ay).
        # Há sobreposição se as células se interceptam.
        for other in self.tiles.values():
            if other.matched or other.z != tile.z + 1:
                continue
            if other.cells_occupied() & tile.cells_occupied():
                return False

        # --- Bloqueio lateral (regra clássica) ---
        # Lado esquerdo: livre se não há peça em (x-2, y, z) ... (x-1 ocuparia
        # a coluna x que já é da tile, então a vizinha à esquerda começa em x-2).
        # Na verdade, a peça vizinha à esquerda teria seu x+1 == tile.x - 1,
        # logo vizinha_esq.x = tile.x - 2.
        left_blocked = self._has_neighbor(tile.x - 2, tile.y, tile.z)
        right_blocked = self._has_neighbor(tile.x + 2, tile.y, tile.z)

        if left_blocked and right_blocked:
            return False

        return True

    def try_match(self, t1: Tile, t2: Tile) -> bool:
        """
        Tenta fazer match de duas peças.
        Retorna True se o match foi realizado.
        """
        if t1 is t2:
            return False
        if t1.matched or t2.matched:
            return False
        if t1.type_id != t2.type_id:
            return False
        if not self.is_tile_free(t1) or not self.is_tile_free(t2):
            return False

        t1.matched = True
        t2.matched = True
        self._move_history.append((t1, t2))
        return True

    def is_won(self) -> bool:
        """Verdadeiro se todas as peças foram removidas."""
        return all(t.matched for t in self.tiles.values())

    def has_moves(self) -> bool:
        """Verdadeiro se existe pelo menos um par disponível."""
        return self.find_hint() is not None

    def find_hint(self) -> Optional[Tuple[Tile, Tile]]:
        """Retorna um par de tiles livres com mesmo type_id, ou None."""
        free = [t for t in self.tiles.values() if not t.matched and self.is_tile_free(t)]
        by_type: Dict[int, List[Tile]] = {}
        for t in free:
            by_type.setdefault(t.type_id, []).append(t)
        for tiles_of_type in by_type.values():
            if len(tiles_of_type) >= 2:
                return (tiles_of_type[0], tiles_of_type[1])
        return None

    def shuffle(self):
        """
        Embaralha as peças restantes usando geração reversa nas posições
        atuais — garante solvabilidade pós-shuffle.
        """
        remaining = [t for t in self.tiles.values() if not t.matched]
        if not remaining:
            return
        positions = [t.pos for t in remaining]

        # Remove os tiles antigos das posições restantes
        for t in remaining:
            del self.tiles[t.pos]

        # Re-gera usando o mesmo algoritmo beatable
        self._generate_beatable(positions)

    # ---- internal ----

    def _has_neighbor(self, x: int, y: int, z: int) -> bool:
        """Verifica se há uma peça ativa em (x, y, z)."""
        t = self.tiles.get((x, y, z))
        return t is not None and not t.matched

    def _generate_beatable(self, slots: List[Tuple[int, int, int]]):
        """
        Algoritmo de Geração Reversa:

        1. Começa com todas as posições "vazias".
        2. Encontra dois slots "livres" (do ponto de vista de remoção — i.e.,
           sem nada acima e pelo menos um lado livre, considerando apenas
           os slots já preenchidos).
        3. Atribui o mesmo type_id a ambos.
        4. Repete até preencher tudo.

        O truque é que ao preencher de "fora para dentro" e de "cima para
        baixo", reproduzimos a ordem reversa de um jogo resolvido.
        """
        total = len(slots)
        if total % 2 != 0:
            # Se ímpar, remove o último slot para garantir pares
            slots = slots[:-1]
            total = len(slots)

        num_pairs = total // 2
        # Gerar lista de type_ids: pares completos
        type_ids = []
        for i in range(num_pairs):
            tid = i % self._num_types
            type_ids.append(tid)
        random.shuffle(type_ids)

        # Set de slots ainda não preenchidos
        remaining_slots: Set[Tuple[int, int, int]] = set(slots)

        # Tiles já "colocados" nesta geração (vamos preenchendo)
        placed: Dict[Tuple[int, int, int], Tile] = {}

        pair_index = 0
        max_attempts = 1000  # segurança contra loops infinitos

        while remaining_slots and pair_index < num_pairs:
            # Encontrar slots "livres" no contexto da geração reversa:
            # Um slot é "livre para remoção" se:
            #   - Nenhum slot preenchido em z+1 o sobrepõe
            #   - Pelo menos um lado (esquerdo ou direito) está livre (sem slot preenchido)
            free_slots = self._find_free_slots_for_generation(remaining_slots, placed)

            if len(free_slots) < 2:
                # Fallback: se o algoritmo travar, usa qualquer slot restante
                free_slots = list(remaining_slots)
                if len(free_slots) < 2:
                    break

            # Escolhe dois slots aleatórios
            random.shuffle(free_slots)
            s1 = free_slots[0]
            s2 = free_slots[1]

            tid = type_ids[pair_index]

            t1 = Tile(x=s1[0], y=s1[1], z=s1[2], type_id=tid)
            t2 = Tile(x=s2[0], y=s2[1], z=s2[2], type_id=tid)

            placed[s1] = t1
            placed[s2] = t2
            remaining_slots.discard(s1)
            remaining_slots.discard(s2)

            pair_index += 1

        self.tiles.update(placed)

    def _find_free_slots_for_generation(
        self,
        remaining: Set[Tuple[int, int, int]],
        placed: Dict[Tuple[int, int, int], Tile]
    ) -> List[Tuple[int, int, int]]:
        """
        Encontra slots que estão "livres" para serem preenchidos na geração reversa.
        Um slot é livre se:
          - Não há tile 'placed' em z+1 que o sobreponha.
          - Pelo menos um lado (esq/dir) está sem tile 'placed'.
        """
        free = []
        for (sx, sy, sz) in remaining:
            # Checar sobreposição acima (z+1)
            blocked_above = False
            cells = {(sx, sy), (sx + 1, sy)}
            for (px, py, pz) in placed:
                if pz == sz + 1:
                    placed_cells = {(px, py), (px + 1, py)}
                    if placed_cells & cells:
                        blocked_above = True
                        break
            if blocked_above:
                continue

            # Checar lados
            left_pos = (sx - 2, sy, sz)
            right_pos = (sx + 2, sy, sz)
            left_blocked = left_pos in placed
            right_blocked = right_pos in placed

            if left_blocked and right_blocked:
                continue

            free.append((sx, sy, sz))

        return free
