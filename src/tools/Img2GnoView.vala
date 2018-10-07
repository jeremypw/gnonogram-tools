public class GnonogramTools.Img2GnoView : Gtk.Grid, GnonogramTools.ToolInterface {
    const string IMG2GNO_SETTINGS_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.settings";
    const string IMG2GNO_STATE_SCHEMA = "com.github.jeremypw.gnonogram-tools.img2gno.saved-state";
    const string UNSAVED_FILENAME = "Img2Gno" + Gnonograms.GAMEFILEEXTENSION;

    private Gtk.Entry name_entry;
    private Gnonograms.ScaleGrid rows_setting;
    private Gnonograms.ScaleGrid cols_setting;
    private Gtk.Image image_orig;
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

        var rows_grid = new GnonogramTools.DimensionGrid (rows_setting);
        var cols_grid = new GnonogramTools.DimensionGrid (cols_setting);

        image_orig = new Gtk.Image.from_icon_name ("missing-image", Gtk.IconSize.LARGE_TOOLBAR);
        eb_img = new Gtk.EventBox ();
        eb_img.add (image_orig);

        var bbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        load_button = new Gtk.Button.with_label (_("Load Image"));
        save_button = new Gtk.Button.with_label (_("Save Game"));

        solve_button = new Gtk.MenuButton ();
        solve_button.image = null;
        solve_button.label = _("Solve");

        model = new Gnonograms.Model ();
        solution_popover = new GnonogramTools.SolutionPopover (model, this);
        solution_popover.set_position (Gtk.PositionType.TOP);
        solve_button.set_popover (solution_popover);

        bbox.add (load_button);
        bbox.add (save_button);
        bbox.add (solve_button);
        bbox.margin = 12;

        attach (name_grid, 0, 0, 1, 1);
        attach (rows_grid, 0, 1, 1, 1);
        attach (cols_grid, 0, 2, 1, 1);
        attach (eb_img, 2, 0, 1, 1);
        attach (bbox, 0, 4, 2, 1);


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
                                                        Gdk.InterpType.NEAREST);
            image_orig.set_from_pixbuf (scaled_pix);
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
}
