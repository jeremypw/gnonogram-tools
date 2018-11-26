public class GnonogramTools.Img2GnoView : Gtk.Grid, GnonogramTools.ToolInterface {
    const string IMG2GNO_SETTINGS_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.settings";
    const string IMG2GNO_STATE_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.saved-state";
    const string UNSAVED_FILENAME = "Img2Gno" + Gnonograms.GAMEFILEEXTENSION;

    private Gtk.Entry name_entry;
    private Gnonograms.ScaleGrid rows_setting;
    private Gnonograms.ScaleGrid cols_setting;
    private Gnonograms.ScaleGrid contrast_base_setting;
    private Gnonograms.ScaleGrid contrast_range_setting;
    private Gnonograms.ScaleGrid edge_setting;
    private Gnonograms.ScaleGrid black_setting;
    private Gnonograms.ScaleGrid cell_threshold_setting;
    private Gnonograms.SettingSwitch invert_switch;
    private Gtk.Image image_orig;
    private Gtk.Image image_intermed1;
    private Gtk.Image image_intermed2;
    private Gtk.Image image_cellgrid;
    private int[] intermed1_data;
    private int[] intermed2_data;
    private uint edge_sens = 50;
    private uint black_thr = 128;
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
        image_grid.column_spacing = 6;

        rows_setting = new Gnonograms.ScaleGrid (_("Rows"));
        cols_setting = new Gnonograms.ScaleGrid (_("Columns"));
        contrast_base_setting = new Gnonograms.ScaleGrid (_("Contrast baseline"));
        contrast_range_setting = new Gnonograms.ScaleGrid (_("Contrast range"));
        black_setting = new Gnonograms.ScaleGrid (_("Black sensitivity"));
        edge_setting = new Gnonograms.ScaleGrid (_("Edge threshold"));
        cell_threshold_setting = new Gnonograms.ScaleGrid (_("Cell threshold"));
        invert_switch = new Gnonograms.SettingSwitch ("Invert");

        controls_grid.add_a_setting (rows_setting);
        controls_grid.add_a_setting (cols_setting);
        controls_grid.add_a_setting (contrast_base_setting);
        controls_grid.add_a_setting (contrast_range_setting);
        controls_grid.add_a_setting (black_setting);
        controls_grid.add_a_setting (edge_setting);
        controls_grid.add_a_setting (cell_threshold_setting);
        controls_grid.add_a_setting (invert_switch);

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
        var orig_label = new Gtk.Label ("Original Image");
        orig_label.no_show_all = true;

        image_intermed1 = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        image_intermed1.no_show_all = true;
        image_intermed1.visible = false;
        var intermed1_label = new Gtk.Label ("Grey Scale");
        intermed1_label.no_show_all = true;

        image_intermed2 = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        image_intermed2.no_show_all = true;
        image_intermed2.visible = false;
        var intermed2_label = new Gtk.Label ("Edge detect");
        intermed2_label.no_show_all = true;

        image_cellgrid = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        image_cellgrid.no_show_all = true;
        image_cellgrid.visible = false;
        var cellgrid_label = new Gtk.Label ("Cell Grid");
        cellgrid_label.no_show_all = true;

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);

        bbox.add (load_button);
        bbox.add (save_button);
        bbox.add (solve_button);
        bbox.margin = 12;

        image_grid.attach (image_orig, 0, 0, 1, 1);
        image_grid.attach (orig_label, 1, 0, 1, 1);
        image_grid.attach (image_intermed1, 0, 1, 1, 1);
        image_grid.attach (intermed1_label, 1, 1, 1, 1);
        image_grid.attach (image_intermed2, 0, 2, 1, 1);
        image_grid.attach (intermed2_label, 1, 2, 1, 1);
        image_grid.attach (image_cellgrid, 0, 3, 1, 1);
        image_grid.attach (cellgrid_label, 1, 3, 1, 1);

        attach (controls_grid, 0, 0, 1, 1);
        attach (image_grid, 1, 0, 1, 1);
        attach (bbox, 0, 1, 2, 1);

        rows_setting.value_changed.connect (on_dimension_changed);
        cols_setting.value_changed.connect (on_dimension_changed);

        contrast_base_setting.value_changed.connect (on_contrast_changed);
        contrast_range_setting.value_changed.connect (on_contrast_changed);

        black_setting.value_changed.connect ((val) => {
            black_thr = (int)(225 - val * 4);
            update_intermed2 ();

        });

        edge_setting.value_changed.connect ((val) => {
            edge_sens = (int)(10 + val * 4);
            update_intermed2 ();
        });

        cell_threshold_setting.value_changed.connect ((val) => {
            convert_cell_grid ();
        });

        invert_switch.@switch.state_changed.connect (() => {
            update_intermed2 ();
        });

        save_button.clicked.connect (() => {
            save_game (null, true);
        });

        load_button.clicked.connect (() => {
            load_image ();
        });

        realize.connect (() => {
            contrast_base_setting.set_value (0);
            contrast_range_setting.set_value (50);
            black_setting.set_value (25);
            edge_setting.set_value (25);
            cell_threshold_setting.set_value (25);
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
        convert_cell_grid ();
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

            var pb = new Gdk.Pixbuf.from_file (image_path);
            var pixels = pb.height * pb.width;
            pix_original = scale_pixbuf_for_convert (pb);
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
        var w = pix.width;
        var h = pix.height;
        double aspect = (double)h / (double)w;
        if (w > h) {
            return pix.scale_simple (100,
                                     (int)(100.0 * aspect),
                                     Gdk.InterpType.NEAREST);
        } else {
            return pix.scale_simple ((int)(100.0 / aspect),
                                     100,
                                     Gdk.InterpType.NEAREST);
        }
    }

    private Gdk.Pixbuf scale_pixbuf_for_convert (Gdk.Pixbuf pix) {
        var w = pix.width;
        var h = pix.height;
        double aspect = (double)h / (double)w;
        if (w > h) {
            return pix.scale_simple (100,
                                     (int)(100.0 * aspect),
                                     Gdk.InterpType.BILINEAR);
        } else {
            return pix.scale_simple ((int)(100.0 / aspect),
                                     100,
                                     Gdk.InterpType.BILINEAR);
        }
    }

    private void convert_original_image () {
        update_intermed1 ();
        update_intermed2 ();
        image_orig.visible = true;
        image_intermed1.visible = true;
        image_intermed2.visible = true;
        image_cellgrid.visible = true;
    }

    private void update_intermed1 () {
        if (pix_original == null) {
            return;
        }

        convert_to_grayscale_array (pix_original);
        var intermed1_pix = pixbuf_from_grayscale (intermed1_data, pix_original.width, pix_original.height);
        var scaled_intermed1 = scale_pixbuf_for_display (intermed1_pix);
        image_intermed1.set_from_pixbuf (scaled_intermed1);
    }

    private void on_contrast_changed () {
        update_intermed1 ();
        update_intermed2 ();
    }

    private void update_intermed2 () {
        if (pix_original == null || intermed1_data == null) {
            return;
        }

        convert_edges (pix_original.width, pix_original.height);
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

    private void convert_to_grayscale_array (Gdk.Pixbuf orig_pix) {
        bool has_alpha = orig_pix.has_alpha;
        int width = orig_pix.width;
        int height = orig_pix.height;
        unowned uint8[] pixels = orig_pix.get_pixels ();
        intermed1_data = new int[width * height];
        double[] luminances = new double[width * height];

        /* Convert colors to luminances */
        int idx = 0;
        int ptr = 0;
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double alphas = has_alpha ? (double)pixels[idx + 3] / 255.0 : 1;
                double rs = (double)pixels[idx] / 255.0 * alphas;
                double gs = (double)pixels[idx + 1] / 255.0 * alphas;
                double bs = (double)pixels[idx + 2] / 255.0 * alphas;
                double luminance = 0.25 * rs + 0.25 * gs + 0.25 * bs + (1 - alphas); /* TODO tweak luminance formula or make user adjustable */
                luminances[ptr] = luminance;
                idx += orig_pix.n_channels;
                ptr++;
            }
        }

        /* Find lowest and highest luminance */
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

        /* Convert luminace range  to intermed1_datascale 0 - 255 */
        double range = max_luminance - min_luminance;
        range = range * contrast_range_setting.get_value () / 50.0;
        min_luminance += (range * contrast_base_setting.get_value ()) / 100.0;

        ptr = 0;
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double l = luminances[ptr];
                intermed1_data[ptr] = (int)((l - min_luminance) * 255.0 / range).clamp (0, 255);
                ptr++;
            }
        }

        return;
    }

    /* Matrix indices:
     * 0 1 2
     * 3 4 5
     * 6 7 8
    */

    /* Mask Mx:
     * -1 0 1
     * -2 0 2
     * -1 0 1
     */

    /* Mask My:
     *  1  2  1
     *  0  0  0
     * -1 -2 -1
     */

    private void convert_edges (int width, int height) {
        intermed2_data = new int[height * width];
        int[] matrix = new int[9]; /* holds the pixels surrounding any one pixel plus that pixel */
        int[] mask_x = new int[] {-1, 0, 1, -2, 0, 2, -1, 0, 1};
        int[] mask_y = new int[] {1, 2, 1, 0, 0, 0, -1, -2, -1};

        var black_state = invert_switch.get_state () ? 255 : 0;
        var clear_state = invert_switch.get_state () ? 0 : 255;
        /* Examine each pixel and its surroundings */
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                var ptr = h * width + w;
                if (h > 0 && h < height - 1 && w > 0 && w < width -1) {
                    /* surrounding pixels off the edge deemed to be same as target pixel */
                    var idx = ptr - width - 1;
                    matrix[0] = intermed1_data[idx++]; /* Top left */
                    matrix[1] = intermed1_data[idx++];  /* Top center */
                    matrix[2] = intermed1_data[idx];  /* Top right */
                    idx = ptr - 1;
                    matrix[3] = intermed1_data[idx++];  /* Center left */
                    matrix[4] = intermed1_data[idx++]; /* target */
                    matrix[5] = intermed1_data[idx]; /* Center right */
                    idx = ptr + width - 1;
                    matrix[6] = intermed1_data[idx++]; /* Bottom left */
                    matrix[7] = intermed1_data[idx++]; /* Bottom center */
                    matrix[8] = intermed1_data[idx]; /* Bottom right */

                    /* Calculate the gradient using Sobel matrices */
                    int dx = 0;
                    int dy = 0;
                    for (int i = 0; i < 9; i++) {
                        dx += mask_x[i] * matrix[i];
                        dy += mask_y[i] * matrix[i];
                    }

                    double grad_approx = int.max (dx.abs (), dy.abs ());
                    intermed2_data[ptr] = grad_approx > edge_sens ? black_state : clear_state;
                } else { /* on edge */
                    intermed2_data[ptr] = intermed1_data[ptr] < black_thr ? black_state : clear_state;
                }
            }
        }

        convert_cell_grid ();
        return;
    }

    private void convert_cell_grid () {
        if (pix_original == null) {
            return;
        }

        var invert = invert_switch.get_state ();
        var clear_state = invert ? Gnonograms.CellState.EMPTY : Gnonograms.CellState.FILLED;
        var black_state = invert ? Gnonograms.CellState.FILLED : Gnonograms.CellState.EMPTY;

        for (int r = 0; r < model.rows; r++) {
            for (int c = 0; c < model.cols; c++) {
                model.set_data_from_rc (r, c, clear_state);
            }
        }

        var pix_per_row = (double)(pix_original.height) / (double)(model.rows);
        var pix_per_col = (double)(pix_original.width) / (double)(model.cols);
        var rows_per_pix = ((int)(1 / pix_per_row)).clamp (1, 10);
        var cols_per_pix = ((int)(1 / pix_per_col)).clamp (1, 10);
        double[] total_l = new double[model.rows * model.cols];
        for (int i = 0; i < model.rows * model.cols; i++) {
            total_l[i] = 0.0;
        }

        int[] avg_over = new int[model.rows * model.cols];
        for (int i = 0; i < model.rows * model.cols; i++) {
            avg_over[i] = 0;
        }

        var threshold = cell_threshold_setting.get_value () * 5;

        for (int h = 0; h < pix_original.height; h++) {
            for (int w = 0; w < pix_original.width; w++) {
                var ptr = h * pix_original.width + w;
                int r = (int)((double)h / pix_per_row);
                int c = (int)((double)w / pix_per_col);

                for (int i = 0; i < rows_per_pix; i++) {
                    for (int j = 0; j < cols_per_pix; j++) {
                        if (r + i < model.rows && c + j < model.cols) {
                            var idx = (r + i) * model.cols + c + j;
                            total_l[idx] += intermed2_data[ptr];
                            avg_over[idx]++;
                        }
                    }
                }
            }
        }

        for (int r = 0; r < model.rows; r++) {
            for (int c = 0; c < model.cols; c++) {
                var idx = r * model.cols + c;
                assert (avg_over[idx] > 0);
                var clear = invert ? total_l[idx] / avg_over[idx] > threshold :
                                     total_l[idx] / avg_over[idx] < 255 - threshold;
                if (clear) {
                    model.set_data_from_rc (r, c, clear_state);
                } else {
                    model.set_data_from_rc (r, c, black_state);
                }
            }
        }


        image_cellgrid.set_from_pixbuf (scale_pixbuf_for_display (pixbuf_from_model ()));
    }

    private Gdk.Pixbuf pixbuf_from_grayscale (int[] gray, int width, int height) {
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

    private Gdk.Pixbuf pixbuf_from_model () {
        var idx = 0;
        var ptr = 0;
        var width = model.cols;
        var height = model.rows;
        uint8[] pixels = new uint8[width * height * 3];

        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                var l = model.get_data_from_rc (h, w) == Gnonograms.CellState.FILLED ? 0 : 255;
                pixels[idx] = (uint8)l;
                pixels[idx + 1] = (uint8)l;
                pixels[idx + 2] = (uint8)l;

                idx += 3;
                ptr++;
            }
        }

        return new Gdk.Pixbuf.from_data (pixels, Gdk.Colorspace.RGB, false, 8, (int)width, (int)height, (int)width * 3);
    }
}
