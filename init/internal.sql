-- webcdr initializa
DROP TABLE IF EXISTS `webuser`;
CREATE TABLE `webuser` (
   `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
   `name` VARCHAR(100) NOT NULL DEFAULT '',
   `username` VARCHAR(100) NOT NULL UNIQUE,
   `password` VARCHAR(100) NOT NULL,
   `acl` VARCHAR(1024) NOT NULL DEFAULT '',
   `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `admin` INT(1) NOT NULL DEFAULT 0,
   `acl_in` INT(1) NOT NULL DEFAULT 0,
   `auth_ad` INT(1) NOT NULL DEFAULT 0,
   PRIMARY KEY (`id`)
)
ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `webuser` (`name`,`username`,`password`,`admin`) VALUES ('Administrator','admin','admincdr',1);

-- nat settings
UPDATE ps_endpoints SET send_pai='yes';
UPDATE ps_endpoints SET media_use_received_transport='yes';
UPDATE ps_endpoints SET trust_id_inbound='yes';
UPDATE ps_endpoints SET media_encryption='no';
UPDATE ps_endpoints SET rtp_symmetric='yes';
UPDATE ps_endpoints SET rewrite_contact='yes';
UPDATE ps_endpoints SET force_rport='yes';
UPDATE ps_endpoints SET allow='ulaw,alaw';
UPDATE ps_endpoints SET allow='ulaw,alaw';
UPDATE ps_endpoints SET direct_media='no';

UPDATE ps_aors SET default_expiration=60;
UPDATE ps_aors SET minimum_expiration=120;
UPDATE ps_aors SET remove_existing='yes';
UPDATE ps_aors SET max_contacts=1;

-- initialize internal ramal
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