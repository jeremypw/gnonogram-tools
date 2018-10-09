public class GnonogramTools.Img2GnoView : Gtk.Grid, GnonogramTools.ToolInterface {
    const string IMG2GNO_SETTINGS_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.settings";
    const string IMG2GNO_STATE_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.saved-state";
    const string UNSAVED_FILENAME = "Img2Gno" + Gnonograms.GAMEFILEEXTENSION;

    private Gtk.Entry name_entry;
    private Gnonograms.ScaleGrid rows_setting;
    private Gnonograms.ScaleGrid cols_setting;
    private Gtk.Image image_orig;
    private Gtk.Image image_intermed;
    private Gnonograms.CellGrid model_cellgrid;
    private Gtk.EventBox eb_img;
    private Gdk.Pixbuf? pix_original = null;

    private Gtk.Button save_button;
    private Gtk.Button load_button;
    private Gtk.MenuButton solve_button;

    private GLib.Settings? settings = null;
    private GLib.Settings? saved_state = null;

    private string? temporary_game_path = null;
    private string current_game_path = "";
    private string current_img_path = "";

    private Gnonograms.Model model;
    private GnonogramTools.SolutionPopover solution_popover;

    public string description {get; set construct;}
    public Gtk.Window window { get; construct; }

    construct {
        description = _("Image Converter");
        margin = 24;

        var name_setting = new Gnonograms.TitleEntry ();
        var controls_grid = new GnonogramTools.SettingGrid (name_setting);
        var image_grid = new Gtk.Grid ();

        image_grid.set_size_request (300, -1);
        image_grid.margin = 12;
        image_grid.row_spacing = controls_grid.row_spacing;

        rows_setting = new Gnonograms.ScaleGrid (_("Rows"));
        cols_setting = new Gnonograms.ScaleGrid (_("Columns"));

        controls_grid.add_a_setting (rows_setting);
        controls_grid.add_a_setting (cols_setting);

        load_button = new Gtk.Button.with_label (_("Load Image"));
        save_button = new Gtk.Button.with_label (_("Save Game"));

        solve_button = new Gtk.MenuButton ();
        solve_button.image = null;
        solve_button.label = _("Solve");

        model = new Gnonograms.Model ();
        solution_popover = new GnonogramTools.SolutionPopover (model, this);
        solution_popover.set_position (Gtk.PositionType.TOP);
        solve_button.set_popover (solution_popover);

        image_orig = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        eb_img = new Gtk.EventBox ();
        eb_img.add (image_orig);

        image_intermed = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        model_cellgrid = new Gnonograms.CellGrid (model);
        model.game_state = Gnonograms.GameState.SETTING;
        model_cellgrid.draw_only = true;

        model_cellgrid.set_size_request (200, 200);

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);


        bbox.add (load_button);
        bbox.add (save_button);
        bbox.add (solve_button);
        bbox.margin = 12;

        image_grid.attach (eb_img, 0, 0, 1, 1);
        image_grid.attach (image_intermed, 0, 1, 1, 1);
        image_grid.attach (model_cellgrid, 0, 2, 1, 1);

        attach (controls_grid, 0, 0, 1, 1);
        attach (image_grid, 1, 0, 1, 1);
        attach (bbox, 0, 1, 2, 1);


        rows_setting.value_changed.connect (on_dimension_changed);
        cols_setting.value_changed.connect (on_dimension_changed);

        save_button.clicked.connect (() => {
            save_game (null, true);
        });

        load_button.clicked.connect (() => {
            load_image ();
        });

        realize.connect (() => {
        });

        restore_settings ();
        show_all ();
    }

    public Img2GnoView (Gtk.Window window) {
        Object (window: window);
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
        if (schema_source.lookup (IMG2GNO_SETTINGS_SCHEMA, true) != null &&
            schema_source.lookup (IMG2GNO_STATE_SCHEMA, true) != null) {

            settings = new Settings (IMG2GNO_SETTINGS_SCHEMA);
            saved_state = new Settings (IMG2GNO_STATE_SCHEMA);
        } else {
            warning ("No image converter schemas found - will not save settings or state");
        }

        uint rows = 10;
        uint cols = 10;

        if (settings != null) {
            rows = settings.get_uint ("rows");
            cols = settings.get_uint ("columns");
        }

        rows_setting.set_value (rows);
        cols_setting.set_value (cols);
    }

    private void on_dimension_changed () {
        var cols = cols_setting.get_value ();
        var rows = rows_setting.get_value ();
        model.dimensions = { cols, rows };
        clear_model ();
    }

    private void clear_model () {
        model.clear ();
    }

    private void save_game (string? path = null, bool save_solution = false) {
        string game_name = name_entry.text != "" ? name_entry.text : Gnonograms.UNTITLED_NAME;

        var dim = Gnonograms.Dimensions ();
        dim.height = rows_setting.get_value ();
        dim.width = cols_setting.get_value ();

        var row_clues = model.get_row_clues ();
        var col_clues = model.get_col_clues ();

        Gnonograms.Filewriter? filewriter = null;

        try {
            filewriter = new Gnonograms.Filewriter (window,
                                                    dim,
                                                    row_clues,
                                                    col_clues,
                                                    null);
            filewriter.is_readonly = false;
            filewriter.difficulty = solution_popover.grade;

            if (save_solution) {
                filewriter.solution = model.copy_solution_data ();
            } else {
                filewriter.solution = null;
            }

            filewriter.write_game_file (null, null, game_name);
        } catch (IOError e) {
            if (!(e is IOError.CANCELLED)) {
                var basename = Path.get_basename (filewriter.game_path);
                Gnonograms.Utils.show_error_dialog (_("Unable to save %s").printf (basename), e.message, window);
            }
        }
    }

    private void load_image (string? path = null) {
        string image_path = path;

        try {
            if (image_path == null) {
                image_path = get_image_filename ();
                if (image_path == null) {
                    return;
                }
            }

            pix_original = new Gdk.Pixbuf.from_file (image_path);
            var scaled_pix = pix_original.scale_simple (200,
                                                        200 * pix_original.height / pix_original.width,
                                                        Gdk.InterpType.HYPER);

            var w = pix_original.width;
            var h = pix_original.height;
            var aspect = (double)h / (double)w;
            Gdk.Pixbuf intermed_pix;
            Gdk.Pixbuf scaled_intermed;

            intermed_pix = convert_luminance (pix_original);
            if (aspect > 1) {
                scaled_intermed = intermed_pix.scale_simple ((int)(50 * 1 / aspect),
                                                          50,
                                                          Gdk.InterpType.HYPER);
            } else {
                scaled_intermed = intermed_pix.scale_simple (50,
                                                          (int)(50 * aspect),
                                                          Gdk.InterpType.HYPER);
            }


            scaled_intermed = scaled_intermed.scale_simple (scaled_intermed.width * 200 / 50,
                                                           scaled_intermed.height * 200 / 50,
                                                           Gdk.InterpType.HYPER);

            image_orig.set_from_pixbuf (scaled_pix);
            image_intermed.set_from_pixbuf (scaled_intermed);
            current_img_path = image_path;
        } catch (GLib.Error e) {
            if (!(e is IOError.CANCELLED)) {
                Gnonograms.Utils.show_error_dialog (_("Unable to load %s").printf (image_path), e.message, window);
            }
        }
    }

    private string get_image_filename() {
        Gnonograms.FilterInfo all = {"All Supported Image Files", {"*.png", "*.bmp", "*.svg"}};
        Gnonograms.FilterInfo png = {"PNG Image files", {"*.png"}};
        Gnonograms.FilterInfo bmp = {"Bitmap Image files", {"*.bmp"}};
        Gnonograms.FilterInfo svg = {"SVG Image Files", {"*.svg"}};
        Gnonograms.FilterInfo[] filterinfos = {all, png, bmp, svg};

        string image_filename = Gnonograms.Utils.get_file_path (window,
                                                                Gnonograms.FileChooserAction.OPEN,
                                                                _("Select an image to convert"),
                                                                filterinfos,
                                                                Environment.get_current_dir(),
                                                                null);
        return image_filename;
    }

    private bool solve_game (bool silent = false) {
        var dim = Gnonograms.Dimensions ();
        dim.height = rows_setting.get_value ();
        dim.width = cols_setting.get_value ();
        var solver = new Gnonograms.Solver (dim);
        solver.configure_from_grade (Gnonograms.Difficulty.COMPUTER);
        var diff = solver.solve_clues (model.get_row_clues (), model.get_col_clues ());

        solution_popover.grade = diff;

        string msg = "";
        if (!solver.state.solved ()) {
            if (!silent) {
                msg = _("No solution found");
                Gnonograms.Utils.show_dlg (msg, Gtk.MessageType.INFO, null, window);
            }
            return false;
        } else {
            return true;
        }
    }

    private Gdk.Pixbuf convert_luminance (Gdk.Pixbuf orig_pix) {
        if (orig_pix.bits_per_sample != 8 || orig_pix.n_channels < 3) {
            Gnonograms.Utils.show_error_dialog (_("Cannot convert this image format"),
                                                _("Need 8 bits per channel and at least 3 channels"),
                                                window);
            return orig_pix;
        }

        Gdk.Pixbuf converted_pix;
        bool has_alpha = orig_pix.has_alpha;
        int width = orig_pix.width;
        int height = orig_pix.height;
        int rowstride = orig_pix.rowstride;

        converted_pix = orig_pix.copy();

        unowned uint8[] pix = converted_pix.get_pixels ();
        double[] luminances = new double[width * height];

        int idx = 0;
        int ptr = 0;
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double alphas = has_alpha ? (double)pix[idx + 3] / 255.0 : 1;
                double rs = (double)pix[idx] / 255.0 * alphas;
                double gs = (double)pix[idx + 1] / 255.0 * alphas;
                double bs = (double)pix[idx + 2] / 255.0 * alphas;
                double luminance = 0.2126 * rs + 0.7152 * gs + 0.0722 * bs - alphas;
                luminances[ptr] = luminance;
                idx += orig_pix.n_channels;
                ptr++;
            }
        }

        double min_luminance = 10000.0;
        double max_luminance = -10000.0;
        foreach (double l in luminances) {
            if (min_luminance > l) {
                min_luminance = l;
            }

            if (max_luminance < l) {
                max_luminance = l;
            }
        }



        /* Convert luminace to grayscale */
        double range = max_luminance - min_luminance;
        ptr = 0;
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double l = luminances[ptr];
                luminances[ptr] = (l - min_luminance) * 255.0 / range;
                ptr++;
            }
        }

        idx = 0;
        ptr = 0;
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                var l = luminances[ptr];
                pix[idx] = (uint8)l;
                pix[idx + 1] = (uint8)l;
                pix[idx + 2] = (uint8)l;
                if (has_alpha) {
                    pix[idx + 3] = 255;
                }

                idx += orig_pix.n_channels;
                ptr++;
            }
        }

        return converted_pix;
    }
}
