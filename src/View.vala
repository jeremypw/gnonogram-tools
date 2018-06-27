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

namespace GnonogramTools {
public class View : Gtk.ApplicationWindow {

/**PUBLIC**/

    /**PRIVATE**/
    /* ----------------------------------------- */
    construct {
        resizable = true;
        set_position (Gtk.WindowPosition.CENTER);
        var header_bar = new Gtk.HeaderBar ();
        header_bar.get_style_context ().add_class ("default-decoration");
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        var main_stack = new Gtk.Stack ();
        var clue_entry = new ClueEntryView ();
        var label2 = new Gtk.Label ("Hello 2");

        main_stack.add_titled (clue_entry, "clue-entry", "Clue Entry");
        main_stack.add_titled (label2, "img2gno", "Convert Image");

        var stack_sidebar = new Gtk.StackSidebar ();
        stack_sidebar.stack = main_stack;

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.add1 (stack_sidebar);
        paned.add2 (main_stack);

        add (paned);
        set_default_size (900, 600);
        set_size_request (750, 500);
        set_titlebar (header_bar);
        title = _("Gnonogram Tools for Elementary");
    }
}
}
