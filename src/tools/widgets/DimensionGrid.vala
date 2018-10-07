public class GnonogramTools.DimensionGrid : Gtk.Grid {
    construct {
        expand = false;
        halign = Gtk.Align.CENTER;
    }

    public DimensionGrid (Gnonograms.AppSetting setting) {
        add (setting.get_heading ());
        add (setting.get_chooser ());
    }
}
