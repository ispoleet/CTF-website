-- ----------------------------------------------------------------------------------- --
--  PURDUE CS527 - Software Security                                                    --
--  Spring 2016                                                                        --
--                                                                                     --
--  This code creates the database                                                     --
--                                                                                     --
-- ispo                                                                                --
-- ----------------------------------------------------------------------------------- --
CREATE DATABASE IF NOT EXISTS cs527_ctf;    -- create the database
USE cs527_ctf;                              -- and use it


-- ----------------------------------------------------------------------------------- --
--                                   DATABASE SCHEMA                                   --
-- ----------------------------------------------------------------------------------- --
DROP VIEW  IF EXISTS Us3Rs__;               -- drop previous views
DROP VIEW  IF EXISTS r4nK__;
DROP TABLE IF EXISTS dynchall;              -- drop previous tables
DROP TABLE IF EXISTS s0lv3D__;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS challenges;

-- ----------------------------------------------------------------------------------- --
CREATE TABLE IF NOT EXISTS users (          -- user's information
    uid             BIGINT PRIMARY KEY,     -- unique user id
    firstname       VARCHAR(64) NOT NULL,
    lastname        VARCHAR(64) NOT NULL,
    username        VARCHAR(32) NOT NULL UNIQUE,
    passwordhash    VARCHAR(40) NOT NULL,   -- SHA1 hash
    alias           VARCHAR(64),            -- in case that you want to hind your name
    type            ENUM('student','b01ler','hacker','admin') DEFAULT 'student',
    points          INT DEFAULT 0,
    bonuspoints     INT DEFAULT 0
);

-- ----------------------------------------------------------------------------------- --
-- webserver will access user information through this VIEWs only
-- (we use script-kiddie names to avoid name guessing in case of SQLi)
-- (access to information_schema database will be limited)
CREATE VIEW Us3Rs__ AS SELECT uid, username AS usr, passwordhash AS pwd FROM users;
CREATE VIEW sC0r3__ AS SELECT uid, (points + bonuspoints) AS points FROM users;
CREATE VIEW r4nK__  AS SELECT alias, type, (points + bonuspoints) AS points FROM users;


-- CREATE VIEW r4nK__  AS SELECT alias, type, 
--  ((SELECT SUM(points) FROM s0lv3D__ WHERE s0lv3D__.uid=users.uid) + bonuspoints) AS points FROM users;


-- ----------------------------------------------------------------------------------- --
CREATE TABLE IF NOT EXISTS challenges (     -- static challenge information
                                            -- no information disclosure here
    -- MSNibble indicates row (different per week)
    -- 2nd MSNibble indicates category: 1=RE, 2=PWN, 3=WEB, 4=MISC, 5=REAL
    cid             BIGINT PRIMARY KEY,     -- unique challenge id (not random)
    name            VARCHAR(64) NOT NULL,   -- challenge name
    difficulty      ENUM('easy','medium','hard','paranoid','real') DEFAULT 'easy',
    flaghash        CHAR(128),              -- SHA1(flag)   
    initpoints      INT,                    -- initial number of points
    link            VARCHAR(128),           -- challenge link
    description     TINYTEXT,               -- small description (up to 255 bytes)      
    hint            TINYTEXT                -- potential challenge hint
);

-- ----------------------------------------------------------------------------------- --
CREATE TABLE IF NOT EXISTS dynchall(        -- dynamic challenge information
    cid             BIGINT PRIMARY KEY,     -- foreign key
    points          INT,                    -- current number of points 
    solves          INT,                    -- number of solves

    FOREIGN KEY (cid) REFERENCES challenges(cid)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
);

-- ----------------------------------------------------------------------------------- --
CREATE TABLE IF NOT EXISTS s0lv3D__ (       -- challenge solvers
    uid         BIGINT,                     -- user's id foreign key
    cid         BIGINT,                     -- challenge's id foreign key
    time        TIMESTAMP,                  -- current number of points
    ord         INT,                        -- the order of the solver
    points      INT,                        -- number of solves

    PRIMARY KEY(uid, cid),                  -- each challenge can be solved once by
                                            -- each user

    FOREIGN KEY (uid) REFERENCES users(uid)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,

    FOREIGN KEY (cid) REFERENCES challenges(cid)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
);


-- ----------------------------------------------------------------------------------- --
--                              TABLE ALTERs AND UPDATES                               --
-- ----------------------------------------------------------------------------------- --
ALTER TABLE challenges ADD COLUMN time TIMESTAMP;   -- add a timestamp column

