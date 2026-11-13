import json
import os
import shutil
from importlib import import_module

from lazurite.compiler.macro_define import MacroDefine

from subpacks import SUBPACKS

lp = import_module('lazurite.project.project')

stage = '.stage'
skip = {'pack', 'tools', 'tmp', 'common'}

defaults = {
    'SunDirection': [1.0, 0.0, 0.0, 0.0],
    'CloudColor': [1.0, 1.0, 1.0, 1.0],
    'SkyColor': [1.0, 1.0, 1.0, 1.0],
    'FogColor': [1.0, 1.0, 1.0, 1.0],
}

extra_uniforms = {
    'Weather': ['ViewPositionAndTime'],
    'Stars': ['ViewPositionAndTime'],
}

if os.path.isdir(stage):
    shutil.rmtree(stage)
os.makedirs(stage)

for name in os.listdir('.'):
    if name.startswith('.') or name in skip or not os.path.isdir(name):
        continue
    shutil.copytree(name, os.path.join(stage, name))
shutil.copy('project.json', stage)

with open(os.path.join('common', 'material.json')) as f:
    common = json.load(f)

for name in os.listdir(stage):
    folder = os.path.join(stage, name)
    if not os.path.isfile(os.path.join(folder, 'config.json')):
        continue

    with open(os.path.join(folder, 'material.json'), 'w') as f:
        json.dump(common, f, indent=2)

    uniforms = os.path.join(folder, 'uniforms')
    os.makedirs(uniforms, exist_ok=True)

    for uniform in common.get('uniform_overrides', {}):
        entry = {
            'name': uniform,
            'type': 'vec4',
            'count': 1,
            'default': defaults.get(uniform, [0.0, 0.0, 0.0, 0.0]),
        }
        with open(os.path.join(uniforms, uniform + '.json'), 'w') as f:
            json.dump(entry, f, indent=2)

    for uniform in extra_uniforms.get(name, []):
        entry = {
            'name': uniform,
            'type': 'vec4',
            'count': 1,
            'default': [0.0, 0.0, 0.0, 0.0],
        }
        with open(os.path.join(uniforms, uniform + '.json'), 'w') as f:
            json.dump(entry, f, indent=2)

profile = os.environ.get('PROFILE', 'android')
shaderc = os.path.abspath(os.environ.get('SHADERC_PATH', os.path.join('tools', 'shaderc')))

out = os.path.join('pack', 'renderer', 'materials')
os.makedirs(out, exist_ok=True)

lp.compile(
    project_path=stage,
    profiles=[profile],
    output_folder=out,
    material_patterns=[],
    shaderc_path=shaderc,
    defines=[]
)

subpacks_dir = os.path.join('pack', 'subpacks')
if os.path.isdir(subpacks_dir):
    shutil.rmtree(subpacks_dir)

manifest_subpacks = []

for sp in SUBPACKS:
    sp_dir = os.path.join(subpacks_dir, sp['folder'])
    sp_out = os.path.join(sp_dir, 'renderer', 'materials')
    os.makedirs(sp_dir, exist_ok=True)

    mats = sp.get('materials')

    if mats is not None and len(mats) == 0:
        with open(os.path.join(sp_dir, 'subpack.txt'), 'w') as f:
            f.write(sp['name'])
    else:
        patterns = []
        for m in (mats or []):
            mat_path = os.path.join(stage, m)
            if not os.path.isdir(mat_path):
                raise SystemExit('Material ' + m + ' does not exist (subpack ' + sp['folder'] + ')')
            patterns.append(mat_path)

        os.makedirs(sp_out, exist_ok=True)

        lp.compile(
            project_path=stage,
            profiles=[profile],
            output_folder=sp_out,
            material_patterns=patterns,
            shaderc_path=shaderc,
            defines=[MacroDefine.from_string(d) for d in sp['defines']]
        )

    manifest_subpacks.append({
        'folder_name': sp['folder'],
        'name': sp['name'],
        'memory_tier': 1,
    })

manifest_path = os.path.join('pack', 'manifest.json')
with open(manifest_path, encoding='utf-8') as f:
    manifest = json.load(f)

if manifest_subpacks:
    manifest['subpacks'] = manifest_subpacks
else:
    manifest.pop('subpacks', None)

with open(manifest_path, 'w', encoding='utf-8') as f:
    json.dump(manifest, f, indent=2)
