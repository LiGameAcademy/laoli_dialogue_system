"""Run plugin contracts in a disposable Godot host, without touching a game's saves."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

SERVICES = {
    'DialogueHistoryManager': 'history/dialogue_history_manager.gd',
    'VariableManager': 'variable/variable_manager.gd',
    'QuestManager': 'quest/quest_manager.gd',
    'DialogueManager': 'dialogue/dialogue_manager.gd',
}


def run(engine: str, host: Path, args: list[str], sentinel: str | None = None) -> None:
    result = subprocess.run(
        [engine, '--headless', '--path', str(host), *args],
        capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180,
    )
    output = result.stdout + result.stderr
    errors = [line for line in output.splitlines()
              if line.startswith(('ERROR:', 'SCRIPT ERROR:'))
              and 'Failed to read the root certificate store.' not in line]
    if result.returncode or errors or (sentinel and sentinel not in output):
        print(output)
        raise RuntimeError(f'Godot check failed: {args}')
    print(sentinel or 'PASS: clean plugin import')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--temp-root', type=Path)
    options = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='laoli_dialogue_test_', dir=options.temp_root) as directory:
        host = Path(directory)
        addon = host / 'addons' / 'laoli_dialogue_system'
        shutil.copytree(source, addon, ignore=shutil.ignore_patterns('.git', '.godot', '__pycache__'))
        project = 'config_version=5\n[application]\nconfig/name="Plugin contracts"\n[autoload]\n'
        for name, path in SERVICES.items():
            project += f'{name}="*res://addons/laoli_dialogue_system/scripts/core/{path}"\n'
        project += '\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
        (host / 'project.godot').write_text(project, encoding='utf-8')
        run(options.godot, host, ['--editor', '--import'])
        for test, sentinel in [
            ('verify_cutscene_contracts', 'PASS: duplicate/stale callbacks'),
            ('verify_checkpoint_storage', 'PASS: standalone checkpoint'),
            ('verify_plugin_compatibility', 'PASS: standalone UI/theme'),
        ]:
            run(options.godot, host,
                ['--fixed-fps', '60', f'res://addons/laoli_dialogue_system/tests/{test}.tscn',
                 '--quit-after', '6000'], sentinel)
        # Reconstruct recorded ownership, then verify disable/re-enable and host retention.
        probe = host / 'addons' / 'install_probe'
        probe.mkdir()
        (probe / 'plugin.cfg').write_text(
            '[plugin]\nname="Installation probe"\ndescription="Test fixture"\n'
            'author="Test"\nversion="1"\nscript="probe.gd"\n', encoding='utf-8')
        (probe / 'probe.gd').write_text(
            '@tool\nextends "res://addons/laoli_dialogue_system/tests/verify_plugin_install.gd"\n',
            encoding='utf-8')
        names = ', '.join(f'"{name}"' for name in SERVICES)
        project += f'\n[laoli_dialogue_system]\ninstalled_autoloads=[{names}]\n'
        project += ('\n[editor_plugins]\nenabled=PackedStringArray('
                    '"res://addons/laoli_dialogue_system/plugin.cfg", '
                    '"res://addons/install_probe/plugin.cfg")\n')
        (host / 'project.godot').write_text(project, encoding='utf-8')
        run(options.godot, host, ['--editor', '--quit-after', '6000'],
            'PASS: plugin installation settings')


if __name__ == '__main__':
    main()
