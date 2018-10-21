public class GnonogramTools.Img2GnoView : Gtk.Grid, GnonogramTools.ToolInterface {
    const string IMG2GNO_SETTINGS_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.settings";
    const string IMG2GNO_STATE_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.saved-state";
    const string UNSAVED_FILENAME = "Img2Gno" + Gnonograms.GAMEFILEEXTENSION;

    private Gtk.Entry name_entry;
    private Gnonograms.ScaleGrid rows_setting;
    private Gnonograms.ScaleGrid cols_setting;
    private Gnonograms.ScaleGrid edge_setting;
    private Gnonograms.ScaleGrid black_setting;
    private Gtk.Image image_orig;
    private Gtk.Image image_intermed1;
    private Gtk.Image image_intermed2;
    private uint8[] intermed1_data;
    private uint8[] intermed2_data;
    private uint edge_sens = 50;
    private uint black_thr = 128;
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

        image_grid.set_size_request (300, 600);
        image_grid.margin = 12;
        image_grid.row_spacing = controls_grid.row_spacing;

        rows_setting = new Gnonograms.ScaleGrid (_("Rows"));
        cols_setting = new Gnonograms.ScaleGrid (_("Columns"));
        black_setting = new Gnonograms.ScaleGrid (_("Black sensitivity"));
        edge_setting = new Gnonograms.ScaleGrid (_("Edge threshold"));

        controls_grid.add_a_setting (rows_setting);
        controls_grid.add_a_setting (cols_setting);
        controls_grid.add_a_setting (black_setting);
        controls_grid.add_a_setting (edge_setting);

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
        image_orig.no_show_all = true;
        image_orig.visible = false;
        eb_img = new Gtk.EventBox ();
        eb_img.add (image_orig);

        image_intermed1 = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        image_intermed1.no_show_all = true;
        image_intermed1.visible = false;

        image_intermed2 = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        image_intermed2.no_show_all = true;
        image_intermed2.visible = false;

        model_cellgrid = new Gnonograms.CellGrid (model);
        model.game_state = Gnonograms.GameState.SETTING;
        model_cellgrid.draw_only = true;
        model_cellgrid.no_show_all = true;
        model_cellgrid.visible = false;

        model_cellgrid.set_size_request (200, 200);

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);

        bbox.add (load_button);
        bbox.add (save_button);
        bbox.add (solve_button);
        bbox.margin = 12;

        image_grid.attach (eb_img, 0, 0, 1, 1);
        image_grid.attach (image_intermed1, 0, 1, 1, 1);
        image_grid.attach (image_intermed2, 0, 2, 1, 1);
        image_grid.attach (model_cellgrid, 0, 3, 1, 1);

        attach (controls_grid, 0, 0, 1, 1);
        attach (image_grid, 1, 0, 1, 1);
        attach (bbox, 0, 1, 2, 1);


        rows_setting.value_changed.connect (on_dimension_changed);
        cols_setting.value_changed.connect (on_dimension_changed);
        black_setting.value_changed.connect ((val) => {
            black_thr = (int)(225 - val * 4);
            update_intermed2 ();

        });
        edge_setting.value_changed.connect ((val) => {
            edge_sens = (int)(10 + val * 4);
            update_intermed2 ();
        });

        save_button.clicked.connect (() => {
            save_game (null, true);
        });

        load_button.clicked.connect (() => {
            load_image ();
        });

        realize.connect (() => {
        });

        restore_settings ();
        black_setting.set_value (25);
        edge_setting.set_value (25);
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
        model_cellgrid.visible = false;
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
            image_orig.set_from_pixbuf (scale_pixbuf_for_display (pix_original));
            current_img_path = image_path;
            convert_original_image ();
        } catch (GLib.Error e) {
            if (!(e is IOError.CANCELLED)) {
                Gnonograms.Utils.show_error_dialog (_("Unable to load %s").printf (image_path), e.message, window);
            }
        }
    }

    private Gdk.Pixbuf scale_pixbuf_for_display (Gdk.Pixbuf pix) {
        var w = pix_original.width;
        var h = pix.height;
        var aspect = (double)h / (double)w;
        return pix.scale_simple (200,
                                 (int)(200 * aspect),
                                 Gdk.InterpType.NEAREST);
    }

    private void convert_original_image () {
            update_intermed1 ();
            update_intermed2 ();
            image_orig.visible = true;
            image_intermed1.visible = true;
            image_intermed2.visible = true;
            model_cellgrid.visible = true;
    }

    private void update_intermed1 () {
        intermed1_data = convert_to_grayscale_array (pix_original);
        var intermed1_pix = pixbuf_from_grayscale (intermed1_data, pix_original.width, pix_original.height);
        var scaled_intermed1 = scale_pixbuf_for_display (intermed1_pix);
        image_intermed1.set_from_pixbuf (scaled_intermed1);
    }

    private void update_intermed2 () {
        intermed2_data = convert_edges (intermed1_data, pix_original.width, pix_original.height);
        var intermed2_pix = pixbuf_from_grayscale (intermed2_data, pix_original.width, pix_original.height);
        var scaled_intermed2 = scale_pixbuf_for_display (intermed2_pix);
        image_intermed2.set_from_pixbuf (scaled_intermed2);
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

    private uint8[] convert_to_grayscale_array (Gdk.Pixbuf orig_pix) {
        bool has_alpha = orig_pix.has_alpha;
        int width = orig_pix.width;
        int height = orig_pix.height;

        unowned uint8[] pixels = orig_pix.get_pixels ();
        uint8[] gray = new uint8[width * height];
        double[] luminances = new double[width * height];

        int idx = 0;
        int ptr = 0;
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double alphas = has_alpha ? (double)pixels[idx + 3] / 255.0 : 1;
                double rs = (double)pixels[idx] / 255.0 * alphas;
                double gs = (double)pixels[idx + 1] / 255.0 * alphas;
                double bs = (double)pixels[idx + 2] / 255.0 * alphas;
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
                gray[ptr] = (uint8)((l - min_luminance) * 255.0 / range);
                ptr++;
            }
        }

        return gray;
    }

    private uint8[] convert_edges (uint8[] gray, int width, int height) {
        int idx = 0;
        int ptr = 0;
        uint8[] edges = new uint8[height * width];
        uint8[] surround = new uint8[8];

        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                ptr++;
                var l = gray[ptr];
                surround[0] = h > 0 && w > 0 ? gray[ptr - width - 1] : l;
                surround[1] = h > 0 ? gray[ptr - width] : l;
                surround[2] = h > 0 && w < width - 1 ? gray[ptr - width + 1] : l;
                surround[3] = w > 1 ? gray[ptr - 1] : l;
                surround[4] = w < width - 1 ? gray[ptr + 1] : l;
                surround[5] = h < height -1 && w > 0 ? gray[ptr + width - 1] : l;
                surround[6] = h < height -1 ? gray[ptr + width] : l;
                surround[7] = h < height -1 && w < width -1 ? gray[ptr + width + 1] : l;

                uint8 min = 255;
                uint8 max = 0;
                foreach (uint8 ls in surround) {
                    if (min > ls) {
                        min = ls;
                    }
                    if (max < ls) {
                        max = ls;
                    }
                }

                edges[ptr] = max - min > edge_sens && l < black_thr ? 0 : 255;
                idx += 1;
            }
        }

        return edges;
    }

    private Gdk.Pixbuf pixbuf_from_grayscale (uint8[] gray, int width, int height) {
        var idx = 0;
        var ptr = 0;
        uint8[] pixels = new uint8[width * height * 3];

        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                var l = gray[ptr];
                pixels[idx] = (uint8)l;
                pixels[idx + 1] = (uint8)l;
                pixels[idx + 2] = (uint8)l;

                idx += 3;
                ptr++;
            }
        }

        return new Gdk.Pixbuf.from_data (pixels, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);

    }
}
