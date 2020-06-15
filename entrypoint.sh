#!/bin/bash

ACL=${ACL:-"192.168.0.0/24"};

function _start() {

    [ -f .init/init.sql ] && {
        # load initial DB Script
        echo ":: Loading initial config ...";
        set -xv;
        cat .init/init.sql | \
        mysql \
            -u"${DB_CONNECTION_USER}" \
            -p"${DB_CONNECTION_PASSWORD}" \
            -h"${DB_CONNECTION_HOST}" \
            -D"${DB_CONNECTION_DATABASE}" && {

                local myip=$(egrep $HOSTNAME /etc/hosts| cut -f 1);
                sed -e "s/127.0.0.1/${myip}/" -i .init/pjsip.conf;
                
                for file in  .init/*.conf; do
                    sed ${file} -e "s/__DB_CONNECTION_USER__/${DB_CONNECTION_USER}/g;s/__DB_CONNECTION_PASSWORD__/${DB_CONNECTION_PASSWORD}/g;s/__DB_CONNECTION_HOST__/${DB_CONNECTION_HOST}/g;s/__DB_CONNECTION_DATABASE__/${DB_CONNECTION_DATABASE}/g;s/__ACL__/${ACL}/g"  \
                    > /etc/asterisk/${file##*/} && echo "  -> /etc/asterisk/${file##*/}" && cat  /etc/asterisk/${file##*/};
                done

                sed .init/odbc.ini -e "s/__DB_CONNECTION_USER__/${DB_CONNECTION_USER}/g;s/__DB_CONNECTION_PASSWORD__/${DB_CONNECTION_PASSWORD}/g;s/__DB_CONNECTION_HOST__/${DB_CONNECTION_HOST}/g;s/__DB_CONNECTION_DATABASE__/${DB_CONNECTION_DATABASE}/g"  \
                > /etc/odbc.ini && echo "  -> /etc/odbc.ini" && cat  /etc/odbc.ini;

                cp -v .init/odbcinst.ini /etc;
                
                sed -e "/^sqlalchemy.url/s/sqlalchemy.url.*/sqlalchemy.url = mysql:\/\/${DB_CONNECTION_USER}:${DB_CONNECTION_PASSWORD}@${DB_CONNECTION_HOST}\/${DB_CONNECTION_DATABASE}/" -i /var/lib/asterisk/ast-db-manage/config.ini.sample && \
                echo "  -> /var/lib/asterisk/ast-db-manage/config.ini.sample" && cat  /var/lib/asterisk/ast-db-manage/config.ini.sample && \
                cd /var/lib/asterisk/ast-db-manage/ && \
                alembic -c ./config.ini.sample upgrade head && \
                cd -;

                cat .init/internal.sql | \
                mysql \
                    -u"${DB_CONNECTION_USER}" \
                    -p"${DB_CONNECTION_PASSWORD}" \
                    -h"${DB_CONNECTION_HOST}" \
                    -D"${DB_CONNECTION_DATABASE}";

                mv -v .init/init.sql .init/init.$(date -I).sql;

                sed -e "s/rtpend=20000/rtpend=10099/" -i /etc/asterisk/rtp.conf;
            }
        set +xv;
    }

    service asterisk start 2>/dev/null && \
    service asterisk status 2>/dev/null  && \
    echo ":: open for the business !" && \
    tail -f /dev/null
}

function main() {
    [ ! -z ${@} ] && {
        ${@}
        return $?;
    } 
    
    
    [ ! -z "${DB_CONNECTION_DATABASE}" ] && \
    [ ! -z "${DB_CONNECTION_USER}"     ] && \
    [ ! -z "${DB_CONNECTION_PASSWORD}" ] && \
    [ ! -z "${DB_CONNECTION_HOST}"     ] && {
        local i=0
        while [ $i -lt 30 ]; do
            i=$((i+1));
            nc -zv ${DB_CONNECTION_HOST} 3306 && {
                _start;
            }
            sleep 20;
            echo ":: waiting db in ${DB_CONNECTION_HOST}/${DB_CONNECTION_DATABASE} retry ${i}...";
        done
    }
    return 1;
}

main $@;
