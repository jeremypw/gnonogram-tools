public class GnonogramTools.ClueEntryView : Gtk.Grid {
    construct {
        column_spacing = 12;
        row_spacing = 6;
        margin = 6;
        column_homogeneous = true;

        var rows_setting = new Gnonograms.ScaleGrid (_("Rows"));
        var cols_setting = new Gnonograms.ScaleGrid (_("Columns"));
        rows_setting.set_value (10);
        cols_setting.set_value (10);

        var rows_grid = new DimensionGrid (rows_setting);
        var cols_grid = new DimensionGrid (cols_setting);

        var row_entry = new ClueEntryGrid (10);
        var col_entry = new ClueEntryGrid (10);

        attach (rows_grid, 0, 0, 1, 1);
        attach (cols_grid, 1, 0, 1, 1);
        attach (row_entry, 0, 1, 1, 1);
        attach (col_entry, 1, 1, 1, 1);

        rows_setting.value_changed.connect ((val) => {
            row_entry.update_n_entries ((int)val);
        });

        cols_setting.value_changed.connect ((val) => {
            col_entry.update_n_entries ((int)val);
        });
    }

    private class ClueEntryGrid : Gtk.ScrolledWindow  {
        private Gtk.Grid grid;
        private int n_entries;

        construct {
            grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 3;
            grid.margin = 6;
            grid.expand = true;
            add (grid);
        }

        public ClueEntryGrid (uint entries) {
            for (int i = 1; i <= entries; i++) {
                grid.attach (new Gtk.Label (i.to_string ()), 0, i - 1, 1, 1);
                var entry = new Gtk.Entry ();
                entry.hexpand = true;
                grid.attach (entry, 1, i - 1, 1, 1);
            }
        }

        public void update_n_entries (int _entries) {
            if (_entries == n_entries ||
                _entries > Gnonograms.MAXSIZE ||
                _entries < Gnonograms.MINSIZE) {

                return;
            }

            if (_entries > n_entries) {
                for (int i = n_entries; i <= _entries; i++) {
                    grid.attach (new Gtk.Label (i.to_string ()), 0, i - 1, 1, 1);
                    var entry = new Gtk.Entry ();
                    entry.hexpand = true;
                    grid.attach (entry, 1, i - 1, 1, 1);
                }

                n_entries = _entries;
            } else {
                while (n_entries > _entries) {
                    grid.remove_row (n_entries - 1);
                    n_entries--;
                }
            }

            grid.show_all ();
        }
    }

    private class DimensionGrid : Gtk.Grid {
        construct {
            expand = false;
            halign = Gtk.Align.CENTER;
        }

        public DimensionGrid (Gnonograms.AppSetting setting) {
            add (setting.get_heading ());
            add (setting.get_chooser ());
        }
    }
}