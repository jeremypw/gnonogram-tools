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

        var row_entry = new ClueEntryGrid ();
        var col_entry = new ClueEntryGrid ();

        attach (rows_grid, 0, 0, 1, 1);
        attach (cols_grid, 1, 0, 1, 1);
        attach (row_entry, 0, 1, 1, 1);
        attach (col_entry, 1, 1, 1, 1);

        rows_setting.value_changed.connect ((val) => {
            row_entry.update_n_entries ((int)val);
            col_entry.size = val;
        });

        cols_setting.value_changed.connect ((val) => {
            col_entry.update_n_entries ((int)val);
            row_entry.size = val;
        });

        realize.connect (() => {
            row_entry.update_n_entries ((int)(rows_setting.get_value ()));
            col_entry.update_n_entries ((int)(cols_setting.get_value ()));
        });
    }

    private class ClueEntryGrid : Gtk.ScrolledWindow  {
        private Gtk.Grid grid;
        private int n_entries = 0;

        public uint size {get; set;}

        construct {
            grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 3;
            grid.margin = 6;
            grid.expand = true;
            add (grid);

            notify["size"].connect (() => {
                for (int i = 0; i < n_entries; i++) {
                    var entry = (ClueEntry)(grid.get_child_at (1, i - 1));
                    if (entry != null) {
                        entry.size = this.size;
                    }
                }
            });
        }

        public void update_n_entries (int _entries) {
            if (_entries == n_entries ||
                _entries > Gnonograms.MAXSIZE ||
                _entries < Gnonograms.MINSIZE) {

                return;
            }

            if (_entries > n_entries) {
                for (int i = n_entries + 1; i <= _entries; i++) {
                    grid.attach (new Gtk.Label (i.to_string ()), 0, i - 1, 1, 1);
                    var entry = new ClueEntry ();
                    grid.attach (entry, 1, i - 1, 1, 1);

                    var row = i; /* Fix value of 'i' for closure */
                    entry.activate.connect (() => {
                        var next = grid.get_child_at (1, row);
                        if (next != null) {
                            next.grab_focus ();
                        }
                    });
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

    private class ClueEntry : Gtk.Entry {
        public uint size {get; set; default = 10;} /* Size of range connected to clue */
        public bool valid {get; set;}

        private string err_message = "";

        construct {
            text = "0";
            placeholder_text = _("Enter clue");
            tooltip_text = _("Enter block lengths separated by commas e.g. 3,1,2,1");
            hexpand = true;

            notify["size"].connect (check_block_extent);
            activate.connect (check_block_extent);

            notify["valid"].connect (() => {
                if (!valid) {
                    set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning");
                    Idle.add (() => {
                        set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, err_message);
                        return false;
                    });
                } else {
                    set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, null);
                    secondary_icon_name = "";
                }
            });
        }

        private void check_block_extent () {
            int extent = Gnonograms.Utils.blockextent_from_clue (text);
            valid = extent <= size;
            err_message = valid ? "" : _("Block extent (%i) exceeds available space (%u)").printf (extent, size);
        }
    }
}