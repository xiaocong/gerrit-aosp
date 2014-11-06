FROM        ubuntu:14.10
MAINTAINER  Xiaocong He <xiaocong@gmail.com>

# update apt sources
RUN apt-get update

# install
RUN         apt-get install -y \
                openjdk-7-jdk \
                openssh-server \
                git \
                curl

RUN         mkdir /var/run/sshd
RUN         echo 'root:!QAZ2wsx3edc' | chpasswd
RUN         sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN         sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN         echo "export VISIBLE=now" >> /etc/profile

ENV GERRIT_HOME /home/gerrit
ENV GERRIT_ROOT /home/gerrit/gerrit
ENV GERRIT_USER gerrit
ENV GERRIT_WAR /home/gerrit/gerrit.war
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
DEBIAN_FRONTEND=noninteractive apt-get -y update && \
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo vim-tiny git && \
DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor

RUN useradd -m $GERRIT_USER
RUN mkdir -p $GERRIT_HOME
RUN chown ${GERRIT_USER}:${GERRIT_USER} $GERRIT_HOME

RUN mkdir -p /var/log/supervisor
ADD http://gerrit-releases.storage.googleapis.com/gerrit-2.9.war $GERRIT_WAR
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chown -R ${GERRIT_USER}:${GERRIT_USER} $GERRIT_HOME

USER gerrit
CMD ["/usr/bin/ls","/home/gerrit"]

RUN java -jar $GERRIT_WAR init --batch -d $GERRIT_ROOT
RUN rm $GERRIT_WAR
RUN chown -R ${GERRIT_USER}:${GERRIT_USER} $GERRIT_ROOT
RUN mkdir ${GERRIT_HOME}/git

ADD gerrit.config /home/gerrit/gerrit/etc/gerrit.config

USER root
VOLUMN ["/home/gerrit/git"]
EXPOSE 8080 28080
EXPOSE 22 20022
EXPOSE 29418 29418
CMD ["/usr/sbin/service","supervisor","start"]

