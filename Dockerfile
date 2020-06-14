FROM debian:10-slim

LABEL mantainer Pedro Robson Leão <pedro.leao@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update &&                  \
    apt -y upgrade &&              \
    apt -y install                 \
        default-mysql-client       \
        default-libmysqlclient-dev \
        unixodbc                   \
        mariadb-plugin-connect     \
        unzip                      \
        python-mysqldb             \
        python3-venv               \
        python3-pip                \
        git                        \
        wget                       \
        build-essential            \    
        pkgconf                    \
        netcat                     \
        sox &&                     \
    /usr/bin/pip3 install          \
         mysqlclient               \
         alembic &&                \
    mkdir -p /tmp/build &&         \
    cd /tmp/build &&               \
    wget -c                        \
    https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.18-linux-debian10-x86-64bit.tar.gz && \
    tar -xvf mysql-connector-odbc-*.tar.gz &&                                          \
    ln -s mysql-connector-odbc-8.0.18-linux-debian10-x86-64bit mysql-connector-odbc && \
    cd mysql-connector-odbc &&                                                         \
    cp -v lib/libmyodbc8* /lib/x86_64-linux-gnu &&                                     \
    mkdir -p /tmp/build &&                                                             \
    cd  /tmp/build &&                                                                  \
    git clone https://github.com/pjsip/pjproject.git &&                                \
    cd pjproject &&                                                                    \
    ./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/lib/x86_64-linux-gnu --enable-shared --disable-video --disable-sound --disable-opencore-amr && \
    make dep &&                                                                        \
    make &&                                                                            \
    make install &&                                                                    \
    ldconfig &&                                                                        \
    cd  /tmp/build &&                                                                  \
    rm -rf pjproject &&                                                                \
    # git clone -b 16 https://gerrit.asterisk.org/asterisk asterisk-16 &&                \
    git clone -b 16.11 https://github.com/asterisk/asterisk.git asterisk-16 &&            \
    cd asterisk-16 &&                                                                  \
    ./contrib/scripts/install_prereq install <<"55" &&                                 \
    ./configure --libdir=/lib/x86_64-linux-gnu &&                                      \
    make menuselect.makeopts &&                                                        \
    ./menuselect/menuselect                                                            \
        --enable chan_ooh323 --enable format_mp3 --enable res_config_mysql             \
	    MENUSELECT_CODECS                                                              \
	    --enable codec_opus                                                            \
	    --enable-category MENUSELECT_APPS                                              \
	    --disable cdr_radius                                                           \
	    --disable cel_radius                                                           \
	    --disable chan_skinny                                                          \
	    --enable-category MENUSELECT_RES &&                                            \
    ./contrib/scripts/get_mp3_source.sh &&                                             \
    make &&                                                                            \
    make install &&                                                                    \
    make samples &&                                                                    \
    make config &&                                                                     \
    ldconfig &&                                                                        \
    mkdir -vp /var/lib/asterisk/sounds/pt-br  /etc/asterisk /var/{lib,log,spool,run}/asterisk /usr/x86_64-linux-gnu/asterisk && \
    cd /var/lib/asterisk/sounds/pt-br &&                                               \
    groupadd asterisk &&                                                               \
    useradd -r -d /var/lib/asterisk -g asterisk asterisk &&                            \
    usermod -aG audio,dialout asterisk &&                                              \
    # chown -hvR asterisk:asterisk /etc/asterisk /var/{lib,log,spool,run}/asterisk /usr/x86_64-linux-gnu/asterisk && \
    wget -O core.zip https://www.asterisksounds.org/pt-br/download/asterisk-sounds-core-pt-BR-sln16.zip &&   \
    wget -O extra.zip https://www.asterisksounds.org/pt-br/download/asterisk-sounds-extra-pt-BR-sln16.zip && \
    ls *.zip && \
    for file in core.zip extra.zip; do                                                 \
        unzip ${file} && rm ${file};                                                   \
    done;                                                                              \  
    ls *.sln16 &&                                                                      \
    for a in $(find . -name '*.sln16'); do                                             \
        sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t gsm -r 8k `echo $a|sed "s/.sln16/.gsm/"`;           \
        sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t raw -r 8k -e a-law `echo $a|sed "s/.sln16/.alaw/"`; \
        sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t raw -r 8k -e mu-law `echo $a|sed "s/.sln16/.ulaw/"`;\
    done;                                                                              \
    ls *.sln16 *.gsm *.alaw *.ulaw  &&                                                 \
    # chown -hvR asterisk:asterisk /var/lib/asterisk/sounds/pt-br &&                       \
    find /var/lib/asterisk/sounds/pt-br -type d -exec chmod 0775 {} \; &&              \
    # need change db parameters
    mv -v /tmp/build/asterisk-16/contrib/ast-db-manage /var/lib/asterisk/ && \
    touch /etc/odbc.ini &&                                                             \
    # chown asterisk:asterisk /etc/odbc.ini /etc/asterisk/config.ini &&                  \
    # uncomment user and group
    sed -e 's/#AST_USER.*/AST_USER="root"/;s/#AST_GROUP.*/AST_GROUP="root"/' -i /etc/default/asterisk &&          \
    sed -e 's/;runuser.*/runuser = root/;s/;rungroup.*/rungroup = root/' -i /etc/asterisk/asterisk.conf &&        \
    rm -rf /tmp/* &&                                                                   \
    # general clean
    apt -y purge                                                                       \
        git                                                                            \
        wget                                                                           \
        build-essential                                                                \    
        pkgconf                                                                        \
        sox                                                                            \
        mariadb-server-10.3         &&                                                 \
        # $( dpkg -l| egrep -i -- '-dev' | awk '{ print $2 }' )  &&                      \
    apt -y autoremove

# USER asterisk:asterisk

WORKDIR /var/lib/asterisk

ADD init/ .init/
ADD entrypoint.sh ./

EXPOSE 5060

ENTRYPOINT [ "./entrypoint.sh" ]
