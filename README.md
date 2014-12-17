whdDocker
=========

This is a Dockerized version of [WebHelpDesk](http://www.webhelpdesk.com/).  This is based on the RHEL rpm installed on a CentOS 6 base.

How To Setup Sal, Sal-WHD, and JSSImport with Docker:
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
    1.**Enable testing repo: --enablerepo=epel-testing, allows you to skip Step 5, installs 1.3.2**
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
8. docker pull centos:centos6
9. docker pull nmcspadden/whd

Preparing Data Files:
------

1. git clone [https://github.com/nmcspadden/MacModelShelf.git](https://github.com/nmcspadden/MacModelShelf.git) /usr/local/sal_data/macmodelshelf

Preparing Database Setup Scripts:
-----

 1. curl -O [https://raw.githubusercontent.com/nmcspadden/whdDocker/master/setup_whd_db.sh](https://raw.githubusercontent.com/nmcspadden/whdDocker/master/setup_whd_db.sh)
      1. chmod +x setup_whd_db.sh
      2. Change DB settings:
        1. DB_NAME=whd
        2. DB_USER=whddbadmin
        3. DB_PASS=password


Run the WHD DB To Prepare the Configurations:
-----

1. docker run -d -v /usr/local/whd_data/db:/var/lib/postgresql/data --name "postgres-whd" postgres
2. docker stop postgres-whd
3. docker rm postgres-whd
4. Change /usr/local/whd_data/db/pg_hba.conf:
    1. Add "host all all 172.17.0..1/16 trust" to IPv4 Local Connections
    2. sed -i '/host    all             all             127.0.0.1\/32            trust/a host    all             all             172.17.0.1\/16            trust' /usr/local/whd_data/db/pg_hba.conf
5. docker run -d -v /usr/local/whd_data/db:/var/lib/postgresql/data --name "postgres-whd" postgres
6. ./setup_whd_db.sh

Prepare the Conf Files and Run WHD:
-----

1. docker run -d -p 8081:8081 --link postgres-sal:saldb --link postgres-whd:db --name "whd" nmcspadden/whd
2. docker cp whd:/usr/local/webhelpdesk/conf /usr/local/whd_data/
       * **We need to copy out the conf to feed it back in later - it's possible in the future that we can just provide this ahead of time, but for now, we need to copy it out and reload the Docker container with the conf directory.**
4. docker stop whd
5. docker rm whd
6. docker run -d -p 8081:8081 --link postgres-sal:saldb --link postgres-whd:db -v /usr/local/whd_data/conf:/usr/local/webhelpdesk/conf --name "whd" nmcspadden/whd

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

