"""
board_widget.py — Widget do tabuleiro que renderiza todas as peças com efeito 3D.

BoardWidget traduz coordenadas lógicas (x, y, z) em posições de tela,
com offsets por camada Z para criar a ilusão de empilhamento.
"""

from kivy.uix.relativelayout import RelativeLayout
from kivy.properties import ObjectProperty
from kivy.metrics import dp

from tile_widget import TileWidget


# Constantes de dimensão (em dp para responsividade)
CELL_W = dp(40)      # Largura de uma célula (tile ocupa 2 células = 2 × CELL_W)
CELL_H = dp(52)      # Altura de uma célula (tile 1:2 → altura ≈ 1.3× largura visual)
TILE_W = CELL_W * 2  # Largura real do tile widget
TILE_H = CELL_H      # Altura real do tile widget

# Offset 3D por camada
Z_OFFSET_X = dp(6)   # Deslocamento X por nível Z
Z_OFFSET_Y = dp(6)   # Deslocamento Y por nível Z


class BoardWidget(RelativeLayout):
    """
    Renderiza o tabuleiro de Mahjong Solitaire.

    Uso:
        board = BoardWidget()
        board.logic = mahjong_logic_instance
        board.rebuild()
    """

    logic = ObjectProperty(None, allownone=True)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._tile_widgets: dict = {}  # (x,y,z) → TileWidget
        self._on_tile_press_callback = None

    def set_tile_press_callback(self, callback):
        """Define o callback chamado quando uma peça é pressionada."""
        self._on_tile_press_callback = callback

    def rebuild(self):
        """Reconstrói todos os widgets de peça a partir do estado da lógica."""
        self.clear_widgets()
        self._tile_widgets.clear()

        if not self.logic:
            return

        # Calcular bounds para centralizar o tabuleiro
        active = self.logic.active_tiles()
        if not active:
            return

        max_x = max(t.x for t in active) + 2  # +2 porque tile ocupa 2 colunas
        max_y = max(t.y for t in active) + 1
        max_z = max(t.z for t in active)

        # Tamanho total do tabuleiro em pixels
        board_w = max_x * CELL_W + max_z * Z_OFFSET_X + TILE_W
        board_h = max_y * CELL_H + max_z * Z_OFFSET_Y + TILE_H

        # Offset para centralizar no widget
        offset_x = (self.width - board_w) / 2 if self.width > board_w else dp(10)
        offset_y = (self.height - board_h) / 2 if self.height > board_h else dp(10)

        # Ordenar por Z (menor primeiro) para que camadas superiores fiquem por cima
        sorted_tiles = sorted(active, key=lambda t: (t.z, t.y, t.x))

        for tile in sorted_tiles:
            screen_x = offset_x + tile.x * CELL_W + tile.z * Z_OFFSET_X
            # Inverter Y para que row 0 fique em cima
            screen_y = offset_y + (max_y - tile.y) * CELL_H + tile.z * Z_OFFSET_Y

            tw = TileWidget(tile=tile)
            tw.pos = (screen_x, screen_y)
            tw.size = (TILE_W, TILE_H)
            tw.size_hint = (None, None)

            # Definir estado blocked
            tw.blocked = not self.logic.is_tile_free(tile)

            # Bind press
            tw.bind(on_press=self._handle_tile_press)

            self.add_widget(tw)
            self._tile_widgets[tile.pos] = tw

    def update_tile_states(self):
        """Atualiza o estado visual (blocked/selected) de todas as peças."""
        if not self.logic:
            return
        for pos, tw in list(self._tile_widgets.items()):
            tile = tw.tile
            if tile.matched:
                # Remover da view
                self.remove_widget(tw)
                del self._tile_widgets[pos]
            else:
                tw.blocked = not self.logic.is_tile_free(tile)

    def highlight_hint(self, tile1, tile2):
        """Destaca duas peças como hint."""
        self.clear_selection()
        tw1 = self._tile_widgets.get(tile1.pos)
        tw2 = self._tile_widgets.get(tile2.pos)
        if tw1:
            tw1.selected = True
        if tw2:
            tw2.selected = True

    def clear_selection(self):
        """Remove qualquer seleção visual."""
        for tw in self._tile_widgets.values():
            tw.selected = False

    def _handle_tile_press(self, tile_widget):
        """Delega o evento de press ao callback do controller."""
        if self._on_tile_press_callback:
            self._on_tile_press_callback(tile_widget)
