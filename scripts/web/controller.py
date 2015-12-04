#!/usr/bin/env python

"""
Usage: controller.py -o <overview.txt> -out <output_folder> -conf <config.yaml> -templates <template_folder> [--viewer]

-h --help     Please enter an overview.txt file, config file, template and an output folder. Specify --viewer if you want
              to show the genome viewer.
              Output folder must include a file overview_new.txt.
"""
from docopt import docopt
from sys import argv
from jinja2 import Environment, PackageLoader, FileSystemLoader
import yaml

def main():
    args = docopt(__doc__, argv[1:])
    overview_path = args['<overview.txt>']
    output_folder = args['<output_folder>']
    config_path = args['<config.yaml>']
    viewer = args['--viewer']
    template_folder = args['<template_folder>']
    config = load_config(config_path)
    config["viewer"] = viewer
    html_content = build_html(config, template_folder)
    write_html(output_folder + "/overview.html", html_content)

def build_html(conf, template_folder):
    env = Environment(loader=FileSystemLoader(template_folder))
    template = env.get_template('overview.html')
    return template.render(conf)

def write_html(output_file, html_content):
    with open(output_file, "wb") as fh:
        fh.write(html_content.encode('utf-8'))

def load_config(path):
    with open(path, 'r') as stream:
        return yaml.load(stream)


if __name__ == '__main__':
    main()
