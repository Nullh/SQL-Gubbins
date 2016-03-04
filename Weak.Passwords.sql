CREATE TABLE #WordList(pwd NVARCHAR(MAX))
INSERT INTO #WordList(pwd)
VALUES (''),
	('Password1'),
	('password1'),
	('Password'),
	('password'),
	('1234'),
	('12345'),
	('123456'),
	('1234567'),
	('12345678'),
	('123456789'),
	('1234567890'),
	('qwerty'),
	('abc123'),
	('letmein'),
	('master'),
	('dragon'),
	('football'),
	('monkey'),
	('letmein'),
	('111111'),
	('mustang'),
	('access'),
	('shadow'),
	('michael'),
	('superman'),
	('696969'),
	('123123'),
	('batman'),
	('trustno1')

SELECT name,pwd,type_desc,create_date,modify_date
		FROM sys.sql_logins
		CROSS JOIN #WordList
	WHERE PWDCOMPARE(pwd,password_hash)=1
	UNION ALL
	SELECT name,name as pwd,type_desc,create_date,modify_date
		FROM sys.sql_logins
		WHERE PWDCOMPARE(name,password_hash)=1

DROP TABLE #WordList