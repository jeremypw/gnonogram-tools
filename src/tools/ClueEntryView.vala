public class GnonogramTools.ClueEntryView : Gtk.Grid {

    construct {
        var dimension_label = new Gtk.Label ("Dimension setting");
        var rows_setting = new DimensionSetting ("Rows");
        var cols_setting = new DimensionSetting ("Columns");
        var row_entry = new ClueEntryGrid (10);
        var col_entry = new ClueEntryGrid (10);

        attach (rows_setting, 0, 0, 1, 1);
        attach (cols_setting, 1, 0, 1, 1);
        attach (row_entry, 0, 1, 1, 1);
        attach (col_entry, 1, 1, 1, 1);

        column_spacing = 12;
        row_spacing = 6;
        margin = 6;

        column_homogeneous = true;
        expand = true;
    }

    private class ClueEntryGrid : Gtk.Grid {

        construct {
            column_spacing = 6;
            margin = 6;
        }

        public ClueEntryGrid (uint entries) {
            for (int i = 1; i <= entries; i++) {
                attach (new Gtk.Label (i.to_string ()), 0, i - 1, 1, 1);
                var entry = new Gtk.Entry ();
                entry.hexpand = true;
                attach (entry, 1, i - 1, 1, 1);
            }
        }
    }

    private class DimensionSetting : Gtk.Grid {
        construct {
            column_spacing = 6;
            halign = Gtk.Align.CENTER;
        }

        public DimensionSetting (string heading) {
            attach (new Gtk.Label (heading), 0, 0, 1, 1);
            var adjustment = new Gtk.Adjustment (10.0, 10.0, 50.0, 5.0, 5.0, 0.0);
            var scale = new Gtk.SpinButton (adjustment, 5.0, 0);
            attach (scale, 1, 0, 1, 1);
        }
    }
}