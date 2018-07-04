public class GnonogramTools.ClueEntryView : Gtk.Grid {
    private ClueEntryGrid row_entry;
    private ClueEntryGrid col_entry;
    private Gnonograms.ScaleGrid rows_setting;
    private Gnonograms.ScaleGrid cols_setting;
    private Gtk.Button save_button;
    private Gtk.Button load_button;
    private Gtk.Button clear_button;
    private Gtk.Entry name_entry;

    private bool valid {
        get {
            if (row_entry == null) {
                return false;
            }

            return row_entry.errors + col_entry.errors == 0 && check_totals ();
        }
    }

    private Gtk.Window? window {
        get {
            return (Gtk.Window)get_toplevel ();
        }
    }

    construct {
        column_spacing = 12;
        row_spacing = 6;
        margin = 6;
        column_homogeneous = true;

        var name_grid = new Gtk.Grid ();
        name_grid.column_spacing = 6;
        name_grid.margin = 12;

        var name_label = new Gtk.Label (_("Name"));
        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Enter the title of the game");
        name_entry.hexpand = true;

        name_grid.add (name_label);
        name_grid.add (name_entry);

        rows_setting = new Gnonograms.ScaleGrid (_("Rows"));
        cols_setting = new Gnonograms.ScaleGrid (_("Columns"));

        var rows_grid = new DimensionGrid (rows_setting);
        var cols_grid = new DimensionGrid (cols_setting);

        row_entry = new ClueEntryGrid ();
        col_entry = new ClueEntryGrid ();

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        load_button = new Gtk.Button.with_label (_("Load"));
        save_button = new Gtk.Button.with_label (_("Save"));
        clear_button = new Gtk.Button.with_label (_("Clear"));
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        bbox.add (load_button);
        bbox.add (save_button);
        bbox.add (clear_button);

        attach (name_grid, 0, 0, 2, 1);
        attach (rows_grid, 0, 1, 1, 1);
        attach (cols_grid, 1, 1, 1, 1);
        attach (row_entry, 0, 2, 1, 1);
        attach (col_entry, 1, 2, 1, 1);
        attach (bbox, 0, 3, 2, 1);

        rows_setting.value_changed.connect ((val) => {
            row_entry.update_n_entries ((int)val);
            clear_game ();
            col_entry.size = val;
        });

        cols_setting.value_changed.connect ((val) => {
            col_entry.update_n_entries ((int)val);
            clear_game ();
            row_entry.size = val;
        });

        save_button.clicked.connect (save_game);
        load_button.clicked.connect (load_game);
        clear_button.clicked.connect (clear_game);

        realize.connect (() => {
            row_entry.update_n_entries ((int)(rows_setting.get_value ()));
            col_entry.update_n_entries ((int)(cols_setting.get_value ()));
        });

        rows_setting.set_value (10);
        cols_setting.set_value (10);
    }

    private bool check_totals () {
        var row_total = row_entry.get_total ();
        var col_total = col_entry.get_total ();

        return row_total == col_total;
    }

    private bool check_clear () {
        var row_total = row_entry.get_total ();
        var col_total = col_entry.get_total ();

        return row_total + col_total == 0;
    }

    private void save_game () {
        if (!valid && !confirm_save_invalid ()) {
            return; 
        }

        string game_name = name_entry.text != "" ? name_entry.text : Gnonograms.UNTITLED_NAME;

        var dim = Gnonograms.Dimensions ();
        dim.height = rows_setting.get_value ();
        dim.width = cols_setting.get_value ();

        var row_clues = row_entry.get_clues ();
        var col_clues = col_entry.get_clues ();
        Gnonograms.Filewriter? filewriter = null;

        try {
            filewriter = new Gnonograms.Filewriter (window,
                                                    null, null, game_name,
                                                    dim,
                                                    row_clues,
                                                    col_clues,
                                                    null, false);
            filewriter.is_readonly = false;
            filewriter.write_game_file ();
        } catch (IOError e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = Path.get_basename (filewriter.game_path);
                Gnonograms.Utils.show_error_dialog (_("Unable to save %s").printf (basename), e.message, window);
            }
        }
    }

    private bool confirm_save_invalid () {
        string secondary_text = "";
        if (row_entry.errors + col_entry.errors > 0) {
            secondary_text = _("There is one or more invalid clues");
        } else if (!check_totals ()) {
            secondary_text = _("Total row blocks not equal to total column blocks");
        }

        return Gnonograms.Utils.show_confirm_dialog (_("Save an invalid game?"), secondary_text, window);
    }

    private void load_game () {
        Gnonograms.Filereader? reader = null;

        try {
            reader = new Gnonograms.Filereader (window, null, null, true);
            if (!reader.has_row_clues || !reader.has_col_clues) {
                Gnonograms.Utils.show_error_dialog (_("Cannot load"), reader.err_msg, window);
                return;
            }

            var row_clues = reader.row_clues;
            var col_clues = reader.col_clues;

            rows_setting.set_value (row_clues.length);
            cols_setting.set_value (col_clues.length);

            row_entry.set_clues (row_clues);
            col_entry.set_clues (col_clues);

            if (reader.name == Gnonograms.UNTITLED_NAME) {
                name_entry.text = "";
            } else {
                name_entry.text = reader.name;
            }
        } catch (IOError e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = reader.game_file.get_basename ();
                Gnonograms.Utils.show_error_dialog (_("Unable to load %s").printf (basename), e.message, window);
            }
        }
    }

    private void clear_game () {
        if (check_clear () ||
            Gnonograms.Utils.show_confirm_dialog (_("Delete existing clues?"), null, window)) {

            row_entry.clear ();
            col_entry.clear ();
        }
    }

    private class ClueEntryGrid : Gtk.ScrolledWindow  {
        private Gtk.Grid grid;
        private int n_entries = 0;

        public uint size {get; set;}
        public uint errors {get; private set; default = 0;}

        construct {
            grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 3;
            grid.margin = 6;
            grid.expand = true;
            add (grid);

            notify["size"].connect (update_size);
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

                    entry.notify["valid"].connect (count_errors);
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

        private void update_size () {
            for (int i = 0; i < n_entries; i++) {
                var entry = (ClueEntry)(grid.get_child_at (1, i));
                if (entry != null) {
                    entry.size = this.size;
                }
            }
        }

        private void count_errors () {
            uint _errors = 0;
            for (int i = 0; i < n_entries; i++) {
                var entry = (ClueEntry)(grid.get_child_at (1, i));
                if (entry != null && !entry.valid) {
                    _errors++;
                }
            }

            errors = _errors;
        }

        public uint get_total () {
            uint _total = 0;
            for (int i = 0; i < n_entries; i++) {
                var entry = (ClueEntry)(grid.get_child_at (1, i));
                if (entry != null) {
                    _total += entry.extent;
                }
            }

            return _total;
        }

        public string[] get_clues () {
            var clues = new string[n_entries];
            for (int i = 0; i < n_entries; i++) {
                var entry = (ClueEntry)(grid.get_child_at (1, i));
                clues[i] = entry != null ? entry.text : "0";
            }

            return clues;
        }

        public void set_clues (string[] clues) {
            for (int i = 0; i < n_entries; i++) {
                var entry = (ClueEntry)(grid.get_child_at (1, i));
                entry.text = clues[i];
            }
        }

        public void clear () {
            for (int i = 0; i < n_entries; i++) {
                var entry = (ClueEntry)(grid.get_child_at (1, i));
                entry.text = "0";
            }
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
        public bool valid {get; set; default = true;}
        public uint extent {get; set; default = 0;}

        private string err_message = "";

        construct {
            text = "0";
            placeholder_text = _("Enter clue");
            tooltip_text = _("Enter block lengths separated by commas e.g. 3,1,2,1");
            hexpand = true;
            set_input_purpose (Gtk.InputPurpose.NUMBER);

            notify["size"].connect (() => {
                valid = check_block_extent ();
            });

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

            notify["text"].connect (() => {
                valid = check_parse () && check_block_extent ();
            });

            key_press_event.connect (on_key_press_event);
        }

        private bool check_block_extent () {
            extent = Gnonograms.Utils.blockextent_from_clue (text);
            bool res = extent <= size;
            err_message = res ? "" : _("Block extent (%i) exceeds available space (%u)").printf (extent, size);
            return res;
        }

        private bool check_parse () {
            var blocks = Gnonograms.Utils.block_struct_array_from_clue (text);
            bool res = true;

            if (blocks.size > 1) {
                for (int i = 1; i < blocks.size; i++) {
                    if (blocks[i].length == 0) {
                        res = false;
                    }
                }
            }

            err_message = res ? "" : _("Not a valid clue - zero length block");
            return res;
        }

        private bool on_key_press_event (Gdk.EventKey event) {
            var key = event.keyval;
            var @char = (char)(Gdk.keyval_to_unicode (key));

            if (@char.isalpha ()) {
                return true;
            } else {
                return false;
            }
        }
    }
}
