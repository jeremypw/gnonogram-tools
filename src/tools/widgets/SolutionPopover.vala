public class GnonogramTools.SolutionPopover : Gtk.Popover {
    public Gnonograms.Model model { get; construct; }
    public Gtk.Widget view {get; construct; }
    public Gnonograms.Difficulty grade { get; set; default = Gnonograms.Difficulty.UNDEFINED;}

    private Gnonograms.CellGrid solution_grid;
    private Gtk.AspectFrame solution_frame;
    private Gtk.Label grade_label;

    construct {
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;

        grade_label = new Gtk.Label ("");
        grade_label.no_show_all = true;
        grade_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        grid.add (grade_label);

        solution_grid = new Gnonograms.CellGrid (model);
        model.game_state = Gnonograms.GameState.SETTING;
        solution_grid.draw_only = true;
        solution_grid.visible = true;
        solution_grid.margin = 12;

        solution_frame = new Gtk.AspectFrame (null, 0.5f, 0.5f, 1.0f, false);
        solution_frame.add (solution_grid);

        grid.add (solution_frame);
        add (grid);
        grid.show_all ();

        model.notify["dimensions"].connect (() => {
            solution_frame.ratio = (float)(model.cols) / (float)(model.rows);
            set_solution_grid_size ();
        });

        notify["grade"].connect (() => {
            grade_label.label = grade.to_string ();
            grade_label.visible = grade != Gnonograms.Difficulty.UNDEFINED;
            set_solution_grid_size ();
        });

        view.size_allocate.connect (set_solution_grid_size);
    }

    public SolutionPopover (Gnonograms.Model model, Gtk.Widget view) {
        Object (relative_to: view,
                model: model,
                view: view);
    }

    /* BLACK MAGIC! Find more elegant way (PopoverConstraint does not seems to work) */
    private void set_solution_grid_size () {
        if (solution_frame.ratio > 1) {
            var w = view.get_allocated_width ();
            solution_grid.set_size_request (w, (int) (w / solution_frame.ratio));
        } else {
            var h = view.get_allocated_height () - (grade_label.visible ? 48 : 0);
            solution_grid.set_size_request ((int)(h * solution_frame.ratio), h);
        }
    }
}
