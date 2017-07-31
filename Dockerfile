## -*- docker-image-name: "vr/rails-base" -*-

FROM debian:jessie 
MAINTAINER josef@voicerepublic.com

## Essentials
RUN apt-get update && \
    apt-get install make openssh-client wget curl git -y

## Java 8 Oracle
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update && \
    apt-get install oracle-java8-installer -y 

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
   
## Leiningen
RUN curl https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > /usr/bin/lein && \
    chmod a+x /usr/bin/lein && \
    lein

## Node 7
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash && \
    apt-get install -y nodejs 

# Ruby 2.1.2 install ruby dependencies
#RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
#    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
#    echo 'eval "$(rbenv init - $SHELL)"' >> ~/.bashrc && \
#    export PATH="$HOME/.rbenv/bin:$PATH" && \
#    eval "$(rbenv init - $SHELL)" && \
#    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build && \
#    apt-get install -y build-essential bzip2 libssl-dev libreadline-dev zlib1g-dev 

#RUN rbenv install -s 2.1.2 && \
#    rbenv global 2.1.2 && \
#    gem install bundler && \
#    rbenv rehash
# Install ruby-build
RUN apt-get update && apt-get install -y curl \
  autoconf \
  bison \
  build-essential \
  libssl-dev \
  libyaml-dev \
  libreadline6-dev \
  zlib1g-dev \
  libpq-dev \ 
  libncurses5-dev

RUN curl -L https://github.com/sstephenson/ruby-build/archive/v20140926.tar.gz -o ruby-build.tar.gz &&\
  tar -xzf ruby-build.tar.gz &&\
  rm ruby-build.tar.gz &&\
  ruby-build-20140926/install.sh &&\
  rm -rf ruby-build-20140926

# Install Ruby 2.1.2 and Bundler
RUN /usr/local/bin/ruby-build 2.1.2 /opt/ruby-2.1.2
RUN /opt/ruby-2.1.2/bin/gem install bundler

# set up path for all users
ENV PATH /opt/ruby-2.1.2/bin:$PATH
RUN echo "PATH=/opt/ruby-2.1.2/bin:$PATH" >> /etc/profile

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock /usr/src/app/
     
RUN apt-get update -y && \
    apt-get install -y curl && \
    curl -L https://raw.githubusercontent.com/dockito/vault/master/ONVAULT > /usr/local/bin/ONVAULT && \
    chmod +x /usr/local/bin/ONVAULT

RUN ONVAULT bundle install

