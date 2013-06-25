import os
from setuptools import setup, find_packages

from gantry import __version__

requirements = ['argh==0.23.2',
                'docker-py==0.0.5']

HERE = os.path.dirname(__file__)
try:
    long_description = open(os.path.join(HERE, 'README.rst')).read()
except:
    long_description = None

setup(
    name='gantry',
    version=__version__,
    packages=find_packages(exclude=['test*']),
    include_package_data=True,

    # metadata for upload to PyPI
    author='Nick Stenning',
    author_email='nick@whiteink.com',
    url='https://github.com/alphagov/gantry',
    description='Gantry: deployment automation for Docker',
    long_description=long_description,
    license='MIT',
    keywords='sysadmin deployment docker automation',

    install_requires=requirements,
    entry_points={
        'console_scripts': [
            'gantry=gantry.command:main',
        ]
    }
)
