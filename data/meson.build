i18n.merge_file (
    'post_uninstall',
    input: 'post_uninstall.py.in',
    output: 'post_uninstall.py',
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    install: false,
)
i18n.merge_file (
    'desktop',
    input: meson.project_name () + '.meson.in.desktop',
    output: meson.project_name () + '.desktop',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'applications'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'appdata',
    input: meson.project_name () + '.meson.in.appdata.xml',
    output: meson.project_name () + '.appdata.xml',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'metainfo'),
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'xml'
)

test (
    'Validate desktop file',
    find_program ('desktop-file-validate'),
    args: join_paths (meson.current_build_dir (),  meson.project_name () + '.desktop')
)

test (
    'Validate appdata file',
    find_program ('appstreamcli'),
    args: ['validate', join_paths (meson.current_build_dir (), meson.project_name () + '.appdata.xml')]
)

test (
    'Validate gschema file',
    find_program ('glib-compile-schemas'),
    args: ['--dry-run', '--strict', join_paths (meson.current_source_dir (), 'schemas')]
)

install_data (
    join_paths (meson.current_source_dir (),'schemas', meson.project_name() + '.gschema.xml'),
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

