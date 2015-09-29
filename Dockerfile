## -*- docker-image-name: "scaleway/diaspora:latest" -*-
FROM scaleway/ubuntu:trusty
MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)

# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter

# Install packages
RUN apt-get -q update \
 && apt-get -y -q upgrade \
 && apt-get install -y -q \
	build-essential \
	git \
	curl \
	imagemagick \
	libmagickwand-dev \
	nodejs \
	redis-server \
	libcurl4-openssl-dev \
	libxml2-dev \
	libxslt-dev \
	libpq-dev \
	gawk \
	libreadline6-dev \
	libyaml-dev \
	libsqlite3-dev \
	sqlite3 \
	autoconf \
	libgdbm-dev \
	libncurses5-dev \
	automake \
	bison \
	libffi-dev \
	postgresql \
	postgresql-contrib \
	nginx

RUN adduser --disabled-login --gecos 'diaspora' diaspora

# Install ruby
RUN su diaspora -c "curl -sSL https://rvm.io/mpapis.asc | gpg --import -" \
 && su diaspora -c "curl -L dspr.tk/1t | bash"
RUN su diaspora -c "source /home/diaspora/.rvm/scripts/rvm \
&& rvm autolibs read-fail \
&& rvm install 2.1"

# Install diaspora
RUN git clone -b master git://github.com/diaspora/diaspora.git /home/diaspora/diaspora \
 && cd /home/diaspora/diaspora \
 && cp config/database.yml.example config/database.yml \
 && cp config/diaspora.yml.example config/diaspora.yml

RUN chown -R diaspora:diaspora /home/diaspora/diaspora 

ADD patches/home/diaspora/diaspora/config/ /home/diaspora/diaspora/config/

RUN su diaspora -c "source /home/diaspora/.rvm/scripts/rvm \
  && cd /home/diaspora/diaspora \
  && gem install bundler \
  && RAILS_ENV=production DB=postgres bundle install --without test development"

ADD ./patches/etc/ /etc/
ADD ./patches/usr/ /usr/

RUN ln -sf /etc/nginx/sites-available/diaspora /etc/nginx/sites-enabled/diaspora && \
    rm -f /etc/nginx/sites-enabled/default

RUN /etc/init.d/postgresql start \
 && su postgres -c "createuser -s diaspora" \
 && sudo -u postgres psql -d template1 -c "ALTER USER diaspora WITH PASSWORD 'tmpwd';"  \
 && sed -i "s/password:.*/password: 'tmpwd'/g" /home/diaspora/diaspora/config/database.yml \
 && su diaspora -c "source /home/diaspora/.rvm/scripts/rvm \
  && cd /home/diaspora/diaspora \
  && RAILS_ENV=production DB=postgres rake db:create db:schema:load \
  && RAILS_ENV=production DB=postgres bin/rake assets:precompile" \
 && /etc/init.d/postgresql stop


RUN /usr/local/sbin/builder-leave
