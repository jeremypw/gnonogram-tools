/* Controller class for gnonogram-tools - creates model and view, handles user input and settings.
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
const string STATE_SCHEMA = "com.github.jeremypw.gnonogram-tools.saved-state";

public class Controller : GLib.Object {
    private View view;
    private GLib.Settings? saved_state = null;

/** PUBLIC SIGNALS, PROPERTIES, FUNCTIONS AND CONSTRUCTOR **/
    public signal void quit_app ();
    public Gtk.Window window {get {return (Gtk.Window)view;}}

    construct {
        view = new View ();

        var schema_source = GLib.SettingsSchemaSource.get_default ();
        if (schema_source.lookup (STATE_SCHEMA, true) != null) {
            saved_state = new Settings (STATE_SCHEMA);
        } else {
            warning ("No settings schemas found - will not save settings or state");
        }
    }

    public Controller () {
        view.show_all ();
        view.present ();
    }

    public void quit () {
        quit_app ();
    }

/** PRIVATE **/
}
}
