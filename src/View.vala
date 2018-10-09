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

    private Gtk.Stack main_stack;

    construct {
        resizable = true;
        set_position (Gtk.WindowPosition.CENTER);
        var header_bar = new Gtk.HeaderBar ();
        header_bar.get_style_context ().add_class ("default-decoration");
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        add (paned);
        set_default_size (900, 600);
        set_size_request (750, 500);
        set_titlebar (header_bar);
        title = _("Gnonogram Tools for Elementary");

        main_stack = new Gtk.Stack ();
        var clue_entry = new ClueEntryView (this);
        var image_converter = new Img2GnoView (this);
        var tool3 = new DummyTool ("Hello 3", "Print gnonogram");

        main_stack.add_titled (clue_entry, "clue-entry", clue_entry.description);
        main_stack.add_titled (image_converter, "img2gno", image_converter.description);
        main_stack.add_titled (tool3, "printgno", tool3.description);

        var stack_sidebar = new Gtk.StackSidebar ();
        stack_sidebar.stack = main_stack;


        paned.add1 (stack_sidebar);
        paned.add2 (main_stack);


    }

    public bool quit () {
        /* Children should save state (if necessary) when no visible child */
        return ((ToolInterface)(main_stack.get_visible_child ())).quit ();
    }

    private class DummyTool : Gtk.Label, GnonogramTools.ToolInterface {
        public string description {get; set construct;}

        public DummyTool (string message, string description) {
            Object (
                label: message,
                description: description
            );
        }
    }
}
}
