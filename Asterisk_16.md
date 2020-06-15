# Asterisk - Instalation

* [Instalação base do SISTEMA](#instala%C3%A7%C3%A3o-base-do-sistema)
* [Instalação MySQL(mariadb)](#instala%C3%A7%C3%A3o-mysqlmariadb)
* [Instalação do Asterisk](#instala%C3%A7%C3%A3o-do-asterisk)
* [Instalando sounds em português](#instalando-sounds-em-portugu%C3%AAs)
* [Configurando banco de dados](#configurando-banco-de-dados)
* [Configuração arquivos /etc/asterisk/](#configura%C3%A7%C3%A3o-arquivos-etcasterisk)

## Instalação base do SISTEMA

[Debian 10](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.4.0-amd64-netinst.iso)

```bash
apt update && apt -y upgrade

apt install -y vim git wget gcc sngrep python3-pip sox libsox-fmt-all unzip net-tools mpg123
```

## Instalação MySQL(mariadb)


```bash
apt -y install mariadb-server mariadb-client
systemctl status mariadb
mysql_secure_installation
new password:= tWea4FKg9mMmdT6G

Set root password? [Y/n] y
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] y
Remove test database and access to it? [Y/n] y
Reload privilege tables now? [Y/n] y

mysql -uroot -ptWea4FKg9mMmdT6G


apt -y update && apt -y upgrade

#alembic
apt install -y python-mysqldb default-libmysqlclient-dev
pip3 install mysqlclient
pip3 install alembic

#Instalação ODBC

cd /usr/src/
wget https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.18-linux-debian10-x86-64bit.tar.gz

tar -xvf mysql-connector-odbc-*.tar.gz
cd mysql-connector-odbc-8.0.18-linux-debian10-x86-64bit
cp lib/libmyodbc8* /usr/lib64/


#Criando usuário no mysql

mysql -uroot -ptWea4FKg9mMmdT6G

CREATE DATABASE pabxbr;

GRANT ALL PRIVILEGES ON pabxbr.* TO 'asteriskbr'@'localhost' IDENTIFIED BY 'DfzwKtLxx9C4QEHM';

FLUSH PRIVILEGES;
\q

apt -y update && apt -y upgrade
apt install -y unixodbc mariadb-plugin-connect

cd 

#Gerando configuração do /etc/odbc.ini
/usr/src/mysql-connector-odbc-8.0.18-linux-debian10-x86-64bit/bin/myodbc-installer -d -a -n "MySQL" -t "DRIVER=/usr/lib64/libmyodbc8w.so;"

/usr/src/mysql-connector-odbc-8.0.18-linux-debian10-x86-64bit/bin/myodbc-installer -s -a -c2 -n "MYSQL-DNS" -t "DRIVER=MySQL;SERVER=127.0.0.1;DATABASE=pabxbr;UID=asteriskbr;PWD=DfzwKtLxx9C4QEHM"

cat /etc/odbc.ini
[MYSQL-DNS]
Driver=MySQL
SERVER=127.0.0.1
UID=asteriskbr
PWD=DfzwKtLxx9C4QEHM
DATABASE=pabxbr
PORT=3306

#Testando config
isql -v MYSQL-DNS
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> show databases;
```


## Instalação do Asterisk


```bash
#Download and Install PJSIP
cd /usr/src/
git clone https://github.com/pjsip/pjproject.git
cd pjproject

./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr

make dep
make
make install
ldconfig

cd /usr/src/
git clone -b 16 https://gerrit.asterisk.org/asterisk asterisk-16


/usr/src/asterisk-16/contrib/scripts/install_prereq install
ITU-T telephone code: 55

cd /usr/src/asterisk-16/
./configure --libdir=/usr/lib64


make menuselect.makeopts
menuselect/menuselect \
--enable chan_ooh323 --enable format_mp3 --enable res_config_mysql \
	MENUSELECT_CODECS \
	--enable codec_opus \
	--enable-category MENUSELECT_APPS \
	--disable cdr_radius \
	--disable cel_radius \
	--disable chan_skinny \
	--enable-category MENUSELECT_RES

contrib/scripts/get_mp3_source.sh
make
make install
make samples
make config
ldconfig


#Configurar e iniciar o Asterisk
groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk /var/{lib,log,spool}/asterisk /usr/lib64/asterisk


#remover comentários
vim /etc/default/asterisk
AST_USER="asterisk"
AST_GROUP="asterisk"

#remover comentários
vim /etc/asterisk/asterisk.conf
runuser = asterisk
rungroup = asterisk
```

## Instalando sounds em português

```
mkdir /var/lib/asterisk/sounds/pt-br
cd /var/lib/asterisk/sounds/pt-br

wget -O core.zip https://www.asterisksounds.org/pt-br/download/asterisk-sounds-core-pt-BR-sln16.zip

wget -O extra.zip https://www.asterisksounds.org/pt-br/download/asterisk-sounds-extra-pt-BR-sln16.zip

unzip core.zip
unzip extra.zip
rm -rf *.zip

cd /var/lib/asterisk/sounds/pt-br

vim /var/lib/asterisk/sounds/pt-br/convert
#!/bin/bash
for a in $(find . -name '*.sln16'); do
  sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t gsm -r 8k `echo $a|sed "s/.sln16/.gsm/"`;\
  sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t raw -r 8k -e a-law `echo $a|sed "s/.sln16/.alaw/"`;\
  sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t raw -r 8k -e mu-law `echo $a|sed "s/.sln16/.ulaw/"`;\
done

chmod +x convert
./convert

chown -R asterisk.asterisk /var/lib/asterisk/sounds/pt-br

find /var/lib/asterisk/sounds/pt-br -type d -exec chmod 0775 {} \;
```

## Configurando banco de dados

```
cd /usr/src/asterisk-16/contrib/ast-db-manage
cp config.ini.sample config.ini
vim config.ini

#comentar a linha 21 e adicionar:
sqlalchemy.url = mysql://asteriskbr:DfzwKtLxx9C4QEHM@localhost/pabxbr

#Criando tabelas
alembic -c ./config.ini upgrade head

mysql -uroot -ptWea4FKg9mMmdT6G -Dpabxbr

CREATE TABLE cdr (
    accountcode VARCHAR(20),
    src VARCHAR(80),
    dst VARCHAR(80),
    dcontext VARCHAR(80),
    clid VARCHAR(80),
    channel VARCHAR(80),
    dstchannel VARCHAR(80),
    lastapp VARCHAR(80),
    lastdata VARCHAR(80),
    start DATETIME,
    answer DATETIME,
    end DATETIME,
    duration INTEGER,
    billsec INTEGER,
    disposition VARCHAR(45),
    amaflags VARCHAR(45),
    userfield VARCHAR(256),
    uniqueid VARCHAR(150),
    linkedid VARCHAR(150),
    peeraccount VARCHAR(20),
    sequence INTEGER
);
\q
```

## Configuração arquivos /etc/asterisk/

```bash
#ODBC
cat <<EOF > /etc/asterisk/res_odbc.conf
;
[ENV]
;
ODBCSYSINI => /etc
ODBCINI    => /etc/odbc.ini
;

[pabxbr]
enabled => yes
dsn =>MYSQL-DNS
username => asteriskbr
password => DfzwKtLxx9C4QEHM
pre-connect => yes
sanitysql => select 1
;idlecheck => 3600
share_connections => yes
pooling => no
limit => 1
;isolation=repeatable_read
logging => yes
;
;
EOF

#LOG
cat <<EOF > /etc/asterisk/logger.conf
;
[general]
appendhostname = yes
queue_log_to_file = yes
queue_log_name = queue_log
rotatestrategy = rotate
exec_after_rotate=gzip -9 ${filename}.2

[logfiles]
;debug => debug
;security => security
console => notice,warning,error
;console => notice,warning,error,debug
messages => notice,warning,error
full => notice,warning,error,debug,verbose,dtmf,fax
;
;full-json => [json]debug,verbose,notice,warning,error,dtmf,fax
;syslog.local0 => notice,warning,error
;
EOF



cat <<EOF > /etc/asterisk/cdr_adaptive_odbc.conf
;
[adaptive_connection]
connection=pabxbr
table=cdr
;
EOF

cat <<EOF > cdr.conf
;
[general]
enable=yes
unanswered = yes
congestion = yes
;
EOF


cat <<EOF > /etc/asterisk/res_odbc_additional.conf
;
[pabxbr]
enabled => yes
dsn => MYSQL-DNS
pre-connect => yes
username => asteriskbr
password => DfzwKtLxx9C4QEHM
;
EOF


cat <<EOF > /etc/asterisk/acl.conf
;
[local_phone]
deny=0.0.0.0/0.0.0.0
permit=192.168.0.0/24
;
EOF


cat <<EOF > /etc/asterisk/modules.conf
;
[modules]
autoload=yes
;
require = chan_pjsip.so
noload => chan_alsa.so
noload => chan_oss.so
noload => chan_console.so
noload => chan_sip.so

noload => cdr_mysql.so
noload => cdr_csv.so
noload => cdr_custom.so

noload => res_hep.so
noload => res_hep_pjsip.so
noload => res_hep_rtcp.so
;
EOF


cat <<EOF > /etc/asterisk/extensions.conf
;
[general]
static=yes
writeprotect=yes
autofallthrough=yes
extenpatternmatchnew=no
clearglobalvars=no
userscontext=unspecified

[globals]

[testing]

exten => _7XXX,1,NoOp()
exten => _7XXX,n,Dial(PJSIP/${EXTEN},120)
exten => _7XXX,n,Hangup()

;
EOF

cat <<EOF > /etc/asterisk/pjsip.conf
;

[global]
type = global
default_realm=127.0.0.1
max_forwards=70
user_agent=PABXBR
keep_alive_interval=30


[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

;
EOF


cat <<EOF > /etc/asterisk/extconfig.conf
;
[settings]
ps_endpoints => odbc,pabxbr
ps_auths => odbc,pabxbr
ps_aors => odbc,pabxbr
ps_domain_aliases => odbc,pabxbr
ps_endpoint_id_ips => odbc,pabxbr
;
EOF


cat <<EOF > /etc/asterisk/sorcery.conf
;
[test_sorcery_section]
test=memory

[test_sorcery_cache]
test/cache=test
test=memory

[res_pjsip]
endpoint=realtime,ps_endpoints
auth=realtime,ps_auths
aor=realtime,ps_aors
domain_alias=realtime,ps_domain_aliases

[res_pjsip_endpoint_identifier_ip]
identify=realtime,ps_endpoint_id_ips
;
EOF


mysql -uroot -ptWea4FKg9mMmdT6G -Dpabxbr <<EOF

insert into ps_aors (id, max_contacts) values (7001, 1);
insert into ps_aors (id, max_contacts) values (7002, 1);
insert into ps_aors (id, max_contacts) values (7003, 1);
insert into ps_aors (id, max_contacts) values (7004, 1);

insert into ps_auths (id, auth_type, password, username) values (7001, 'userpass', 7001, 7001);
insert into ps_auths (id, auth_type, password, username) values (7002, 'userpass', 7002, 7002);
insert into ps_auths (id, auth_type, password, username) values (7003, 'userpass', 7003, 7003);
insert into ps_auths (id, auth_type, password, username) values (7004, 'userpass', 7004, 7004);

insert into ps_endpoints (id, transport, aors, auth, context, disallow, allow, direct_media) values (7001, 'transport-udp', '7001', '7001', 'testing', 'all', 'ulaw,alaw', 'no');
insert into ps_endpoints (id, transport, aors, auth, context, disallow, allow, direct_media) values (7002, 'transport-udp', '7002', '7002', 'testing', 'all', 'ulaw,alaw', 'no');
insert into ps_endpoints (id, transport, aors, auth, context, disallow, allow, direct_media) values (7003, 'transport-udp', '7003', '7003', 'testing', 'all', 'ulaw,alaw', 'no');
insert into ps_endpoints (id, transport, aors, auth, context, disallow, allow, direct_media) values (7004, 'transport-udp', '7004', '7004', 'testing', 'all', 'ulaw,alaw', 'no');
EOF

#reinicia a máquina
reboot

#Verificar o serviço
service asterisk status

#Caso tenha erro
cp /usr/lib64/libasteriskssl.so.1 /usr/lib/
cp /usr/lib64/libasteriskpj.so.2 /usr/lib/

service asterisk stop
service asterisk start
service asterisk status

#Prompt do asterisk
asterisk -Rvvvvvvvddddddd


#Softphone
User:	7001
Pass:	7001
SIP Domain: 	192.168.86.37
```
