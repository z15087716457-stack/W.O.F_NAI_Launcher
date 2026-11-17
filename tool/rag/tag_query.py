"""Query preparation for the pinned DanbooruSearch retrieval contract."""
import re

STOP_WORDS = frozenset('''
, . : ; ? ! " ' ` ( ) [ ] { } < > - _ = + / \\ | @ # $ % ^ & * ~
， 。 ： ； ？ ！ “ ” ‘ ’ （ ） 【 】 《 》 、 … — ·
的 地 得 了 着 过 是 为 被 给 把 让 由 在 从 自 向 往 对 于
和 与 及 或 且 而 但 并 即 又 也 啊 吗 吧 呢 噢 哦 哈 呀 哇
我 你 他 她 它 我们 你们 他们 这 那 此 其 谁 啥 某 每
这个 那个 这些 那些 这里 那里 个 位 只 条 张 幅 件 套 双 对 副
种 类 群 些 点 份 部 名 很 太 更 最 挺 特 好 真
一 一个 一种 一下 一点 一些 有 无 非 没 不
正在 已经 正 刚 开始 继续 一直 不断 穿着 戴着 穿 戴
带有 具有 拥有 看起来 看上去 显得 仿佛 似乎 十分 非常 特别 比较
图片 画面 图像 位于 处于 许多 大量 各种 所有 其他 其它
a an the in on at to for of with by from as into about between through after before above below
and or but nor so yet is are was were be been being do does did done have has had having
will would shall should can could may might must not no very too also just only even still
i me my we our you your he him his she her it its they them their
this that these those which who whom what there here where when how all each every
some any few more most other such than up out if then else while during both same own now
'''.split()) | frozenset((' ', '\t', '\n', '\r'))


def english_terms(text, names):
    words = []
    for word in re.sub(r'[,()\[\]{}:]', ' ', text).lower().split():
        if word in names:
            words.append(word)
            continue
        if word in STOP_WORDS:
            continue
        variants = [word]
        if '-' in word:
            hyphenated = word.replace('-', '_')
            if hyphenated in names:
                words.append(hyphenated)
                continue
            variants.append(hyphenated)
        replacement = None
        for base in variants:
            for ending, substitute in [('s', ''), ('es', ''), ('ies', 'y')]:
                if base.endswith(ending) and len(base) > len(ending):
                    candidate = base[:-len(ending)] + substitute
                    if candidate in names:
                        replacement = candidate
                        break
            if replacement is not None:
                break
        if replacement is not None:
            words.append(replacement)
        elif not word.isdigit():
            words.append(word)
    merged = []
    offset = 0
    while offset < len(words):
        width = next((size for size in range(min(4, len(words)-offset), 1, -1)
                      if '_'.join(words[offset:offset+size]) in names), 1)
        merged.append('_'.join(words[offset:offset+width]))
        offset += width
    return merged


def prepare_query(text, names, tokenizer, segmentation=True):
    if not segmentation:
        return [text], [], []
    boundary = len([part for part in re.split(r'[\s\n\r，、；。]+', text) if part.strip()]) > 1
    tokens, segments = [], []
    for region in re.split(r'([一-龥]+(?:[\s\n\r，、；。]+[一-龥]+)*)', text):
        if not region.strip():
            continue
        if not re.search(r'[一-龥]', region):
            tokens.extend(english_terms(region, names))
            continue
        for segment in filter(None, (part.strip() for part in re.split(r'[\s\n\r，、；。]+', region))):
            segments.append(segment)
            if boundary and re.fullmatch(r'[一-龥]{1,7}', segment):
                tokens.append(segment)
            else:
                for chunk in re.split(r'([一-龥]+)', segment):
                    tokens.extend(tokenizer.cut(chunk) if re.match(r'[一-龥]', chunk)
                                  else english_terms(chunk, names))
    keywords = [word.strip() for word in tokens if word.strip() and word.strip() not in STOP_WORDS]
    extra = [part for part in segments if part != text and part not in set(keywords)]
    return [text, *extra, *keywords], keywords, extra


def intent_weights(text):
    content = text.replace(' ', '')
    size = max(len(content), 1)
    chinese = sum('\u4e00' <= letter <= '\u9fff' for letter in content) / size > .5
    english = sum(letter.isascii() and letter.isalpha() for letter in content) / size > .5
    if len(text) > 8 and chinese:
        return (.8, 1.1, 1.4, .9)
    if len(text) > 8 and english:
        return (1., .9, 1.3, .8)
    if chinese:
        return (.8, 1.1, .6, 1.3)
    if english:
        return (1.3, .8, .6, 1.)
    return (1., 1., 1., 1.)
