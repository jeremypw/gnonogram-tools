#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')
desktopdir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'applications')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir])
    print('Updating desktop database...')
    subprocess.call(['update-desktop-database', desktopdir])
