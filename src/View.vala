/* View class for gnonogram-tools - displays user interface
 * Copyright (C) 2010-2017  Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author:
 *  Jeremy Wootten <jeremywootten@gmail.com>
 */

namespace gnonogram-tools {
/*** The View class manages the header, clue label widgets and the drawing widget under instruction
   * from the controller. It signals user interaction to the controller.
***/
public class View : Gtk.ApplicationWindow {

/**PUBLIC**/

    /**PRIVATE**/
    /* ----------------------------------------- */
    public View () {
    }

    construct {
        resizable = true;
        drawing_with_state = CellState.UNDEFINED;
        header_bar = new Gtk.HeaderBar ();
        header_bar.get_style_context ().add_class ("default-decoration");
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        title = _("Gnonogram Tools for Elementary");
        set_titlebar (header_bar);

        var label = new Gtk.Label ("Hello");
        add (label);
    }
}
}
