DEPLOYMENT NOTES
================

Components Overview
-------------------

* rails app
* multiple djs for separate queues
* rtmpd (nginx)
* private_pub (faye)
* localeapp


Issue 'missing bundler' -- Resolved
-----------------------------------

As user `app`

    app@voicerepublic-staging:~$ rbenv versions
      1.9.3-p448
    app@voicerepublic-staging:~$ bundle
    -bash: bundle: command not found
    app@voicerepublic-staging:~$ gem
    rbenv: gem: command not found
    
    The `gem' command exists in these Ruby versions:
      1.9.3-p448
    app@voicerepublic-staging:~$ rbenv global 1.9.3-p448
    app@voicerepublic-staging:~$ rbenv versions
    * 1.9.3-p448 (set by /home/app/.rbenv/version)
    app@voicerepublic-staging:~$ gem install bundler
    Fetching: bundler-1.5.3.gem (100%)
    Successfully installed bundler-1.5.3
    1 gem installed
    Installing ri documentation for bundler-1.5.3...
    Installing RDoc documentation for bundler-1.5.3...
    app@voicerepublic-staging:~$ echo 'gem: --no-document' > .gemrc


Issue 'missing packages' -- Resolved
------------------------------------

As root

    [13:05:41] voicerepublic-staging:~# apt-get install postgresql-contrib-9.1 libpcre++-dev libav-tools
    ...


Issue 'PG::InsufficientPrivilege' -- Resolved
---------------------------------------------

As root

    [13:59:18] voicerepublic-staging:~# su - postgres
    [13:59:25] voicerepublic-staging:~$ psql rails_production
    psql (9.1.11)
    Type "help" for help.
    
    rails_production=# CREATE EXTENSION pg_trgm;
    CREATE EXTENSION
    rails_production=# CREATE EXTENSION unaccent;
    CREATE EXTENSION


Build & start rtmpd
-------------------

    app@voicerepublic-staging:~$ current
    app@voicerepublic-staging:~/app/current$ be rake rtmp:build
    created directory /home/app/app/shared/rtmp
    checking for nginx...
    fetching newest version (nginx-1.5.11)...
    checking for nginx-rtmp-module...
    fetching newest version (v1.1.3)...
    compiling (nginx-1.5.11/nginx-rtmp-module-1.1.3)...
    
    Good news everyone. You're all set.
    
      rake rtmp:(start|stop|restart)

    app@voicerepublic-staging:~/app/current$ be rake rtmp:start
    rtmpd started with pids 4199, 4200, 4201


Setup symlinks
--------------

    app@voicerepublic-staging:~/app/current$ be rake setup
    RECORDINGS /home/app/app/shared/recordings
    Create /home/app/app/shared/recordings
    RTMPBUILD  /home/app/app/shared/rtmp
    RECTEMP    /home/app/app/shared/rtmp/run/recordings
    symlink    /home/app/app/shared/rtmp/run/recordings
         ->    /home/app/app/shared/recordings


PrivatePub Config
-----------------

    app@voicerepublic-staging:~$ cp app/current/config/private_pub.yml app/shared/config/private_pub.yml
    app@voicerepublic-staging:~$ nano app/shared/config/private_pub.yml
    app@voicerepublic-staging:~$ cat app/shared/config/private_pub.yml 
    production:
      server: "http://voicerepublic-staging.sky.ungleich.ch:9292/faye"
      secret_token: "1ca35552f8b33e95302a951002a835fc39b6699ab2447f9140d36190fca0c0a7"
      signature_expiration: 7200 # two hours


TODO
----

### Setup Whenever in config/deploy.rb

### Open Ports

* 9292 (private_pub/faye) 
* 1935 (rtmp)

### Write Start/Stop Scripts

for daemons started via config/monit.conf

* dj ?
* private_pub
* rtmpd
* localeapp

### Fix Monit Config

### Setup multiple DJs for separate queues

#### Queue 'mail'

Low prio. No hurry. Process one at a time without puting burden on the
system.

#### Queue 'trigger'

High prio. Very cheap jobs, which should be handled in real time. The
jobs in this queue are set to run at a given time.

#### Queue 'process_audio'

Long running io heavy jobs. Process as fast as possible. Several might
show up at once. Process multiple in parallel?

#### Setup

    RAILS_ENV=production script/delayed_job --queue=mail start
    RAILS_ENV=production script/delayed_job --queue=trigger start
    RAILS_ENV=production script/delayed_job --queue=process_audio -n 15 start



Nice to have
------------

Debian packages

* tree
* multitail