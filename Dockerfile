FROM alpine
MAINTAINER Riad Vargas de Oliveira riad@leafhost.com.br

RUN addgroup -S -g 5000 vmail
RUN adduser -S -u 5000 -g vmail vmail
RUN apk add --update postfix postfix-mysql acf-dovecot openssl dovecot-mysql rsyslog
ADD postfix /etc/postfix
ADD dovecot /etc/dovecot

RUN chgrp postfix /etc/postfix/mysql-*.cf && \
    chgrp vmail /etc/dovecot/dovecot.conf && \
    chmod g+r /etc/dovecot/dovecot.conf

RUN postconf -e virtual_uid_maps=static:5000 && \
    postconf -e virtual_gid_maps=static:5000 && \
    postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf && \
    postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf && \
    postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf,mysql:/etc/postfix/mysql-email2email.cf && \
    postconf -e virtual_transport=dovecot && \
    postconf -e dovecot_destination_recipient_limit=1 && \
    # specially for docker
    postconf -F '*/*/chroot = n'

RUN echo "dovecot   unix  -       n       n       -       -       pipe"  >> /etc/postfix/master.cf && \
    echo '    flags=DRhu user=vmail:vmail argv=/usr/libexec/dovecot/deliver -d ${recipient}' >> /etc/postfix/master.cf

ADD start.sh /start.sh  

#SMTP ports
EXPOSE 25
EXPOSE 587  
# POP and IMAP ports  
EXPOSE 110
EXPOSE 143
EXPOSE 995
EXPOSE 993

CMD sh start.sh
