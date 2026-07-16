import xml.etree.ElementTree as ET

tree = ET.parse('translations/qgc_source_zh_CN.ts')
root = tree.getroot()

for ctx in root:
    cname = ctx.find('name').text if ctx.find('name') is not None else '?'
    for msg in ctx.findall('message'):
        s = msg.find('source')
        t = msg.find('translation')
        if s is not None and t is not None and s.text and t.text:
            src = s.text
            trans = t.text
            src_has_1 = '%1' in src
            trans_has_1 = '%1' in trans
            src_has_2 = '%2' in src
            trans_has_2 = '%2' in trans
            if (src_has_1 and not trans_has_1) or (src_has_2 and not trans_has_2):
                print('PLACEHOLDER LOST: CTX=' + cname + ' | SRC=' + repr(src[:80]) + ' | TRANS=' + repr(trans[:80]))

# Also find VTAL typo
for ctx in root:
    cname = ctx.find('name').text if ctx.find('name') is not None else '?'
    for msg in ctx.findall('message'):
        t = msg.find('translation')
        if t is not None and t.text and 'VTAL' in t.text:
            print('TYPO: CTX=' + cname + ' | TRANS=' + repr(t.text[:80]))