-- ----------------------------------------------------------------------------------- --
--                                       TRIGGERS                                      --
-- ----------------------------------------------------------------------------------- --
DROP TRIGGER IF EXISTS inichall;            -- drop previous triggers
DROP TRIGGER IF EXISTS hashflag;
DROP TRIGGER IF EXISTS gettime;
DROP TRIGGER IF EXISTS addpoints;

DELIMITER $$
-- ----------------------------------------------------------------------------------- --
-- when a challenge is inserted, initialize its dynamic information
CREATE TRIGGER inichall AFTER INSERT ON challenges
FOR EACH ROW
    BEGIN
        INSERT INTO dynchall VALUES(NEW.cid, NEW.initpoints, 0);        
    END $$

-- ----------------------------------------------------------------------------------- --
-- when a new challenge is created, store the hash of the flag in the table
CREATE TRIGGER hashflag BEFORE INSERT ON challenges
FOR EACH ROW
    BEGIN
        SET NEW.flaghash = SHA1( CONCAT(NEW.flaghash,'i$p0z5aL7') );
    END $$

-- ----------------------------------------------------------------------------------- --
-- when a challenge is solved get current timestamp
CREATE TRIGGER gettime BEFORE INSERT ON s0lv3D__
FOR EACH ROW
    BEGIN
        -- IF NEW.time != NULL THEN
        --  SET NEW.time = NOW();
        -- END IF;  
        
        SET NEW.time = NOW();
    END $$
-- ----------------------------------------------------------------------------------- --
-- when a challenge is solved update points from current user
CREATE TRIGGER addpoints AFTER INSERT ON s0lv3D__
FOR EACH ROW
    BEGIN
        UPDATE users                        -- give the points to user
            SET points = (SELECT SUM(points) FROM s0lv3D__ WHERE uid=NEW.uid)           
            WHERE uid  = NEW.uid;
    END $$
-- ----------------------------------------------------------------------------------- --
-- when a challenge is solved update points from other users
CREATE TRIGGER subtpoints AFTER UPDATE ON s0lv3D__
FOR EACH ROW
    BEGIN
        UPDATE users                        -- give the points to user
            SET points = (SELECT SUM(points) FROM s0lv3D__ WHERE uid=NEW.uid)           
            WHERE uid  = NEW.uid;
    END $$

DELIMITER ;


-- ----------------------------------------------------------------------------------- --
--                                  STORED PROCEDURES                                  --
-- ----------------------------------------------------------------------------------- --
DROP PROCEDURE IF EXISTS addusr;            -- drop previous stored procedures
DROP PROCEDURE IF EXISTS authusr;
DROP PROCEDURE IF EXISTS authflag;
DROP PROCEDURE IF EXISTS calcpoints;
DROP PROCEDURE IF EXISTS getslvd;

DELIMITER $$
-- ----------------------------------------------------------------------------------- --
CREATE                                      -- add a new user to the users's table
    /* DEFINER = root  */
    PROCEDURE addusr ( 
        IN firstname VARCHAR(64),
        IN lastname  VARCHAR(64),
        IN username  VARCHAR(32),
        IN alias     VARCHAR(32),           -- displayed name on the scoreboard
                                            -- default alias is first and last name
        IN type      ENUM('student','b01ler','hacker','admin') 
    ) 
    BEGIN   
        SET @uid_       = FLOOR(1 + RAND()*POW(2,63));  -- unique, random uid
        SET @alias_     = IF(alias IS NULL, CONCAT(firstname, ' ', lastname), alias);
        SET @firstname_ = firstname;
        SET @lastname_  = lastname;
        SET @username_  = username;                     
        SET @type_      = type;
        SET @pwd        = '';                           -- randomly generated password
        SET @i          = 0;                            -- iterator

        -- generate a random password for that user
        pwdgen: LOOP                                    -- password loop
            SET @rndchr = ELT(1 + FLOOR(RAND() * 82),   -- generate a random character
                '~','!','@','#','$','%','^','&','*','-','=','_','+','/','|','?',
                ';',':','<','>','0','1','2','3','4','5','6','7','8','9','A','B',
                'C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R',
                'S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h',
                'i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');

            SET @pwd = CONCAT(@pwd, @rndchr);           -- append character to password
            SET @i   = @i + 1;                          -- ++i

            IF @i >= 24 THEN                            -- 24 characters seem enough
                LEAVE pwdgen;                           -- break
            END IF;
        END LOOP pwdgen;

        SET @hash_ = SHA1(CONCAT(@pwd,'i$p0z5aL7'));    -- get salted hash

        IF @type_ = 'admin' THEN                        -- admin get uid=0 (root)
            SET @uid_ = 0;
        END IF;

        -- insert user into users table
        PREPARE stmt FROM 'INSERT INTO users VALUES(?,?,?,?,?,?,?,0,0)';    
        EXECUTE stmt USING @uid_, @firstname_, @lastname_, @username_, 
                           @hash_, @alias_, @type_;
        DEALLOCATE PREPARE stmt;

        -- display user's password only once
        -- SELECT username AS 'username', @pwd AS 'password';

        -- create a file name with its user's username and write password to it
        -- /var/lib/mysql/usr/
        SET @stmt = CONCAT("SELECT @pwd INTO OUTFILE 'usr/", username, "'");
        PREPARE stmt FROM @stmt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END; $$ 

