/* Copyright (C) 2010-2018  Jeremy Wootten
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
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */

public class Gnonograms.GradeChooser : Gnonograms.AppSetting {
    Gtk.ComboBoxText cb;
    Gtk.Label heading;
    public override uint @value {
        get {
            return (uint)(int.parse (cb.active_id));
        }

        set {
            cb.active_id = value.clamp (MIN_GRADE, Difficulty.MAXIMUM).to_string ();
        }
    }

    construct {
        cb = new Gtk.ComboBoxText ();

        foreach (Difficulty d in Difficulty.all_human ()) {
            cb.append (((uint)d).to_string (), d.to_string ());
        }

        cb.expand = false;
        heading = new Gtk.Label (_("Difficulty"));
    }

    public override Gtk.Label get_heading () {
        return heading;
    }

    public override Gtk.Widget get_chooser () {
        return cb;
    }
}
