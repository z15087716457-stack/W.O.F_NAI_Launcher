"""Local tag windows. Cursor offsets use Flutter's UTF-16 coordinate system."""
import re


def cursor_index(text, utf16_offset):
    raw = text.encode('utf-16-le')
    end = max(0, min(int(utf16_offset), len(raw) // 2)) * 2
    return len(raw[:end].decode('utf-16-le', errors='ignore'))


def clean_tag(value):
    value = re.sub(r'(^|\s)[+-]?(?:\d+(?:\.\d*)?|\.\d+)\s*::', ' ', value)
    value = re.sub(r':\s*-?\d+(?:\.\d+)?\s*$', '', value)
    value = value.replace('::', '').strip(' \t\r\n{}[]()')
    return value.replace('_', ' ').strip()


def context_window(text, utf16_offset, mode, count_tokens, budget=120):
    if mode not in ('before', 'around') or budget != 120:
        raise ValueError('invalid_context_mode')
    cursor = cursor_index(text, utf16_offset)
    parts = [(m.start(), m.end(), clean_tag(m.group()))
             for m in re.finditer(r'[^,，\r\n\uE000-\uF8FF]+', text)]
    # Exclude library aliases: these are instructions to expand, not tag text.
    parts = [p for p in parts if p[2] and '<' not in p[2] and '>' not in p[2]]
    if mode == 'before':
        parts = [p for p in parts if p[1] <= cursor]
    ordered = sorted(parts, key=lambda p: (max(p[0]-cursor, cursor-p[1], 0), p[0]))
    selected = []
    for part in ordered:
        candidate = sorted([*selected, part])
        value = ', '.join(p[2] for p in candidate)
        if count_tokens(value) > budget:
            # Keep a contiguous local window; do not skip a long adjacent tag
            # and accidentally pull unrelated tags from farther away.
            break
        selected = candidate
    value = ', '.join(p[2] for p in selected)
    return {'text': value, 'tokens': count_tokens(value), 'budget': budget,
            'mode': mode, 'tag_count': len(selected)}
