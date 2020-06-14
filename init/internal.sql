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