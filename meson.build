project ('com.github.jeremypw.gnonogram-tools', 'vala', 'c')
shortname = 'gnonogram-tools'
domain = 'com.github.jeremypw.'
schema_path = '/com/github/jeremypw/' + shortname + '/'
tmp_dir_path = '/.local/share/' + shortname + '/'

i18n = import ('i18n')

add_global_arguments (
    '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
    language:'c'
)

dependency('gtk+-3.0', version: '>=3.18', required: true)
GTK322 = dependency('gtk+-3.0', version: '>=3.22', required: false)

if GTK322.found ()
    add_project_arguments (
        '--define=HAVE_GTK_3_22',
        language:'vala'
    )
endif

executable (
    meson.project_name (),
    'src/Application.vala',
    'src/Controller.vala',
    'src/View.vala',
    'src/tools/ToolInterface.vala',
    'src/tools/ClueEntryView.vala',

    dependencies : [
        dependency ('gtk+-3.0'),
        dependency ('gee-0.8'),
        dependency ('granite'),
        dependency ('gnonograms-core')
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')

uninstall_data = configuration_data()
uninstall_data.set('schema_install_dir', join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas'))
uninstall_data.set('schema_path', schema_path)
uninstall_data.set('desktop_dir_path', join_paths(get_option('prefix'), get_option('datadir'), 'applications'))

configure_file (
    input: join_paths (meson.source_root (), 'data', 'post_uninstall.py.in'),
    output: 'post_uninstall.py',
    configuration: uninstall_data
)

subdir ('po')
subdir ('data')
