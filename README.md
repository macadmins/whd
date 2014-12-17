whdDocker
=========

This is a Dockerized version of [WebHelpDesk](http://www.webhelpdesk.com/).  This is based on the RHEL rpm installed on a CentOS 6 base.

How to use WebHelpDesk with Docker:
=========

Installing Docker:
------

This guide was done on CentOS 6.5.  It should work about the same for any
other RedHat-based platform, including Fedora and RHEL.  For Ubuntu or Debian,
you'd have to replace the yum commands with applicable apt-get install
commands.

1. yum install -y epel-release
2. yum install -y git
3. yum install -y docker-io
    1. **Enable testing repo: --enablerepo=epel-testing, allows you to skip next step, installs 1.3.2**
4. **Manually update Docker:**
    1. service docker stop
    2. killall docker
    3. wget [https://get.docker.com/builds/Linux/x86_64/docker-latest](https://get.docker.com/builds/Linux/x86_64/docker-latest) -O docker
    4. chmod +x docker
    5. mv docker /usr/bin/docker
    6. service docker start
5. chkconfig docker on
6. docker -v
7. docker pull postgres
8. docker pull nmcspadden/whd

Preparing Database Setup Scripts:
-----

 1. curl -O [https://raw.githubusercontent.com/nmcspadden/whdDocker/master/setup_whd_db.sh](https://raw.githubusercontent.com/nmcspadden/whdDocker/master/setup_whd_db.sh)
      1. chmod +x setup_whd_db.sh
      2. Change DB settings:
        1. DB_NAME=whd
        2. DB_USER=whddbadmin
        3. DB_PASS=password


Prepare the data container for the DB:
-----

1. docker run -d --name whd-db-data --entrypoint /bin/echo nmcspadden/postgres-whd Data-only container for postgres-whd
2. docker run -d --name postgres-whd --volumes-from whd-db-data nmcspadden/postgres-whd
3. ./setup_whd_db.sh

Prepare the data container for WHD:
-----

1. docker run -d --name whd-data --entrypoint /bin/echo nmcspadden/whd Data-only container for whd
2. docker run -d -p 8081:8081 --link postgres-whd:db --name "whd" --volumes-from whd-data nmcspadden/whd


Configure WHD Through Browser:
----

1. Open Web Browser: localhost:8081
2. Set up using Custom SQL Database:
      1. Database type: postgreSQL (External)
      2. Host: db
      3. Port: 5432
      4. Database Name: whd
      5. Username: whddbadmin
      6. Password: password
3. Skip email customization
4. Setup administrative account/password
5. Choose "IT General/Other"

