import xml.etree.ElementTree as ET

ts_path = 'translations/qgc_source_zh_CN.ts'
T = {
    ' To change this configuration, select the desired frame class below and then reboot the vehicle.': '  要更改此配置，请在下方选择所需的机架类别，然后重启载具。',
    ' via USB to ': '  通过 USB 连接到 ',
    ' to a powered USB port on your computer, not through a USB hub. ': '  到电脑的带电 USB 端口，不要通过 USB 集线器。',
    ' seconds': '  秒',
    ' seconds ...': '  秒...',
    ' Multiple buttons that have the same action must be pressed simultaneously to invoke the action.': '  具有相同动作的多个按钮必须同时按下才能执行该动作。',
    'Plan View - Vehicle Disconnected': '计划视图 - 载具已断开',
    'RSSI': 'RSSI',
    'Signing:': '签名：',
    'Units': '单位',
}

# Handle the Thrust curve HTML separately
thrust_key = 'Thrust curve <b><a href="https://docs.px4.io/main/en/config_mc/pid_tuning_guide_multicopter.html#thrust-curve">?</a></b>'
thrust_val = '推力曲线 <b><a href="https://docs.px4.io/main/en/config_mc/pid_tuning_guide_multicopter.html#thrust-curve">?</a></b>'
T[thrust_key] = thrust_val

tree = ET.parse(ts_path)
root = tree.getroot()
filled = 0
for ctx in root:
    for msg in ctx.findall('message'):
        t = msg.find('translation')
        if t is not None and t.get('type') == 'unfinished':
            s = msg.find('source')
            src = s.text if s is not None and s.text else ''
            if src in T:
                t.text = T[src]
                if 'type' in t.attrib: del t.attrib['type']
                filled += 1
            elif src.strip() in T:
                t.text = T[src.strip()]
                if 'type' in t.attrib: del t.attrib['type']
                filled += 1

tree.write(ts_path, encoding='utf-8', xml_declaration=True)
print(f'Filled: {filled}')

# Verify
tree2 = ET.parse(ts_path)
root2 = tree2.getroot()
u = 0; f = 0
for ctx in root2:
    for msg in ctx.findall('message'):
        t = msg.find('translation')
        if t is not None:
            if t.get('type') == 'unfinished': u += 1
            else: f += 1
print(f'Final: Filled={f}, Unfinished={u}')
