public interface GnonogramTools.ToolInterface : Gtk.Widget {
    public abstract string description {get; set construct;}
    public virtual bool quit () {warning ("Quit %s", description); return false;}
    public virtual void hide () {warning ("Hidden %s", description);}
}
