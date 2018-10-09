public class GnonogramTools.SettingGrid : Gtk.Grid {
    private int pos = 0;

    construct {
//        expand = false;
//        halign = Gtk.Align.END;
        column_homogeneous = false;
        margin = 12;
        row_spacing = 12;
        column_spacing = 6;
    }

    public SettingGrid (Gnonograms.AppSetting setting) {
        add_a_setting (setting);
    }

    public void add_a_setting (Gnonograms.AppSetting setting) {
        var label = setting.get_heading ();
        var chooser = setting.get_chooser ();
        label.xalign = 1;
        label.valign = Gtk.Align.CENTER;
        label.vexpand = false;

        chooser.halign = Gtk.Align.START;
        chooser.valign = Gtk.Align.CENTER;
        chooser.vexpand = false;
        chooser.hexpand = true;

        attach (label, 0, pos, 1, 1);
        attach (setting.get_chooser (), 1, pos, 1, 1);
        pos++;

    }
}
