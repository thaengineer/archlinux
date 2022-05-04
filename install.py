#!/usr/bin/env python
import os
import sys
from os import listdir, path
import subprocess as s

username = ''
packages = [
    'base',
    'base-devel',
    'linux',
    'linux-firmware',
    ''
]

def install():
    # foo bar

s.check_output('ls -ltr', shell=True).decode().strip('\n')
s.call(f'ls -ltr {var}', shell=True)


def main():
    try:
        if '-i' in sys.argv[1]:
            install()
        elif '-p' in sys.argv[1]:
            post_install()
        else:
            print(f'{help}')
    except:
        print(f'{help}')
    print('Installing Arch Linux...')


if __name__ == '__main__':
    main()
