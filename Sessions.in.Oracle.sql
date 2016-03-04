column machine format a15;
column client_info format a15;
column username format a17;
column module format a20;
column action format a15;

select machine, client_info, username, module, action from v$session where upper(MACHINE) like '%WEB%' order by machine;