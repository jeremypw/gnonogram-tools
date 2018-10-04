public class GnonogramTools.ClueEntryView : Gtk.Grid, GnonogramTools.ToolInterface {
    const string EDITOR_SETTINGS_SCHEMA = "com.github.jeremypw.gnonogram-tools.clue-editor.settings";
    const string EDITOR_STATE_SCHEMA = "com.github.jeremypw.gnonogram-tools.clue-editor.saved-state";
    const string UNSAVED_FILENAME = "ClueEditor" + Gnonograms.GAMEFILEEXTENSION;

    private ClueEntryGrid row_entry;
    private ClueEntryGrid col_entry;
    private Gnonograms.ScaleGrid rows_setting;
    private Gnonograms.ScaleGrid cols_setting;
    private Gtk.Button save_button;
    private Gtk.Button load_button;
    private Gtk.Button clear_button;
    private Gtk.MenuButton solve_button;
    private Gtk.Entry name_entry;

    private GLib.Settings? settings = null;
    private GLib.Settings? saved_state = null;

    private string? temporary_game_path = null;
    private string current_game_path = "";

    public Gnonograms.Difficulty grade {get; private set; default = Gnonograms.Difficulty.UNDEFINED;}

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
            var w = get_toplevel ();
            if (w is Gtk.Window) {
                return (Gtk.Window)w;
            }

            return null;
        }
    }

    private Gnonograms.Model model;
    private Gnonograms.CellGrid solution_grid;
    private Gtk.AspectFrame solution_frame;
    private Gtk.Popover solution_popover;
    public string description {get; set construct;}

    construct {
        description = _("Clue Entry");

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

        var grade_label = new Gtk.Label ("");

        rows_setting = new Gnonograms.ScaleGrid (_("Rows"));
        cols_setting = new Gnonograms.ScaleGrid (_("Columns"));

        var rows_grid = new DimensionGrid (rows_setting);
        var cols_grid = new DimensionGrid (cols_setting);

        row_entry = new ClueEntryGrid ();
        col_entry = new ClueEntryGrid ();

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        load_button = new Gtk.Button.with_label (_("Load"));
        save_button = new Gtk.Button.with_label (_("Save"));
        clear_button = new Gtk.Button.with_label (_("New Puzzle"));
        solve_button = new Gtk.MenuButton ();
        solve_button.image = null;
        solve_button.label = _("Solve");

        model = new Gnonograms.Model ();
        solution_grid = new Gnonograms.CellGrid (model);
        model.game_state = Gnonograms.GameState.SETTING;

        solution_grid.draw_only = true;
        solution_grid.visible = true;
        solution_grid.margin = 12;

        solution_frame = new Gtk.AspectFrame (null, 0.5f, 0.5f, 1.0f, false);
        solution_frame.add (solution_grid);
        solution_frame.show_all ();

        solution_popover = new Gtk.Popover (null);
        solution_popover.add (solution_frame);
        solve_button.set_popover (solution_popover);

        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        bbox.add (load_button);
        bbox.add (save_button);
        bbox.add (clear_button);
        bbox.add (solve_button);

        attach (name_grid, 0, 0, 1, 1);
        attach (grade_label, 1, 0, 1, 1);
        attach (rows_grid, 0, 1, 1, 1);
        attach (cols_grid, 1, 1, 1, 1);
        attach (row_entry, 0, 2, 1, 1);
        attach (col_entry, 1, 2, 1, 1);
        attach (bbox, 0, 4, 2, 1);

        notify["grade"].connect (() => {
            if (grade == Gnonograms.Difficulty.UNDEFINED) {
                grade_label.label = "";
            } else {
                grade_label.label = grade.to_string ();
            }
        });

        rows_setting.value_changed.connect ((val) => {
            on_dimension_changed (row_entry, col_entry, val);
        });

        cols_setting.value_changed.connect ((val) => {
            on_dimension_changed (col_entry, row_entry, val);
        });

        row_entry.changed.connect (() => {
            clear_model ();
        });

        col_entry.changed.connect (() => {
            clear_model ();
        });

        save_button.clicked.connect (() => {save_game ();});
        load_button.clicked.connect (() => {load_game ();});
        clear_button.clicked.connect (() => {
            clear_game ();
            clear_current_game_path ();
        });

        solve_button.clicked.connect ( () => {
            solve_game ();
        });

        realize.connect (() => {
            row_entry.update_n_entries ((int)(rows_setting.get_value ()));
            col_entry.update_n_entries ((int)(cols_setting.get_value ()));
        });

        size_allocate.connect (set_solution_grid_size);

        restore_settings ();
    }

    private void set_solution_grid_size () {
        if (solution_frame.ratio > 1) {
            var w = this.get_allocated_width ();
            solution_grid.set_size_request (w, (int) (w / solution_frame.ratio));
        } else {
            var h = this.get_allocated_height ();
            solution_grid.set_size_request ((int)(h * solution_frame.ratio), h);
        }
    }

    private void restore_settings () {
        string data_home_folder_current = Path.build_path (Path.DIR_SEPARATOR_S,
                                                           Environment.get_user_data_dir (),
                                                           "gnonogram-tools",
                                                           "unsaved"
                                                           );
        File file;
        try {
            file = File.new_for_path (data_home_folder_current);
            file.make_directory_with_parents (null);
        } catch (GLib.Error e) {
            if (!(e is IOError.EXISTS)) {
                warning ("Could not make %s - %s",file.get_uri (), e.message);
            }
        }

        temporary_game_path = Path.build_path (Path.DIR_SEPARATOR_S, data_home_folder_current,
                                               UNSAVED_FILENAME);

        var schema_source = GLib.SettingsSchemaSource.get_default ();
        if (schema_source.lookup (EDITOR_SETTINGS_SCHEMA, true) != null &&
            schema_source.lookup (EDITOR_STATE_SCHEMA, true) != null) {

            settings = new Settings (EDITOR_SETTINGS_SCHEMA);
            saved_state = new Settings (EDITOR_STATE_SCHEMA);
        } else {
            warning ("No clue editor schemas found - will not save settings or state");
        }

        uint rows = 10;
        uint cols = 10;

        if (settings != null) {
            rows = settings.get_uint ("rows");
            cols = settings.get_uint ("columns");
        }

        rows_setting.set_value (rows);
        cols_setting.set_value (cols);

        if (saved_state != null) {
            current_game_path = saved_state.get_string ("current-game-path");
            if (current_game_path != "") {
                load_game (current_game_path);
            }
        }

        if (current_game_path == "" && temporary_game_path != null) {
            load_game (temporary_game_path);
        }
    }

    public bool quit () {
        settings.set_uint ("rows",  rows_setting.get_value ());
        settings.set_uint ("columns",  cols_setting.get_value ());


        if (temporary_game_path != null && current_game_path == "") {
            try {
                var current_game = File.new_for_path (temporary_game_path);
                current_game.@delete ();
            } catch (GLib.Error e) {
            } finally {
                /* Save solution and current state */
                save_game (temporary_game_path);
            }
        }

        return false;
    }

    private void on_dimension_changed (ClueEntryGrid changed, ClueEntryGrid other, uint new_val) {
        changed.update_n_entries ((int)new_val);
        other.size = new_val;
        grade = Gnonograms.Difficulty.UNDEFINED;
        clear_model ();
        var cols = cols_setting.get_value ();
        var rows = rows_setting.get_value ();
        model.dimensions = { cols, rows };
        solution_frame.ratio =  (float)(cols) / (float)(rows);
        set_solution_grid_size ();
    }

    private void clear_model () {
        model.clear ();
    }

    private bool check_totals () {
        var row_total = row_entry.get_total ();
        var col_total = col_entry.get_total ();
        return row_total == col_total;
    }

    private void save_game (string? path = null) {
        if (path == null && !valid && !confirm_save_invalid ()) {
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
                                                    null, path, game_name,
                                                    dim,
                                                    row_clues,
                                                    col_clues,
                                                    null);
            filewriter.is_readonly = false;
            filewriter.difficulty = grade;

            row_entry.count_errors ();
            col_entry.count_errors ();

            filewriter.solution = null;
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

    private void load_game (string? game_path = null) {
        Gnonograms.Filereader? reader = null;
        try {
            File? game_file = null;
            if (game_path != null) {
                game_file = File.new_for_path (game_path);
                if (!game_file.query_exists ()) {
                    return;
                }
            }

            string? load_dir_path = null;
            if (game_path == null && settings != null) {
                load_dir_path = settings.get_string ("game-dir");
            }

            reader = new Gnonograms.Filereader (window, load_dir_path, game_file);

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

            model.dimensions = { col_clues.length, row_clues.length };

            if (reader.name == Gnonograms.UNTITLED_NAME) {
                name_entry.text = "";
            } else {
                name_entry.text = reader.name;
            }

            grade = reader.difficulty;

            /* Must do after clearing game */
            if (game_path != temporary_game_path && reader.game_file != null) {
                var dir = reader.game_file.get_parent ();
                if (dir != null && settings != null) {
                    settings.set_string ("game-dir", dir.get_uri ());
                }

                if (saved_state != null) {
                    saved_state.set_string ("current-game-path", reader.game_file.get_uri ());
                }
            }
        } catch (IOError e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = game_path ?? "";
                if (reader != null && reader.game_file != null) {
                    basename = reader.game_file.get_basename ();
                }
                Gnonograms.Utils.show_error_dialog (_("Unable to load %s").printf (basename), e.message, window);
            }
        }
    }

    private void solve_game () {
        if (!valid) {
            Gnonograms.Utils.show_error_dialog (_("Cannot solve"), _("The clues are invalid"), window);
            grade = Gnonograms.Difficulty.UNDEFINED;
            return;
        }

        var dim = Gnonograms.Dimensions ();
        dim.height = rows_setting.get_value ();
        dim.width = cols_setting.get_value ();
        var solver = new Gnonograms.Solver (dim);
        solver.configure_from_grade (Gnonograms.Difficulty.COMPUTER);
        var diff = solver.solve_clues (row_entry.get_clues (), col_entry.get_clues ());

        string msg = "";
        if (!solver.state.solved ()) {
            clear_model ();
            msg = _("No solution found");
            Gnonograms.Utils.show_dlg (msg, Gtk.MessageType.INFO, null, window);
        } else {
            model.set_solution_from_array (solver.solution);
        }

        grade = diff;
    }

    private void clear_game () {
        row_entry.clear ();
        col_entry.clear ();
        name_entry.text = "";
        grade = Gnonograms.Difficulty.UNDEFINED;
        clear_model ();
    }

    private void clear_current_game_path () {
        if (saved_state != null) {
            saved_state.set_string ("current-game-path", "");
        }
    }

    private class ClueEntryGrid : Gtk.ScrolledWindow  {
        private Gtk.Grid grid;
        private int n_entries = 0;

        public uint size {get; set;}
        public uint errors {get; private set; default = 0;}
        private int last_total = -1;

        public signal void changed ();

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

                    entry.focus_out_event.connect (() => {
                        if (get_total () != last_total) {
                            if (last_total >= 0) {
                                changed ();
                            }

                            last_total = (int)get_total ();
                        }
                        return false;
                    });

                    entry.size = size;
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

        public void count_errors () {
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
                if (entry.text != "" && entry.text != "0" ) {
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

            count_errors ();
            last_total = (int)get_total ();
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
        public uint extent {
            get {
                var blocks = Gnonograms.Utils.block_array_from_clue (text);
                int e = 0;
                foreach (int b in blocks) {
                    e += b;
                }

                return (uint)e;
            }
        }

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
                    secondary_icon_name = "";
                }
            });

            notify["text"].connect (() => {
                valid = text == "" || text == "0" || (check_parse () && check_block_extent ());
            });

            key_press_event.connect (on_key_press_event);
        }

        private bool check_block_extent () {
            bool res = extent <= size;
            err_message = res ? "" : _("Block extent (%u) exceeds available space (%u)").printf (extent, size);
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
