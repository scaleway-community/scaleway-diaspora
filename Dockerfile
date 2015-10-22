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
	mysql-server \
	nginx \
	mailutils \
	libmysqlclient-dev \
	supervisor

RUN adduser --disabled-login --gecos 'diaspora' diaspora

# Install ruby
RUN su diaspora -c "curl -sSL https://rvm.io/mpapis.asc | gpg --import -" \
 && su diaspora -c "curl -L dspr.tk/1t | bash" \
 && su diaspora -c "source /home/diaspora/.rvm/scripts/rvm \
  && rvm autolibs read-fail \
  && rvm install 2.1"

# Add patches
ADD ./patches/etc/ /etc/
ADD ./patches/usr/ /usr/
ADD patches/home/diaspora/diaspora/config/ /home/diaspora/diaspora/config/

# Install diaspora
RUN git clone -b master git://github.com/diaspora/diaspora.git /home/diaspora/diaspora \
 && cd /home/diaspora/diaspora \
 && cp config/database.yml.example config/database.yml \
 && cp config/diaspora.yml.example config/diaspora.yml \
 && chown -R diaspora:diaspora /home/diaspora/diaspora \
 && su diaspora -c "source /home/diaspora/.rvm/scripts/rvm \
  && cd /home/diaspora/diaspora \
  && gem install bundler \
  && RAILS_ENV=production DB=mysql bundle install --without test development"

# Configure Nginx
RUN ln -sf /etc/nginx/sites-available/diaspora /etc/nginx/sites-enabled/diaspora && \
    rm -f /etc/nginx/sites-enabled/default

# Configure database
RUN /etc/init.d/mysql start \
  && mysql -u root -e "CREATE DATABASE IF NOT EXISTS diaspora_production DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_bin;" \
  && su diaspora -c "source /home/diaspora/.rvm/scripts/rvm \
  && cd /home/diaspora/diaspora \
  && RAILS_ENV=production DB=mysql rake db:create db:schema:load \
  && RAILS_ENV=production DB=mysql bin/rake assets:precompile" \
 && /etc/init.d/mysql stop

RUN /usr/local/sbin/builder-leave
