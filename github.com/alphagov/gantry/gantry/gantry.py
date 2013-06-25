from __future__ import print_function, unicode_literals

import logging
import subprocess

import docker

DOCKER_DEFAULT_URL = 'http://localhost:4243'

log = logging.getLogger(__name__)


class GantryError(Exception):
    pass


class Gantry(object):

    def __init__(self, docker_url=DOCKER_DEFAULT_URL):
        self.client = docker.Client(docker_url)

    def deploy(self, repository, to_tag, from_tag, stop=True):
        """
        For the specified repository, spin up as many containers of
        <repository>:<to_tag> as there are currently running containers of
        <repository>:<from_tag>, or just one if there are no currently running
        containers.

        Once the new containers have started, stop the old containers.
        """
        images, tags, containers = self.fetch_state(repository)

        try:
            from_image = tags[from_tag]
        except KeyError:
            # If there is no matching image for from_tag, behave as if there
            # were no running containers for that image (i.e. spawn a single
            # container of the to_tag)
            log.warn('Image %s:%s not found (looking for from_tag)' %
                     (repository, from_tag))
            from_image = None

        try:
            to_image = tags[to_tag]
        except KeyError:
            raise GantryError('Image %s:%s not found (looking for to_tag)' %
                              (repository, to_tag))

        from_containers = filter(lambda ct: ct['Image'] == from_image,
                                 containers)
        num_containers = max(1, len(from_containers))

        log.info("Starting %d containers with %s:%s",
                 num_containers,
                 repository,
                 to_tag)

        for i in xrange(num_containers):
            retcode = _start_container(to_image)
            if retcode != 0:
                raise GantryError("Failed to start container from image %s" %
                                  to_image)

        log.info("Started %d containers", num_containers)

        if not stop:
            return

        log.info("Shutting down %d old containers with %s:%s",
                 len(from_containers),
                 repository,
                 from_tag)

        self.client.stop(*map(lambda ct: ct['Id'], from_containers))

        log.info("Shut down %d old containers", len(from_containers))

    def containers(self, repository, tags=None, exclude_tags=None):
        """
        Return a list of all currently-running containers for the specified
        repository.
        """
        images, image_tags, containers = self.fetch_state(repository)

        if tags is None and exclude_tags is None:
            return containers

        def wanted(c):
            matches_tags = True
            matches_excludes = False

            if tags is not None:
                matches = map(lambda t: c['Image'] == image_tags.get(t), tags)
                matches_tags = True in matches

            if exclude_tags is not None:
                matches = map(lambda t: c['Image'] == image_tags.get(t),
                              exclude_tags)
                matches_excludes = True in matches

            return matches_tags and not matches_excludes

        return filter(wanted, containers)

    def ports(self, repository, tags=None, exclude_tags=None):
        """
        Return a list of all forwarded ports for currently-running containers
        for the specified repository.
        """
        ports = []
        for c in self.containers(repository,
                                 tags=tags,
                                 exclude_tags=exclude_tags):
            if 'Ports' in c:
                ports.extend(_parse_ports(c['Ports']))
        return ports

    def fetch_state(self, repository):
        images, tags = self._fetch_images(repository)
        containers = []
        for c in self.client.containers():
            if ':' in c['Image']:
                # Normalize "repo:tag" Image references to an image id
                repo, tag = c['Image'].split(':', 1)
                if repo != repository:
                    continue
                if tag not in tags:
                    raise GantryError(
                        "Found tag %s with no corresponding image entry" % tag)
                c['Image'] = tags[tag]
                containers.append(c)
            else:
                # Normalize short id to full id
                for img_id in images.keys():
                    if len(c['Image']) == 12 and img_id.startswith(c['Image']):
                        c['Image'] = img_id
                        containers.append(c)
        return images, tags, containers

    def _fetch_images(self, repository):
        images = {}
        tags = {}
        for img in self.client.images(repository):
            if img['Id'] not in images:
                images[img['Id']] = img
            try:
                tag = img.pop('Tag')
            except KeyError:
                continue
            tags[tag] = img['Id']
        return images, tags


def _start_container(img_id):
    # FIXME: This should use the HTTP client, but the Python bindings are
    # out of date and don't support run() without a command, which is what
    # we need for our images build with the CMD Dockerfile directive.
    args = ['docker', 'run', '-d']

    resolvers = _get_guest_resolvers()
    if not resolvers:
        log.warn("Starting container with an empty set of resolvers. "
                 "You probably want to have at least one non-loopback "
                 "resolver defined in /etc/resolv.conf")

    for r in resolvers:
        args.extend(['-dns', r])

    args.append(img_id)

    p = subprocess.Popen(args)
    return p.wait()


def _get_guest_resolvers():
    """
    Return an ordered list of nameservers appropriate for guest use
    """
    return filter(lambda x: x not in ['::1', '127.0.0.1'],
                  _get_host_resolvers())


def _get_host_resolvers():
    """
    Return an ordered list of host nameservers
    """
    with open('/etc/resolv.conf') as fp:  # pragma: no cover
        return _parse_resolv_conf(fp.read())


def _parse_resolv_conf(contents):
    """
    Return a list of nameservers declared in ``contents``, a string with
    resolv.conf-like syntax.
    """
    resolvers = []
    for line in contents.splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[0] == 'nameserver':
            resolvers.append(fields[1])
    return resolvers


def _parse_ports(ports):
    """
    Parse docker's ports output into a list of (host, guest) port pairs
    """
    if ports:
        return [map(int, p.split('->', 1)) for p in ports.split(', ')]
    else:
        return []