-- ----------------------------------------------------------------------------------- --
-- authenticate a user. Returns its user ID if authentication is successful.
CREATE
    /* DEFINER = ispo */
    PROCEDURE authusr( IN usr VARCHAR(64), IN pwd CHAR(40) )
    BEGIN
        SET @usr_ = usr;
        SET @pwd_ = pwd;                    -- password already hashed: Prevent sniffing

        PREPARE stmt FROM 'SELECT uid FROM Us3Rs__ WHERE usr=? AND pwd=? LIMIT 1';
        EXECUTE stmt USING @usr_, @pwd_;
        DEALLOCATE PREPARE stmt;            
    END; $$ 

-- ----------------------------------------------------------------------------------- --
-- authenticate a flag. If it's correct, add an entry in s0lv3D__ table, and update
-- challenge's points. This procedure returns an table with 1 column and 2 rows:
-- If the 1st row is 1, flag was correct. If it's 0 flag was wrong.
-- The 2nd row indicates whether user has already solved the challenge. If the 2nd row
-- is 0, flag is solved for 1st time. If it's 1 it is already solved.
CREATE
    /* DEFINER = ispo */
    PROCEDURE authflag( IN _uid BIGINT, IN _cid INT, IN hflag CHAR(40) )
    BEGIN       
        DECLARE EXIT HANDLER FOR 1062       -- handle for detecting submission
            SELECT -1 AS result;            -- of the same flag (we never execute this)


        SET @uid_   = _uid;
        SET @cid_   = _cid;
        SET @hflag_ = hflag;                -- flag already hashed: Prevent sniffing
        
        -- first check if flag is valid and if this is the first time  we submit it     
        -- at the same time check if flag has expired
        --  We flag flag's life to 2 weeks 1209600 (= 86400*14) seconds
        SET @stmt = 'SELECT @succ:=IF(UNIX_TIMESTAMP(NOW()) - '
                    '       UNIX_TIMESTAMP((SELECT time FROM challenges where cid=?)) <= 1209600,'
                    ' COUNT(*), -2) AS "result"'
                    '   FROM challenges WHERE cid=? AND flaghash=? '
                    'UNION ALL '
                    'SELECT @dup:=COUNT(*) '
                    '   FROM s0lv3D__ WHERE cid=? AND uid=?';

        PREPARE stmt FROM @stmt;
        EXECUTE stmt USING @cid_, @cid_, @hflag_, @cid_, @uid_;
        DEALLOCATE PREPARE stmt;    

        IF @succ = 1 AND @dup = 0 THEN      -- was the flag valid,
                                            -- and submitted for 1st time?
            
            -- get solver type
            SET @stmt = 'SELECT @type:=type FROM users WHERE uid=?';
            
            PREPARE stmt FROM @stmt;
            EXECUTE stmt USING @uid_;
            DEALLOCATE PREPARE stmt;                
            
            -- valid flag. Add user/challenge in s0lv3D__ table.
            IF @type != 'student' THEN

                -- a non-student submitted the flag. Give him half points, without
                -- updating the challenge points
                SET @stmt = 'INSERT INTO s0lv3D__ (uid, cid, ord, points) ' 
                            'VALUES (?, ?, -1,'
                            '              (SELECT initpoints/2 FROM challenges WHERE cid=?))';

                PREPARE stmt FROM @stmt;             
                EXECUTE stmt USING @uid_, @cid_, @cid_;
                DEALLOCATE PREPARE stmt;

            ELSE            
                -- a student submitted the flag. Update all points
                SET @stmt = 'INSERT INTO s0lv3D__ (uid, cid, ord, points) ' 
                            'VALUES (?, ?, (SELECT solves+1 FROM dynchall WHERE cid=?),'
                            '              (SELECT points   FROM dynchall WHERE cid=?))';                                         

                PREPARE stmt FROM @stmt;             
                EXECUTE stmt USING @uid_, @cid_, @cid_, @cid_;
                DEALLOCATE PREPARE stmt;

                UPDATE dynchall             -- increase number of solves
                    SET solves = solves+1
                    WHERE cid = _cid;

                CALL calcpoints(_cid);      -- decrease points for that challenge
            END IF;
        END IF;
    END; $$ 

