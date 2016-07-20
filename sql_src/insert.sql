-- ----------------------------------------------------------------------------------- --
--  PURDUE CS527 - Software Security                                                    --
--  Spring 2016                                                                        --
--                                                                                     --
--  This code inserts users and challenges                                             --
--                                                                                     --
-- ispo                                                                                --
-- ----------------------------------------------------------------------------------- --

-- ----------------------------------------------------------------------------------- --
--                                    INSERT USERS                                     --
-- ----------------------------------------------------------------------------------- --
CALL addusr('Kyriakos','Ispoglou',  'ispo',         'ispo',       'admin'  ); -- admin: uid=0
CALL addusr('Foo',     'Bar',       'fooo',         'baar',       'hacker' );
CALL addusr('Foo',     'Bar',       'fooo',         'baar',       'b01ler' );
CALL addusr('Foo',     'Bar',       'fooo',         'baar',       'student' );


-- ----------------------------------------------------------------------------------- --
--                                  INSERT CHALLENGES                                  --
-- ----------------------------------------------------------------------------------- --
INSERT INTO challenges(cid,name,difficulty,flaghash,initpoints,link,description,hint) 
    VALUES 
-- week 1 challenges
/*
    ...
*/
(
    0x11000011, 
    'Reverse Math #1',
    'medium',
    'cs527{I_lov3_girLs_w1tH_b1g_f0reH34ds}',   
    150,
    'chal/re/mathrev_1',
    'Not all flags are stored in ASCII.',
    'Sometimes, you can compress things this way (e.g. JPEG)'
), (
    0x11000012, 
    'Reverse Math #2',
    'medium',
    'cs527{0H_y3aH_1_c4N_w0rK_w1th_n0N-l1n34R_7hiNGs}', 
    200,
    'chal/re/mathrev_2',
    'Very similar challenge to Reverse Math #1.', 
    'Things get non-linear this time.'
), (
    0x11000013,
    'Reverse Math #3',
    'medium',
    'cs527{7he_L1t7l3_dUck_g0ez_t0_tH3_r1v3R}', 
    300,
    'chal/re/mathrev_3',
    'This challenge is similar to Reverse Math #1 and #2. However, get ready to use FPU!', 
    'You have to solve some equations.'
);

-- week 2 challenges
INSERT INTO challenges(cid,name,difficulty,flaghash,initpoints,link,description,hint) 
    VALUES 
(
    0x21000021,
    'Easy RE #1',
    'easy',
    'cs527{1_c4n_m3sS_w17H_StR1pPpPPPppPeD_b1N4Riez}', 
    100,
    'chal/re/easyre_1',
    'Simply find the flag.', 
    ''
), (
    0x21000022,
    'Easy RE #2',
    'medium',
    'cs527{D0_y0u_l1ke_Kr4bbY_pAt71ez?}',     
    100,
    'chal/re/easyre_2',
    'Simply find the flag.',
    ''
);
/*
    ...
*/

-- week 5 challenges
INSERT INTO challenges(cid,name,difficulty,flaghash,initpoints,link,description,hint) 
    VALUES 
(
    0x52000001,
    'easy BoF',
    'medium',
    'cs527{Im_4n_exP3Rt_1N_s7aCk_0VeRF1oWWWWzzzz}',
    500,
    '',
    'Get your hands dirty :D </br>ssh -p9930 chicken@cs527ctf.risvc.net (pw: chicken)', 
    'Don\'t forget the NOP sled ;)'
), 
/*
    ...
*/
(
    0x63000015,
    'SQL filters #2',
    'hard',    
    'cs527{m4s7eR1ng_7iMe_b4sed_bl1nD_sQL_InjEEEEEctioN}',
    950,
    'http://cs527ctf.risvc.net:9911/sql_filter_2/',
    'You know what to do. Good luck.', 
    ''
);

-- hidden challenge
INSERT INTO challenges(cid,name,difficulty,flaghash,initpoints,link,description,hint) 
    VALUES 
