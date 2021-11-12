import yaml
import collections.abc
import crypt
from getpass import getpass
import time
from collections import namedtuple

def update(d, u):
    for k, v in u.items():
        if isinstance(v, collections.abc.Mapping):
            d[k] = update(d.get(k, {}), v)
        else:
            d[k] = v
    return d

def value(d, u):
    for k, v in u.items():
        if isinstance(v, collections.abc.Mapping):
            return value(d.get(k, {}), v)
        else:
            return d[k]

def find_and_replace_kickstart_late_command(x, pattern, value):
    x = x.replace('\n', '')
    while '  ' in x:
        x = x.replace('  ', ' ')

    if pattern in x:
        x = x.replace(pattern, value)

    return x

def main():
    autoinstall_filename = '/autoinstall.yaml'
    
    DynamicPromptEntry = namedtuple('DynamicPromptEntry', 'prompt_fnc, label, show_default, yaml_key_fnc')

    dynamic_prompts = {
        'HOSTNAME': DynamicPromptEntry(input, 'Hostname', True,
                                       lambda x: {'identity': {'hostname': x}}),
        'PASSWORD': DynamicPromptEntry(getpass, 'Password: (leave blank for no change)', False, 
                                       lambda x: {'identity': {'password': crypt.crypt(x, crypt.mksalt(crypt.METHOD_SHA512))}})
    }

    with open(autoinstall_filename, 'r') as f:
        data = yaml.safe_load(f)

    for pe in dynamic_prompts.values():
        default_text = ''
        if pe.show_default:
            default_text = '(Default: %s)' % value(data, pe.yaml_key_fnc(''))

        usrin = pe.prompt_fnc('%s: %s ' % (pe.label, default_text))

        if usrin:
            update(data, pe.yaml_key_fnc(usrin))

    install_type = ''
    while not install_type in ['master', 'slave']:
        install_type = input('InstallType [master/slave]:')

    data['late-commands'] = list(map(lambda x: find_and_replace_kickstart_late_command(x, "INSTALL_TYPE", install_type), data['late-commands']))
    data['late-commands'] = list(map(lambda x: find_and_replace_kickstart_late_command(x, "PASSWORD", "'"+data['identity']['password']+"'"), data['late-commands']))

    with open(autoinstall_filename, 'w') as f:
        yaml.safe_dump(data, f,
            default_flow_style=False,
            indent=4,
            allow_unicode=True,
            explicit_start=True,
            explicit_end=True)

if __name__ == '__main__':
    main()
