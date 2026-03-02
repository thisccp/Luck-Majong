"""
tile_widget.py — Widget visual de uma peça do Mahjong Solitaire (Kivy).

TileWidget é um botão colorido com proporção 1:2 (largura × altura)
que exibe o type_id como texto central e muda de aparência conforme o estado.
"""

from kivy.uix.widget import Widget
from kivy.uix.behaviors import ButtonBehavior
from kivy.graphics import Color, Rectangle, Line
from kivy.uix.label import Label
from kivy.properties import (
    NumericProperty, BooleanProperty, ObjectProperty, ListProperty
)
from kivy.metrics import dp

# Cores geradas via HSV para 35 tipos distintos
def _color_for_type(type_id: int, total_types: int = 22):
    """Retorna (r, g, b, a) distinta para cada type_id usando HSV."""
    from colorsys import hsv_to_rgb
    hue = (type_id / total_types) % 1.0
    saturation = 0.65
    value = 0.85
    r, g, b = hsv_to_rgb(hue, saturation, value)
    return (r, g, b, 1.0)


class TileWidget(ButtonBehavior, Widget):
    """
    Representação visual de uma peça de Mahjong.

    Propriedades:
        tile       – referência ao objeto Tile da lógica.
        type_id    – tipo da peça (usado para cor e texto).
        selected   – se a peça está selecionada (borda brilhante).
        blocked    – se a peça está bloqueada (semi-transparente).
        base_color – cor RGBA base derivada do type_id.
    """

    type_id = NumericProperty(0)
    selected = BooleanProperty(False)
    blocked = BooleanProperty(False)
    tile = ObjectProperty(None, allownone=True)
    base_color = ListProperty([0.5, 0.5, 0.5, 1.0])

    def __init__(self, tile=None, **kwargs):
        super().__init__(**kwargs)
        self.tile = tile
        if tile:
            self.type_id = tile.type_id
        self.base_color = list(_color_for_type(self.type_id))

        self._rect_color = None
        self._rect = None
        self._border = None
        self._border_color = None
        self._label = Label(
            text=str(self.type_id),
            font_size=dp(14),
            bold=True,
            color=(1, 1, 1, 1),
            halign='center',
            valign='middle',
        )
        self.add_widget(self._label)

        self.bind(pos=self._update_canvas, size=self._update_canvas)
        self.bind(selected=self._update_canvas, blocked=self._update_canvas)
        self.bind(type_id=self._on_type_changed)

        self._draw()

    def _on_type_changed(self, *args):
        self.base_color = list(_color_for_type(self.type_id))
        self._label.text = str(self.type_id)
        self._draw()

    def _draw(self):
        """Redesenha o canvas."""
        self.canvas.before.clear()
        with self.canvas.before:
            # Fundo do tile
            if self.blocked:
                c = [self.base_color[0] * 0.4,
                     self.base_color[1] * 0.4,
                     self.base_color[2] * 0.4,
                     0.6]
            elif self.selected:
                c = [min(1.0, self.base_color[0] + 0.25),
                     min(1.0, self.base_color[1] + 0.25),
                     min(1.0, self.base_color[2] + 0.25),
                     1.0]
            else:
                c = list(self.base_color)

            self._rect_color = Color(*c)
            self._rect = Rectangle(pos=self.pos, size=self.size)

            # Borda
            if self.selected:
                self._border_color = Color(1, 1, 0.2, 1)  # amarelo brilhante
                self._border = Line(
                    rectangle=(self.x, self.y, self.width, self.height),
                    width=dp(2.5)
                )
            else:
                self._border_color = Color(0.2, 0.2, 0.2, 0.8)
                self._border = Line(
                    rectangle=(self.x, self.y, self.width, self.height),
                    width=dp(1)
                )

    def _update_canvas(self, *args):
        self._draw()
        # Atualizar label
        self._label.pos = self.pos
        self._label.size = self.size
        self._label.text_size = self.size
