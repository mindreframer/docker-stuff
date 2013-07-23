FROM base
MAINTAINER Evan Hazlett "ejhazlett@gmail.com"
RUN apt-get -qq update
RUN apt-get install -y python-dev python-setuptools libxml2-dev libxslt-dev libmysqlclient-dev supervisor redis-server git-core
RUN easy_install pip
RUN pip install virtualenv
RUN pip install uwsgi
RUN virtualenv --no-site-packages /opt/ve/shipyard
ADD . /opt/apps/shipyard
ADD .docker/supervisor.conf /opt/supervisor.conf
ADD .docker/known_hosts /root/.ssh/known_hosts
ADD .docker/run.sh /usr/local/bin/run
RUN (cd /opt/apps/shipyard && rm shipyard.db)
RUN (cd /opt/apps/shipyard && git remote rm origin)
RUN (cd /opt/apps/shipyard && git remote add origin https://github.com/ehazlett/shipyard.git)
RUN /opt/ve/shipyard/bin/pip install -r /opt/apps/shipyard/requirements.txt
RUN (cd /opt/apps/shipyard && /opt/ve/shipyard/bin/python manage.py syncdb --noinput)
RUN (cd /opt/apps/shipyard && /opt/ve/shipyard/bin/python manage.py migrate)
RUN (cd /opt/apps/shipyard && /opt/ve/shipyard/bin/python manage.py update_admin_user --username=admin --password=shipyard)

EXPOSE 8000
CMD ["/bin/sh", "-e", "/usr/local/bin/run"]
