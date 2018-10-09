public class GnonogramTools.DimensionGrid : Gtk.Grid {
    construct {
        expand = false;
        halign = Gtk.Align.END;
        column_homogeneous = false;
        margin = 12;
        row_spacing = 6;
        column_spacing = 6;
    }

    public DimensionGrid (Gnonograms.AppSetting setting) {
        add (setting.get_heading ());
        add (setting.get_chooser ());
    }
}