(
    0x74000000,
    'The Hidden Challenge',
    'misc',    
    'cs527{Th1s_iZ_th3_lasT_fL4G_0f_s0fTwAr3_53cUR1tY_cLasS}',
    777,
    '',
    '',
    ''
);

-- ----------------------------------------------------------------------------------- --
--                                 EXTEND THE DEADLINE                                 --
-- ----------------------------------------------------------------------------------- --
UPDATE challenges                       -- extend last set by 3 days
    SET time = FROM_UNIXTIME(UNIX_TIMESTAMP(time) + 86400*3)
    WHERE cid & 0x70000000 = 0x70000000  or
          cid & 0x60000000 = 0x60000000;

-- ----------------------------------------------------------------------------------- --
--                                  GIVE BONUS POINTS                                  --
-- ----------------------------------------------------------------------------------- --
UPDATE users
    SET bonuspoints = bonuspoints + 300
    WHERE username = 'fooo';

-- ----------------------------------------------------------------------------------- --
--                                  UPDATE OLD TIMESTAMPS                              --
-- ----------------------------------------------------------------------------------- --
UPDATE challenges                       -- give a timestamp to the 2nd week challenges
    SET time = TIMESTAMP('2016-04-08 23:14:30')
    WHERE cid & 0x20000000 = 0x20000000;

-- ----------------------------------------------------------------------------------- --
--                                   INSERT A LATE FLAG                                --
-- ----------------------------------------------------------------------------------- --
INSERT INTO s0lv3D__ (uid, cid, ord, points)
 VALUES(
    2044930774452680448,                -- uid
    0x63000014, 
    (SELECT solves+1 FROM dynchall WHERE cid=0x63000014),
    (SELECT points FROM dynchall WHERE cid=0x63000014)
);
UPDATE dynchall
 SET solves = solves+1
  WHERE cid = 0x63000014;

-- ----------------------------------------------------------------------------------- --
SELECT * FROM s0lv3D__;
SELECT * FROM dynchall;
SELECT * FROM Us3Rs__;

-- ----------------------------------------------------------------------------------- --
--                                      TOTAL SCORES                                   --
-- ----------------------------------------------------------------------------------- --
SELECT firstname, lastname, points+bonuspoints AS score 
        FROM users 
        WHERE type='student' ORDER BY score DESC;

-- ----------------------------------------------------------------------------------- --
--                                   SCORES BY CATEGORY                                --
-- ----------------------------------------------------------------------------------- --
SELECT firstname, lastname, SUM(s0lv3D__.points) AS reversing 
FROM s0lv3D__ INNER JOIN users ON s0lv3D__.uid=users.uid  
WHERE type='student' AND cid & 0x0f000000 = 0x01000000 
GROUP BY s0lv3D__.uid 
ORDER BY reversing DESC
;

SELECT firstname, lastname, SUM(s0lv3D__.points) AS pwn 
FROM s0lv3D__ INNER JOIN users ON s0lv3D__.uid=users.uid  
WHERE type='student' AND cid & 0x0f000000 = 0x02000000 
GROUP BY s0lv3D__.uid 
ORDER BY pwn DESC
;

SELECT firstname, lastname, SUM(s0lv3D__.points) AS web 
FROM s0lv3D__ INNER JOIN users ON s0lv3D__.uid=users.uid  
WHERE type='student' AND cid & 0x0f000000 = 0x03000000 
GROUP BY s0lv3D__.uid 
ORDER BY web DESC
;

SELECT firstname, lastname, SUM(s0lv3D__.points) AS misc 
FROM s0lv3D__ INNER JOIN users ON s0lv3D__.uid=users.uid  
WHERE type='student' AND cid & 0x0f000000 = 0x04000000 
GROUP BY s0lv3D__.uid 
ORDER BY misc DESC
;

SELECT firstname, lastname, SUM(s0lv3D__.points) AS realistic 
FROM s0lv3D__ INNER JOIN users ON s0lv3D__.uid=users.uid  
WHERE type='student' AND cid & 0x0f000000 = 0x05000000 
GROUP BY s0lv3D__.uid 
ORDER BY realistic DESC
;
-- ----------------------------------------------------------------------------------- --
