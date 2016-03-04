CREATE TABLE #WordList(pwd NVARCHAR(MAX))
INSERT INTO #WordList(pwd) VALUES ('')
INSERT INTO #WordList(pwd) VALUES ('Password1')
INSERT INTO #WordList(pwd) VALUES ('password1')
INSERT INTO #WordList(pwd) VALUES ('Password')
INSERT INTO #WordList(pwd) VALUES ('password')
INSERT INTO #WordList(pwd) VALUES ('1234')
INSERT INTO #WordList(pwd) VALUES ('12345')
INSERT INTO #WordList(pwd) VALUES ('123456')
INSERT INTO #WordList(pwd) VALUES ('1234567')
INSERT INTO #WordList(pwd) VALUES ('12345678')
INSERT INTO #WordList(pwd) VALUES ('123456789')
INSERT INTO #WordList(pwd) VALUES ('1234567890')
INSERT INTO #WordList(pwd) VALUES ('qwerty')
INSERT INTO #WordList(pwd) VALUES ('abc123')
INSERT INTO #WordList(pwd) VALUES ('letmein')
INSERT INTO #WordList(pwd) VALUES ('master')
INSERT INTO #WordList(pwd) VALUES ('dragon')
INSERT INTO #WordList(pwd) VALUES ('football')
INSERT INTO #WordList(pwd) VALUES ('monkey')
INSERT INTO #WordList(pwd) VALUES ('letmein')
INSERT INTO #WordList(pwd) VALUES ('111111')
INSERT INTO #WordList(pwd) VALUES ('mustang')
INSERT INTO #WordList(pwd) VALUES ('access')
INSERT INTO #WordList(pwd) VALUES ('shadow')
INSERT INTO #WordList(pwd) VALUES ('michael')
INSERT INTO #WordList(pwd) VALUES ('superman')
INSERT INTO #WordList(pwd) VALUES ('696969')
INSERT INTO #WordList(pwd) VALUES ('123123')
INSERT INTO #WordList(pwd) VALUES ('batman')
INSERT INTO #WordList(pwd) VALUES ('trustno1')

SELECT name,pwd,type_desc,create_date,modify_date
		FROM sys.sql_logins
		CROSS JOIN #WordList
	WHERE PWDCOMPARE(pwd,password_hash)=1
UNION ALL
	SELECT name,name as pwd,type_desc,create_date,modify_date
		FROM sys.sql_logins
		WHERE PWDCOMPARE(name,password_hash)=1

DROP TABLE #WordList