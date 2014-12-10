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
8. docker pull grahamgilbert/postgres
9. docker pull centos:centos6
10. docker pull nmcspadden/whd
11. docker pull nmcspadden/salwhd

Preparing Data Files:
------

1. mkdir -p /usr/local/sal_data/settings/
2. curl -o /usr/local/sal_data/settings/settings.py [https://raw.githubusercontent.com/macadmins/sal/master/settings.py](https://raw.githubusercontent.com/macadmins/sal/master/settings.py)
    1. Make the following changes to settings.py:Add 'whdimport', to INSTALLED_APPS
3. curl -o /usr/local/sal_data/com.github.nmcspadden.prefs.json [https://raw.githubusercontent.com/nmcspadden/Sal-JSSImport/master/com.github.nmcspadden.prefs.json](https://raw.githubusercontent.com/nmcspadden/Sal-JSSImport/master/com.github.nmcspadden.prefs.json)
    1. Change password
4. curl -o /usr/local/sal_data/com.github.sheagcraig.python-jss.plist [https://raw.githubusercontent.com/nmcspadden/Sal-JSSImport/master/com.github.sheagcraig.python-jss.plist](https://raw.githubusercontent.com/nmcspadden/Sal-JSSImport/master/com.github.sheagcraig.python-jss.plist)
    1. Setup API user, host, and password
5. git clone [https://github.com/nmcspadden/MacModelShelf.git](https://github.com/nmcspadden/MacModelShelf.git) /usr/local/sal_data/macmodelshelf

Preparing Database Setup Scripts:
-----

 1. curl -O [https://raw.githubusercontent.com/macadmins/sal/master/setup_db.sh](https://raw.githubusercontent.com/macadmins/sal/master/setup_db.sh)
      1. chmod +x setup_db.sh
      2. Change postgres to grahamgilbert/postgres
      3. Change DB settings:
        1. DB_NAME=sal
        2. DB_USER=saldbadmin
        3. DB_PASS=password
2. curl -O [https://raw.githubusercontent.com/nmcspadden/salWHD/master/setup_jssi_db.sh](https://raw.githubusercontent.com/nmcspadden/salWHD/master/setup_jssi_db.sh)
      1. chmod +x setup_jssi_db.sh
      2. Change DB settings:
        1. DB_NAME=jssimport
        2. DB_USER=jssdbadmin
        3. DB_PASS=password
3. curl -O [https://raw.githubusercontent.com/nmcspadden/whdDocker/master/setup_whd_db.sh](https://raw.githubusercontent.com/nmcspadden/whdDocker/master/setup_whd_db.sh)
      1. chmod +x setup_whd_db.sh
      2. Change DB settings:
        1. DB_NAME=whd
        2. DB_USER=whddbadmin
        3. DB_PASS=password

Run the Sal DB and Setup Scripts:
-------

1. docker run --name "postgres-sal" -d -v /usr/local/sal_data/db:/var/lib/postgresql/data grahamgilbert/postgres
2. ./setup_db.sh
3. ./setup_jssi_db.sh

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

Run Temporary Sal to Prepare Initial Data Migration:
-----

If you want to load data from an existing Sal implementation, use `python
[manage.py](http://manage.py) dumpdata --format json > saldata.json` to export
the data, and then place the saldata.json into /usr/local/sal_data/saldata/.

1. docker run --name "sal-loaddata" --link postgres-sal:db -e ADMIN_PASS=password -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password -i -t --rm -v /usr/local/sal_data/saldata:/saldata -v /usr/local/sal_data/settings/settings.py:/home/docker/sal/sal/settings.py nmcspadden/salwhd /bin/bash
      1. cd /home/docker/sal
      2. python [manage.py](http://manage.py) syncdb --noinput
      3. python [manage.py](http://manage.py) migrate
      4. echo "TRUNCATE django_content_type CASCADE;" | python [manage.py](http://manage.py) dbshell | xargs
      5.         1. Equivalent to: # python [manage.py](http://manage.py) dbshell
        2. TRUNCATE django_content_type CASCADE;
        3. \q
      6. python [manage.py](http://manage.py) schemamigration whdimport --auto
      7.         1. This step may not be necessary
      8. python [manage.py](http://manage.py) migrate whdimport
      9. **If you want to import data : **python [manage.py](http://manage.py) loaddata /saldata/saldata.json
      10. exit
2. After exiting, the temporary "sal-loaddata" container is removed.

Run Sal and Sync the Database:
-----

1. docker run -d --name="sal" -p 80:8000 --link postgres-sal:db -e ADMIN_PASS=password -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password -v /usr/local/sal_data/settings/settings.py:/home/docker/sal/sal/settings.py -v /usr/local/sal_data/com.github.sheagcraig.python-jss.plist:/home/docker/sal/jssimport/com.github.sheagcraig.python-jss.plist -v /usr/local/sal_data/com.github.nmcspadden.prefs.json:/home/docker/sal/jssimport/com.github.nmcspadden.prefs.json nmcspadden/salwhd
2. docker exec sal python /home/docker/sal/manage.py syncmachines

Sync/Import the JSS into the Database:
-----

1. docker exec sal python /home/docker/sal/jssimport/jsspull.py --dbprefs "/home/docker/sal/jssimport/com.github.nmcspadden.prefs.json" --jssprefs "/home/docker/sal/jssimport/com.github.sheagcraig.python-jss.plist"

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

Setup Discovery Connections:
----

1. Setup discovery disconnection "Sal":
      1. Connection Name: "Sal" (whatever you want)
      2. Discovery Tool: Database Table or View
      3. Database Type: PostgreSQL - **uncheck Use Embedded Database**
      4. Host: saldb
      5. Port: 5432
      6. Database Name: sal
      7. Username: saldbadmin
      8. Password: password
      9. Schema: Public
      10. Table or View: whdimport_whdmachine
      11. Sync Column: serial
2. Setup discovery connection "Casper":
      1. Connection Name: "Casper" (whatever you want)
      2. Discovery Tool: Database Table or View
      3. Database Type: PostgreSQL - **uncheck Use Embedded Database**
      4. Host: saldb
      5. Port: 5432
      6. Database Name: jssimport
      7. Username: jssdbadmin
      8. Password: password
      9. Schema: Public
      10. Table or View: casperimport
      11. Sync Column: serial
