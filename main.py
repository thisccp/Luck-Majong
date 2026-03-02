"""
main.py — Aplicação principal do Mahjong Solitaire (Kivy).

Contém o GameApp (controller) que orquestra:
  - Geração do tabuleiro e novo jogo
  - Seleção e matching de peças
  - Botões Reset, Hint, Shuffle
  - Popups de vitória e "sem jogadas"
"""

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.clock import Clock
from kivy.core.window import Window
from kivy.metrics import dp

from game_logic import MahjongLogic
from board_widget import BoardWidget


class MahjongApp(App):
    """Aplicação Kivy do Mahjong Solitaire."""

    def build(self):
        self.title = 'Lucky Mahjong — Solitaire'

        # ---- Lógica ----
        self.logic = MahjongLogic()
        self.selected_tile_widget = None  # TileWidget atualmente selecionado
        self.pairs_matched = 0

        # ---- Layout principal ----
        root = BoxLayout(orientation='vertical', padding=dp(8), spacing=dp(6))

        # -- Barra de título --
        title_label = Label(
            text='[b]Lucky Mahjong[/b]',
            markup=True,
            font_size=dp(22),
            size_hint_y=None,
            height=dp(36),
            color=(1, 0.85, 0.3, 1),
        )
        root.add_widget(title_label)

        # -- Barra de botões --
        btn_bar = BoxLayout(
            orientation='horizontal',
            size_hint_y=None,
            height=dp(48),
            spacing=dp(8),
        )

        btn_reset = Button(
            text='🔄 Reset',
            font_size=dp(15),
            background_color=(0.3, 0.5, 0.8, 1),
            bold=True,
        )
        btn_reset.bind(on_press=self._on_reset)

        btn_hint = Button(
            text='💡 Hint',
            font_size=dp(15),
            background_color=(0.8, 0.6, 0.1, 1),
            bold=True,
        )
        btn_hint.bind(on_press=self._on_hint)

        btn_shuffle = Button(
            text='🔀 Shuffle',
            font_size=dp(15),
            background_color=(0.2, 0.7, 0.4, 1),
            bold=True,
        )
        btn_shuffle.bind(on_press=self._on_shuffle)

        btn_bar.add_widget(btn_reset)
        btn_bar.add_widget(btn_hint)
        btn_bar.add_widget(btn_shuffle)
        root.add_widget(btn_bar)

        # -- Tabuleiro --
        self.board = BoardWidget()
        self.board.set_tile_press_callback(self._on_tile_pressed)
        root.add_widget(self.board)

        # -- Barra de status --
        self.status_label = Label(
            text='Pares: 0',
            font_size=dp(14),
            size_hint_y=None,
            height=dp(30),
            color=(0.9, 0.9, 0.9, 1),
        )
        root.add_widget(self.status_label)

        # Iniciar jogo após o layout estar pronto
        Clock.schedule_once(self._start_game, 0.3)

        # Definir cor de fundo da janela
        Window.clearcolor = (0.12, 0.12, 0.18, 1)

        return root

    # ==============================================================
    # Controle de jogo
    # ==============================================================

    def _start_game(self, *args):
        """Gera um novo tabuleiro e renderiza."""
        self.logic.new_game()
        self.selected_tile_widget = None
        self.pairs_matched = 0
        self._update_status()
        self.board.logic = self.logic
        self.board.rebuild()

    def _on_tile_pressed(self, tile_widget):
        """Callback chamado quando o jogador clica em uma peça."""
        tile = tile_widget.tile

        # Ignorar peças bloqueadas
        if not self.logic.is_tile_free(tile):
            return

        if self.selected_tile_widget is None:
            # Primeira seleção
            self.selected_tile_widget = tile_widget
            tile_widget.selected = True

        elif self.selected_tile_widget is tile_widget:
            # Clicou na mesma peça → desselecionar
            tile_widget.selected = False
            self.selected_tile_widget = None

        else:
            # Segunda seleção
            prev_tw = self.selected_tile_widget
            prev_tile = prev_tw.tile

            if self.logic.try_match(prev_tile, tile):
                # Match bem-sucedido!
                prev_tw.selected = False
                self.selected_tile_widget = None
                self.pairs_matched += 1
                self._update_status()

                # Atualizar visuais
                self.board.update_tile_states()

                # Checar vitória
                if self.logic.is_won():
                    Clock.schedule_once(self._show_win_popup, 0.4)
                elif not self.logic.has_moves():
                    Clock.schedule_once(self._show_no_moves_popup, 0.4)
            else:
                # Não é match — trocar seleção
                prev_tw.selected = False
                tile_widget.selected = True
                self.selected_tile_widget = tile_widget

    def _update_status(self):
        total_pairs = len(self.logic.tiles) // 2
        self.status_label.text = f'Pares: {self.pairs_matched} / {total_pairs}'

    # ==============================================================
    # Botões
    # ==============================================================

    def _on_reset(self, *args):
        """Resetar o nível (novo jogo)."""
        self._start_game()

    def _on_hint(self, *args):
        """Destacar uma dica (par disponível) por 2 segundos."""
        hint = self.logic.find_hint()
        if hint:
            t1, t2 = hint
            self.board.highlight_hint(t1, t2)
            Clock.schedule_once(lambda dt: self.board.clear_selection(), 2.0)
        else:
            self._show_no_moves_popup()

    def _on_shuffle(self, *args):
        """Embaralhar as peças restantes."""
        self.selected_tile_widget = None
        self.logic.shuffle()
        self.board.logic = self.logic
        self.board.rebuild()

    # ==============================================================
    # Popups
    # ==============================================================

    def _show_win_popup(self, *args):
        """Popup de vitória."""
        content = BoxLayout(orientation='vertical', padding=dp(16), spacing=dp(12))
        content.add_widget(Label(
            text='🎉 Parabéns! 🎉\nVocê completou o tabuleiro!',
            font_size=dp(18),
            halign='center',
            color=(1, 0.9, 0.3, 1),
        ))
        btn = Button(
            text='Jogar de Novo',
            size_hint_y=None,
            height=dp(44),
            background_color=(0.2, 0.7, 0.4, 1),
        )
        content.add_widget(btn)

        popup = Popup(
            title='Vitória!',
            content=content,
            size_hint=(0.7, 0.4),
            auto_dismiss=False,
        )
        btn.bind(on_press=lambda *a: (popup.dismiss(), self._start_game()))
        popup.open()

    def _show_no_moves_popup(self, *args):
        """Popup quando não há mais jogadas disponíveis."""
        content = BoxLayout(orientation='vertical', padding=dp(16), spacing=dp(12))
        content.add_widget(Label(
            text='😿 Sem jogadas disponíveis!',
            font_size=dp(16),
            halign='center',
            color=(1, 0.6, 0.3, 1),
        ))

        btn_bar = BoxLayout(
            orientation='horizontal',
            size_hint_y=None,
            height=dp(44),
            spacing=dp(8),
        )
        btn_shuffle = Button(
            text='Embaralhar',
            background_color=(0.2, 0.7, 0.4, 1),
        )
        btn_reset = Button(
            text='Reset',
            background_color=(0.3, 0.5, 0.8, 1),
        )
        btn_bar.add_widget(btn_shuffle)
        btn_bar.add_widget(btn_reset)
        content.add_widget(btn_bar)

        popup = Popup(
            title='Sem Jogadas',
            content=content,
            size_hint=(0.7, 0.4),
            auto_dismiss=False,
        )
        btn_shuffle.bind(on_press=lambda *a: (popup.dismiss(), self._on_shuffle()))
        btn_reset.bind(on_press=lambda *a: (popup.dismiss(), self._start_game()))
        popup.open()


# ==============================================================
# Entry point
# ==============================================================

if __name__ == '__main__':
    MahjongApp().run()