-- ----------------------------------------------------------------------------------- --
-- every time that someone solves a challenge we decrese challenge's points
CREATE
    /* DEFINER = ispo */
    PROCEDURE calcpoints( IN _cid INT )
    BEGIN
        -- get current number of points
        SET @pnt = (SELECT initpoints FROM challenges WHERE cid=_cid);
        SET @slv = (SELECT solves FROM dynchall WHERE cid=_cid);

        -- reduce the number of points for all solvers
        -- ignore those with ord < 0 (not students)
        UPDATE s0lv3D__
            SET points = GREATEST(@pnt - SQRT((@slv-1)*@pnt*ord) , @pnt/2)
            WHERE cid = _cid AND ord >= 0;

        -- reduce number of points for that challenge
        UPDATE dynchall
            SET points = GREATEST(@pnt - SQRT(@slv*@pnt*(@slv+1)) , @pnt/2)
            WHERE cid = _cid;

    END; $$ 

-- ----------------------------------------------------------------------------------- --
-- we want to know exactly which challenges each user has solved. We need this 
-- information to mark the solved challenges as disabled in the dashboard. All we
-- have to do is to join challenges with s0lv3D__ table for that user (uid). We need
-- and left outer join to allow null entries (a user will probably not solved all 
-- challenges).
-- Note that we restrict access to s0lv3D__ table through this stored procedure.
-- Thus if the webserver has been compromised, the adversary won't be able to
-- view s0lv3D__ table. 
CREATE
    /* DEFINER = ispo */
    PROCEDURE getslvd( IN _uid BIGINT )
    BEGIN
        SET @uid_ = _uid;           
        SET @stmt = 'SELECT challenges.cid, solved.slvd, groups.chng '
                    'FROM challenges '
                    /* 
                     * RIGHT won't work as we need the NULL columns for slvd, 
                     * to determine the unsolved challnges.
                     */                 
                    '   LEFT OUTER JOIN '               
                    '       (SELECT 1 AS slvd, cid '
                    '           FROM s0lv3D__ '
                    '           WHERE uid=?) AS solved '
                    '   ON challenges.cid = solved.cid '
                    '   LEFT OUTER JOIN '
                    '       (SELECT 1 AS chng, cid '
                    '           FROM challenges '
                    '           GROUP BY (cid & 0xf0000000)) AS groups '
                    '   ON challenges.cid = groups.cid '
                    'ORDER BY challenges.cid ASC';

        PREPARE stmt FROM @stmt;             
        EXECUTE stmt USING @uid_;
        DEALLOCATE PREPARE stmt;    
    END; $$ 

DELIMITER ;


-- ----------------------------------------------------------------------------------- --
--                                      PRIVILEGES                                     --
-- ----------------------------------------------------------------------------------- --
CREATE USER 'lowpriv'@localhost IDENTIFIED BY 'chrysa';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'lowpriv'@localhost;
-- ----------------------------------------------------------------------------------- --
-- no GRANT to users table: Only root can modify it
GRANT SELECT ON cs527_ctf.Us3Rs__    TO 'lowpriv'@localhost;
GRANT SELECT ON cs527_ctf.sC0r3__    TO 'lowpriv'@localhost;
GRANT SELECT ON cs527_ctf.r4nK__     TO 'lowpriv'@localhost;
GRANT SELECT ON cs527_ctf.challenges TO 'lowpriv'@localhost;
GRANT SELECT, UPDATE ON cs527_ctf.dynchall TO 'lowpriv'@localhost;
GRANT SELECT, INSERT, UPDATE ON cs527_ctf.s0lv3D__ TO 'lowpriv'@localhost;
-- ----------------------------------------------------------------------------------- --
GRANT EXECUTE ON PROCEDURE cs527_ctf.authflag   TO 'lowpriv'@localhost;
GRANT EXECUTE ON PROCEDURE cs527_ctf.authusr    TO 'lowpriv'@localhost;
GRANT EXECUTE ON PROCEDURE cs527_ctf.getslvd    TO 'lowpriv'@localhost;
GRANT EXECUTE ON PROCEDURE cs527_ctf.calcpoints TO 'lowpriv'@localhost;

-- ----------------------------------------------------------------------------------- --
SOURCE insert.sql
-- ----------------------------------------------------------------------------------- --
