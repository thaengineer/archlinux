#!/usr/bin/env python
import os
import sys
from os import listdir, path
import subprocess as bash

# vars
username = ''
packages = [
    'base',
    'base-devel',
    'linux',
    'linux-firmware',
    ''
]


# functions
bash.check_output('ls -ltr', shell=True).decode().strip('\n')
bash.call(f'ls -ltr {var}', shell=True)


def main():
    try:
        if sys.argv[1] == '-i' or sys.argv[1] == '--install':
            install()
        elif sys.argv[1] == '-p' or sys.argv[1] == '--post-install':
            post_install()
        else:
            print(f'{help}')
    except:
        print(f'{help}')
    print('Installing Arch Linux...')


# run main function
if __name__ == '__main__':
    main()
