## -*- docker-image-name: "scaleway/ruby:latest" -*-
FROM scaleway/ruby:latest
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
	mysql-server \
	nginx \
	mailutils \
	libmysqlclient-dev \
	supervisor

# Create diaspora user
RUN adduser --disabled-password --shell /bin/bash --gecos 'diaspora' diaspora \
  && usermod -a -G rvm diaspora

# Install diaspora
RUN git clone -b master git://github.com/diaspora/diaspora.git /home/diaspora/diaspora \
 && cd /home/diaspora/diaspora \
 && cp config/database.yml.example config/database.yml \
 && cp config/diaspora.yml.example config/diaspora.yml

RUN chown -R diaspora:diaspora /home/diaspora/diaspora

ADD patches/home/diaspora/diaspora/config/ /home/diaspora/diaspora/config/

RUN su diaspora -c "source /usr/local/rvm/scripts/rvm \
  && cd /home/diaspora/diaspora \
  && gem install bundler \
  && RAILS_ENV=production DB=mysql bundle install --without test development"

ADD ./patches/etc/ /etc/
ADD ./patches/usr/ /usr/

RUN ln -sf /etc/nginx/sites-available/diaspora /etc/nginx/sites-enabled/diaspora && \
    rm -f /etc/nginx/sites-enabled/default

RUN /etc/init.d/mysql start \
 && mysql -u root -e "CREATE DATABASE IF NOT EXISTS diaspora_production DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_bin;" \
 && su diaspora -c "source /usr/local/rvm/scripts/rvm \
 && cd /home/diaspora/diaspora \
 && RAILS_ENV=production DB=mysql rake db:create db:schema:load \
 && RAILS_ENV=production DB=mysql bin/rake assets:precompile" \
 && /etc/init.d/mysql stop

RUN /usr/local/sbin/builder-leave
