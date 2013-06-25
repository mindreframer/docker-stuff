from __future__ import print_function, unicode_literals

import logging
import os
import sys
import warnings

# Filter annoying warnings from argh about bash completion
warnings.filterwarnings('ignore', '.*argcomplete.*')

from argh import arg, expects_obj, ArghParser

from . import __version__
from .gantry import Gantry, GantryError, DOCKER_DEFAULT_URL

_user_loglevel = os.environ.get('GANTRY_LOGLEVEL', '').upper()

# If a loglevel wasn't explicitly specified, make requests a bit quieter
if not _user_loglevel:
    logging.getLogger("requests").setLevel(logging.WARNING)

_loglevel = getattr(logging, _user_loglevel, logging.INFO)
logging.basicConfig(format='%(levelname)s: %(message)s', level=_loglevel)


@arg('-f', '--from-tag', required=True)
@arg('-t', '--to-tag', required=True)
@arg('--no-stop', action='store_true',
     help="Don't stop previously-deployed containers automatically")
@arg('repository')
@expects_obj
def deploy(args):
    gantry = Gantry(args.docker_url)
    try:
        gantry.deploy(args.repository,
                      args.to_tag,
                      args.from_tag,
                      stop=not args.no_stop)
    except GantryError as e:
        print(str(e))
        sys.exit(1)


@arg('repository')
@arg('-t', '--tags',
     help='Only list containers with the specified tags '
          '(supplied as a comma-separated list)')
@arg('-x', '--exclude-tags',
     help='Exclude containers with the specified tags '
          '(supplied as a comma-separated list)')
@expects_obj
def containers(args):
    gantry = Gantry(args.docker_url)
    tags = args.tags.split(',') if args.tags else None
    exclude_tags = args.exclude_tags.split(',') if args.exclude_tags else None
    for c in gantry.containers(args.repository,
                               tags=tags,
                               exclude_tags=exclude_tags):
        print(c['Id'])


@arg('repository')
@arg('-t', '--tags',
     help='Only list containers with the specified tags '
          '(supplied as a comma-separated list)')
@arg('-x', '--exclude-tags',
     help='Exclude containers with the specified tags '
          '(supplied as a comma-separated list)')
@arg('-q', '--quiet', default=False)
@expects_obj
def ports(args):
    gantry = Gantry(args.docker_url)
    tags = args.tags.split(',') if args.tags else None
    exclude_tags = args.exclude_tags.split(',') if args.exclude_tags else None
    if not args.quiet:
        print("%10s %10s" % ("host_port", "guest_port"))
    for p in gantry.ports(args.repository,
                          tags=tags,
                          exclude_tags=exclude_tags):
        print("%10d %10d" % (p[0], p[1]))

parser = ArghParser(version=__version__)
parser.add_argument('--docker-url', default=DOCKER_DEFAULT_URL)
parser.add_commands([deploy, containers, ports])


def main():
    parser.dispatch()


if __name__ == '__main__':
    main()
