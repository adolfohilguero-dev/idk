#!/usr/bin/env python3
"""Prepara el proyecto Android generado por `flutter create` para esta app.
Uso (desde la carpeta del proyecto):  python3 patch_android.py
Añade permisos, receptores de notificaciones, desugaring y el nombre de la app."""
import os, re, sys

MANIFEST = 'android/app/src/main/AndroidManifest.xml'
PERMS = ['android.permission.INTERNET', 'android.permission.POST_NOTIFICATIONS',
         'android.permission.RECEIVE_BOOT_COMPLETED', 'android.permission.VIBRATE']
RECEIVERS = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''

def patch_manifest():
    if not os.path.exists(MANIFEST):
        sys.exit('No encuentro %s. Ejecuta esto dentro del proyecto creado con "flutter create".' % MANIFEST)
    s = open(MANIFEST, encoding='utf-8').read()
    add = ''.join('    <uses-permission android:name="%s"/>\n' % p for p in PERMS if p not in s)
    if add:
        s = re.sub(r'(<manifest[^>]*>\s*\n)', lambda m: m.group(1) + add, s, count=1)
    if 'ScheduledNotificationReceiver' not in s:
        s = s.replace('</application>', RECEIVERS + '    </application>', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="Chuleta SMX"', s, count=1)
    open(MANIFEST, 'w', encoding='utf-8').write(s)
    print('OK  AndroidManifest.xml')

def patch_gradle():
    for name, kts in (('android/app/build.gradle.kts', True), ('android/app/build.gradle', False)):
        if not os.path.exists(name):
            continue
        s = open(name, encoding='utf-8').read()
        if 'oreLibraryDesugaring' in s:
            print('OK  %s (ya estaba)' % name); return
        flag = 'isCoreLibraryDesugaringEnabled = true' if kts else 'coreLibraryDesugaringEnabled true'
        dep = ('    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")' if kts
               else "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'")
        if 'compileOptions {' in s:
            s = s.replace('compileOptions {', 'compileOptions {\n        ' + flag, 1)
        else:
            s = re.sub(r'(android\s*\{)', r'\1\n    compileOptions {\n        ' + flag + '\n    }', s, count=1)
        s = s.rstrip() + '\n\ndependencies {\n' + dep + '\n}\n'
        open(name, 'w', encoding='utf-8').write(s)
        print('OK  %s' % name); return
    sys.exit('No encuentro android/app/build.gradle(.kts).')

patch_manifest()
patch_gradle()
print('Listo. Ahora: flutter pub get && dart run flutter_launcher_icons && flutter build apk --release')
