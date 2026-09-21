"""Import reviewed Geist SVG matches without changing Material IconData IDs.

Usage: python tool/branding/import_geist_icons.py --source <svg-directory>
Re-run only after reviewing new semantic mappings below. No fuzzy name matching.
"""
import argparse
import json
import re
import shutil
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Each line is an artwork name followed by the existing action names it depicts.
# Outline/rounded style suffixes share artwork; filled state pairs are explicit.
GROUPS = """
accessibility accessibility accessibility_new
clock access_time schedule watch
credit-card account_balance_wallet
user account_circle person person_pin portrait
git-branch account_tree call_split
plus add
plus-square-small add_box
plus-circle add_circle
bar-chart analytics bar_chart
archive archive inventory_2
arrow-left arrow_back
chevron-left arrow_back_ios chevron_left
arrow-down arrow_downward south
chevron-down-small arrow_drop_down
chevron-up-small arrow_drop_up
arrow-right arrow_forward arrow_right_alt trending_flat
chevron-right arrow_forward_ios chevron_right keyboard_arrow_right
arrow-up arrow_upward north
file-text article description text_snippet
music audiotrack music_note
sparkles auto_awesome auto_fix_high
book-open auto_stories menu_book
lightning bolt
bookmark bookmark bookmark_border
pen brush draw
wrench build
calendar calendar_today date_range event
camera camera_alt photo_camera
cross-circle cancel
target center_focus_strong filter_center_focus
check check done_all library_add_check
check-square check_box checklist
check-circle-fill check_circle
check-circle check_circle_outline check_circle_outlined
cross clear close
cloud cloud
cloud-upload cloud_upload
code code data_object
book-closed collections_bookmark library_books
droplet colorize invert_colors
desktop-device computer
copy content_copy copy file_copy copy_all
clipboard content_paste paste
folder-plus create_new_folder
crop crop
trash delete delete_forever delete_sweep
download download file_download save_alt system_update_alt
menu drag_handle
pencil edit drive_file_rename
notes edit_note
email email
face-happy emoji_emotions mood
warning-fill error warning
warning error_outline error_outlined warning_amber warning_outlined warning_rounded
chevron-up expand_less keyboard_arrow_up
chevron-down expand_more keyboard_arrow_down
compass explore
puzzle extension
face-smile face
heart-fill favorite
heart favorite_border favorite_outline favorite_outlined
file file_present insert_drive_file
filter filter_alt filter_list
tabs filter_none
chevron-double-left first_page keyboard_double_arrow_left
fullscreen fit_screen fullscreen open_in_full zoom_out_map
folder-closed folder
folder-open folder_open
file-zip folder_zip
text-format format_size text_fields
acronym-gif gif gif_box
grid-square grid_on grid_view view_module dashboard category widgets
users group groups people
question help
clock-rewind history
home home
network-device hub
image image
inbox inbox
information-fill info
information info_outline info_outlined
sign-in input login
key key vpn_key
tag label tag sell
globe language public
chevron-double-right last_page
layers layers
sun light_mode wb_sunny
link link
buildings location_city
location location_on
lock-closed lock
lock-open lock_open
logout logout output
magnifying-glass manage_search search
cpu memory
menu menu
git-merge merge merge_type
more-horizontal more_horiz
more-vertical more_vert
cursor mouse
video movie videocam
moon nightlight nights_stay
external open_in_new
arrow-move open_with
coins paid toll savings
pause pause
clock-small pending
user-plus person_add_alt
user-minus person_remove
play-fill play_arrow play_circle_fill
power power
eye preview visibility remove_red_eye
pin push_pin
corner-up-right redo
refresh-clockwise refresh repeat sync
minus remove
minus-circle remove_circle
refresh-counter-clockwise restart_alt
rotate-counter-clockwise rotate_left
rotate-clockwise rotate_right
floppy-disk save
shield security shield
paper-airplane send
settings-gear settings
chart-activity show_chart timeline insights
arrow-crossed shuffle
skip-forward-fill skip_next
sort-descending sort
gauge speed
star-fill star
star star_border star_outline
stop-circle stop_circle
database storage
arrow-left-right swap_horiz
arrow-up-down swap_vert import_export
download system_update
thumb-up thumb_up
stopwatch timer
cursor-click touch_app
chart-trending-down trending_down
chart-trending-up trending_up
settings-sliders tune
corner-up-left undo
cloud-upload file_upload
shield-check verified_user
layout view_quilt
sidebar-left view_sidebar
list-unordered view_list
eye-off visibility_off
speaker-volume-loud volume_up
magnifying-glass-plus zoom_in
magnifying-glass-minus zoom_out
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True, type=Path)
    args = parser.parse_args()
    mappings = {}
    for row in GROUPS.strip().splitlines():
        asset, *names = row.split()
        for name in names:
            mappings[name] = asset
    usage = Counter()
    for file in (ROOT / 'lib').rglob('*.dart'):
        if file.name == 'studio_icon_registry.dart':
            continue
        usage.update(re.findall(r'\bIcons\.(\w+)', file.read_text(encoding='utf-8')))
    resolved = {}
    for name in usage:
        base = re.sub(r'_(outlined|outline|rounded)$', '', name)
        asset = mappings.get(name, mappings.get(base))
        if asset:
            assert (args.source / f'{asset}.svg').is_file(), asset
            resolved[name] = asset

    dest = ROOT / 'assets/icons/geist'
    dest.mkdir(parents=True, exist_ok=True)
    for asset in sorted(set(resolved.values())):
        shutil.copyfile(args.source / f'{asset}.svg', dest / f'{asset}.svg')

    # Some Material names are aliases of the same IconData. Use a normal map
    # with explicit assignments so aliases remain valid without duplicate keys.
    lines = [
        '// Generated by tool/branding/import_geist_icons.py. Do not edit.',
        "import 'package:flutter/material.dart';", '',
        'abstract final class StudioIconRegistry {',
        '  static String? assetFor(IconData? icon) => assets[icon];', '',
        '  static final Map<IconData, String> assets = _buildAssets();', '',
        '  static Map<IconData, String> _buildAssets() {',
        '    final result = <IconData, String>{};',
    ]
    for name, asset in sorted(resolved.items()):
        lines.append(f"    result[Icons.{name}] = 'assets/icons/geist/{asset}.svg';")
    lines.extend(['    return Map.unmodifiable(result);', '  }', '}', ''])
    (ROOT / 'lib/presentation/widgets/common/studio_icon_registry.dart').write_text(
        '\n'.join(lines), encoding='utf-8')
    manifest = {
        'source': 'https://github.com/jarvis394/geist-icons/tree/f478dfba63570bccb7efeacd7df82df994064058/source',
        'licenseDeclaration': 'https://github.com/jarvis394/geist-icons/blob/main/package.json',
        'note': 'Community snapshot of Geist artwork, not an official Vercel Flutter package.',
        'normalization': 'Only JSX numeric width/height attributes are converted to XML quotes; paths match upstream.',
        'matches': dict(sorted(resolved.items())),
        'retainedMaterialIcons': sorted(set(usage) - set(resolved)),
    }
    (ROOT / 'tool/branding/geist_icon_manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'{len(resolved)}/{len(usage)} icon names mapped; '
          f'{sum(usage[n] for n in resolved)}/{sum(usage.values())} occurrences; '
          f'{len(set(resolved.values()))} SVG assets.')


if __name__ == '__main__':
    main()
