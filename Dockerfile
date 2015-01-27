# Version: 0.0.9

FROM centos:centos6

MAINTAINER Nick McSpadden "nmcspadden@gmail.com"

ADD http://downloads.solarwinds.com/solarwinds/Release/WebHelpDesk/12.2.0/webhelpdesk-12.2.0-1.x86_64.rpm.gz /webhelpdesk.rpm.gz 
RUN gunzip -dv /webhelpdesk.rpm.gz
RUN yum install -y /webhelpdesk.rpm && rm /webhelpdesk.rpm && yum clean all
RUN cp /usr/local/webhelpdesk/conf/whd.conf.orig /usr/local/webhelpdesk/conf/whd.conf
RUN sed -i 's/^PRIVILEGED_NETWORKS=[[:space:]]*$/PRIVILEGED_NETWORKS=172.17.42.1/g' /usr/local/webhelpdesk/conf/whd.conf

EXPOSE 8081

CMD ["/usr/local/webhelpdesk/whd", "start"]
