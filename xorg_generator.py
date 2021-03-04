#!/usr/bin/env python3

import subprocess
import re
import sys


class Section(object):
    def __init__(self, content):
        self.content = content
        self.type = self.__get_section_type(content)

    def get_content(self):
        return self.content

    def set_content(self, content):
        self.content = content

    def get_type(self):
        return self.type

    def create_new_identifier(self, seq_no):
        new_identifier = Section(self.get_content())
        iname = new_identifier.get_content().replace(
            self.type + '0', self.type + str(seq_no))
        new_identifier.set_content(iname)
        return new_identifier

    def append_line(self, item):
        tmp_content = ''
        list_of_lines = self.content.split('\n')
        for i, line in enumerate(list_of_lines):
            if i == len(list_of_lines) - 2:
                tmp_content += line + '\n'
                tmp_content += item + '\n'
            elif i == len(list_of_lines) - 1:
                tmp_content += line
            else:
                tmp_content += line + '\n'
        self.content = tmp_content

    def __get_section_type(self, content):
        first_line = content.split('\n')[0]
        type_name = re.search('"(.*)"', first_line).group().replace('\"', '')
        return type_name


class AllSections(object):
    def __init__(self, content):
        self.section_list = []
        self.__content = content
        self.__sep_section()

    def get_content(self):
        self.__content = ''
        for section in self.section_list:
            self.__content += section.get_content() + '\n' + '\n'
        return self.__content

    def add_section(self, section):
        self.section_list.append(section)
        self.__content = ''
        for section in self.section_list:
            self.__content += section.get_content() + '\n'

    def search_section(self, type_name):
        for section in self.section_list:
            if section.get_type() == type_name:
                return section

    def delete_section(self, type_name):
        for i, section in enumerate(self.section_list):
            if section.get_type() == type_name:
                self.section_list.pop(i)
                break

    def struct_multi_screen(self, times=5):
        after_sections = AllSections(self.__content)
        after_sections.delete_section('Monitor')
        after_sections.delete_section('Device')
        after_sections.delete_section('Screen')
        for i in range(times):
            # Monitor
            original_monitor = self.search_section('Monitor')
            new_monitor = original_monitor.create_new_identifier(i)
            after_sections.add_section(new_monitor)
            # Device
            original_device = self.search_section('Device')
            new_device = original_device.create_new_identifier(i)
            new_device.append_line('    Option         "AllowExternalGpus" "True"')
            new_device.append_line('    Screen         ' + str(i))
            after_sections.add_section(new_device)
            # Screen
            original_screen = self.search_section('Screen')
            new_screen = original_screen.create_new_identifier(i)
            new_screen.set_content(new_screen.get_content()
                                   .replace('Device0', 'Device' + str(i)))
            new_screen.set_content(new_screen.get_content()
                                   .replace('Monitor0', 'Monitor' + str(i)))
            after_sections.add_section(new_screen)
            # ServerLayout
            if i != 0:
                serverlayout = after_sections.search_section('ServerLayout')
                tmp_setting = '    Screen      {}  "Screen{}" leftOf "Screen0"'\
                              .format(str(i), str(i))
                serverlayout.append_line(tmp_setting)
        return after_sections

    def __sep_section(self):
        is_wip = False
        tmp_section = ''
        for line in self.__content.split('\n'):
            if line.startswith('Section'):
                is_wip = True
                tmp_section += line + '\n'
                continue
            if line.startswith('EndSection'):
                is_wip = False
                tmp_section += line
                section = Section(tmp_section)
                self.section_list.append(section)
                tmp_section = ''
                continue
            if is_wip:
                tmp_section += line + '\n'
                continue


class SourceXorgConf(object):
    def __init__(self, resolution):
        self.path = "/tmp/.xorg.conf"
        self.content = ""
        self.__exec_nvidia_xconfig(resolution)

    def get_content(self):
        return self.content

    def __exec_nvidia_xconfig(self, resolution):
        p1 = subprocess.Popen(["nvidia-xconfig", "--query-gpu-info"],
                              stdout=subprocess.PIPE)
        p2 = subprocess.Popen(["grep", "PCI BusID"],
                              stdin=p1.stdout, stdout=subprocess.PIPE)
        p3 = subprocess.Popen(["sed", "-r", "s/\\s*PCI BusID : PCI:(.*)/\\1/"],
                              stdin=p2.stdout, stdout=subprocess.PIPE)
        p1.stdout.close()
        p2.stdout.close()
        bus_id = p3.communicate()[0].decode('utf-8').rstrip()
        ret = subprocess.run(["nvidia-xconfig",
                              "-o", self.path,
                              "--busid", bus_id,
                              "--virtual", resolution,
                              "--depth=24",
                              "--use-display-device=None",
                              "--allow-empty-initial-configuration",
                              "--enable-all-gpus"],
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        if ret.returncode == 0:
            with open(self.path) as f:
                self.content = f.read()
        else:
            raise ChildProcessError()


class DestXorgConf(object):
    def __init__(self, all_sections):
        self.path = "/etc/X11/xorg.conf"
        self.all_sections = all_sections

    def save(self):
        with open(self.path, mode='w') as f:
            f.write(self.all_sections)

    def print(self):
        print(self.all_sections.get_content())


def main(quantity, resolution):
    try:
        src = SourceXorgConf(resolution)
        all_sections = AllSections(src.get_content())
        new_sections = all_sections.struct_multi_screen(int(quantity))
        dst = DestXorgConf(new_sections)
        dst.print()
    except Exception:
        import traceback
        print(traceback.format_exc())


if __name__ == '__main__':
    args = sys.argv
    if len(args) >= 3:
        main(args[1], args[2])
        exit(0)
    else:
        print('Please specify the argument.')
        print(' [0]: Monitor quantity(int)')
        print(' [0]: Monitor Resolution(str) e.g. 1280x720')
        exit(1)
