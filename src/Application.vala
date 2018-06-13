/* Entry point for gnonogram-tools  - initializes application and launches game
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

public class GnonogramTools.App : Gtk.Application {
    private Controller controller;

    construct {
        flags = ApplicationFlags.HANDLES_OPEN;

        SimpleAction quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (controller != null) {
                controller.quit ();
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Ctrl>q"});
    }

    public override void startup () {
        base.startup ();
    }

    public override void activate () {
        controller = new Controller ();
        this.add_window (controller.window);

        controller.quit_app.connect (quit);
    }
}

public static GnonogramTools.App get_app () {
    return Application.get_default () as GnonogramTools.App;
}

public static int main (string[] args) {
    var app = new GnonogramTools.App ();
    return app.run (args);
}
