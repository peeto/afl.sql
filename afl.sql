DROP DATABASE IF EXISTS `afl`;
CREATE DATABASE `afl`;

-- Tables

DROP TABLE IF EXISTS `afl`.`competition`;
CREATE TABLE  `afl`.`competition` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_competition_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `afl`.`stadium`;
CREATE TABLE  `afl`.`stadium` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_stadium_name` (`name`),
  KEY `idx_staduim_location` (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `afl`.`team`;
CREATE TABLE  `afl`.`team` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `place` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_team_place` (`place`),
  KEY `idx_team_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `afl`.`season`;
CREATE TABLE  `afl`.`season` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `competition` int(10) unsigned DEFAULT NULL,
  `year` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_season_year` (`year`),
  KEY `fk_season_competition` (`competition`),
  CONSTRAINT `fk_season_competition` FOREIGN KEY (`competition`) REFERENCES `competition` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `afl`.`match`;
CREATE TABLE  `afl`.`match` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `season` int(10) unsigned DEFAULT NULL,
  `round` int(10) unsigned NOT NULL,
  `stadium` int(10) unsigned DEFAULT NULL,
  `starttime` datetime NOT NULL,
  `hometeam` int(10) unsigned DEFAULT NULL,
  `awayteam` int(10) unsigned DEFAULT NULL,
  `hometeamsupergoals` int(10) NOT NULL DEFAULT '0',
  `hometeamgoals` int(10) NOT NULL DEFAULT '0',
  `hometeampoints` int(10) NOT NULL DEFAULT '0',
  `awayteamsupergoals` int(10) NOT NULL DEFAULT '0',
  `awayteamgoals` int(10) NOT NULL DEFAULT '0',
  `awayteampoints` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_match_season` (`season`),
  KEY `fk_match_stadium` (`stadium`),
  KEY `fk_match_hometeam` (`hometeam`),
  KEY `fk_match_awayteam` (`awayteam`),
  KEY `idx_match_round` (`round`),
  KEY `idx_match_starttime` (`starttime`),
  KEY `idx_match_hometeamgoals` (`hometeamgoals`),
  KEY `idx_match_hometeampoints` (`hometeampoints`),
  KEY `idx_match_awayteamgoals` (`awayteamgoals`),
  KEY `idx_match_awayteampoints` (`awayteampoints`),
  KEY `idx_match_hometeamsupergoals` (`hometeamsupergoals`),
  KEY `idx_match_awayteamsupergoals` (`awayteamsupergoals`),
  CONSTRAINT `fk_match_awayteam` FOREIGN KEY (`awayteam`) REFERENCES `team` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_match_hometeam` FOREIGN KEY (`hometeam`) REFERENCES `team` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_match_season` FOREIGN KEY (`season`) REFERENCES `season` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_match_stadium` FOREIGN KEY (`stadium`) REFERENCES `stadium` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Views

CREATE OR REPLACE VIEW `afl`.`v_team` AS
SELECT
    t.*,
    CONCAT(t.`place`, ' ', t.`name`) AS `team_name`
FROM
    `afl`.team AS t
ORDER BY
    t.place,
    t.name
;

CREATE OR REPLACE VIEW `afl`.`v_match_outcome` AS
SELECT
    m.*,
    ((m.hometeamsupergoals * 9) + (m.hometeamgoals * 6) + m.hometeampoints) AS hometeamscore,
    ((m.awayteamsupergoals * 9) + (m.awayteamgoals * 6) + m.awayteampoints) AS awayteamscore,
    IF( ((m.hometeamsupergoals * 9) + (m.hometeamgoals * 6) + m.hometeampoints) > ((m.awayteamsupergoals * 9) + (m.awayteamgoals * 6) + m.awayteampoints), m.hometeam, IF( ((m.hometeamsupergoals * 9) + (m.hometeamgoals * 6) + m.hometeampoints) < ((m.awayteamsupergoals * 9) + (m.awayteamgoals * 6) + m.awayteampoints), awayteam, NULL ) ) AS winningteam,
    IF( ((m.hometeamsupergoals * 9) + (m.hometeamgoals * 6) + m.hometeampoints) > ((m.awayteamsupergoals * 9) + (m.awayteamgoals * 6) + m.awayteampoints), m.awayteam, IF( ((m.hometeamsupergoals * 9) + (m.hometeamgoals * 6) + m.hometeampoints) < ((m.awayteamsupergoals * 9) + (m.awayteamgoals * 6) + m.awayteampoints), hometeam, NULL ) ) AS losingteam,
    IF( ((m.hometeamsupergoals * 9) + (m.hometeamgoals * 6) + m.hometeampoints) = ((m.awayteamsupergoals * 9) + (m.awayteamgoals * 6) + m.awayteampoints), TRUE, FALSE ) AS isdraw
FROM 
    `afl`.`match` AS m
;

CREATE OR REPLACE VIEW `afl`.`v_team_score` AS
SELECT
    c.`id` AS `competition_id`,
    c.`name` AS `competition_name`,
    s.`id` AS `season_id`,
    s.`year`,
    m.`round`,
    m.`id` AS `match_id`,
    t.`id` AS `team_id`,
    t.`team_name`,
    IF(t.id=m.hometeam, m.awayteam, m.hometeam) AS other_team_id,
    IF(t.id=m.hometeam, TRUE, FALSE) AS ishomegame,
    IF(t.id=m.winningteam, 4, IF(m.isdraw, 2, 0)) AS `points`,
    IF(t.id=m.hometeam, m.hometeamscore, m.awayteamscore) AS `pointsfor`,
    IF(t.id=m.hometeam, m.awayteamscore, m.hometeamscore) AS `pointsagainst`,
    IF(t.id=m.winningteam, TRUE, FALSE) AS `win`,
    IF(t.id=m.losingteam, TRUE, FALSE) AS `lose`,
    m.isdraw AS `draw`
FROM
    `afl`.`competition` AS c
    JOIN `afl`.`season` AS s ON s.competition=c.id
    JOIN `afl`.`v_match_outcome` AS m ON m.season=s.id
    JOIN `afl`.`v_team` AS t ON (t.id=m.hometeam OR t.id=m.awayteam)
ORDER BY
    c.id,
    s.year,
    m.round,
    t.team_name
;

CREATE OR REPLACE VIEW `afl`.`v_match_details` AS
SELECT
    d.competition_id,
    d.competition_name,
    d.season_id,
    d.year,
    d.round,
    d.match_id,
    s.id AS stadium_id,
    s.name AS stadium_name,
    s.location AS stadium_location,
    d.ishomegame,
    m.starttime,
    d.team_id,
    d.team_name,
    d.points AS team_season_points,
    d.pointsfor AS team_match_score,
    d.win,
    d.lose,
    d.draw,
    d.other_team_id,
    ot.team_name AS other_team_name,
    d.pointsagainst AS other_team_match_score
FROM
    `afl`.`v_team_score` AS d
    JOIN `afl`.`match` AS m ON m.id=d.match_id
    JOIN `afl`.`stadium` AS s ON s.id=m.stadium
    JOIN `afl`.`v_team` AS ot ON ot.id=d.other_team_id
;

CREATE OR REPLACE VIEW `afl`.`v_season_ladder` AS
SELECT
    c.`id` AS `competition_id`,
    c.`name` AS `competition_name`,
    s.`id` AS `season_id`,
    s.`year`,
    t.`id` AS `team_id`,
    t.`team_name`,
    SUM(m.points) AS points,
    SUM(m.pointsfor) AS pointsfor,
    SUM(m.pointsagainst) AS pointsagainst,
    (SUM(m.pointsfor) / SUM(m.pointsagainst)) * 100 AS percent,
    SUM(m.win) AS win,
    SUM(m.lose) AS lose,
    SUM(m.draw) AS draw
FROM
    `afl`.`competition` AS c
    JOIN `afl`.`season` AS s ON s.competition=c.id
    JOIN `afl`.`v_team_score` AS m ON m.season_id=s.id
    JOIN `afl`.`v_team` AS t ON t.id=m.team_id
GROUP BY
    c.`id`,
    c.`name`,
    s.`id`,
    s.`year`,
    t.id
ORDER BY 
    c.`id`,
    c.`name`,
    s.`year` DESC,
    SUM(m.points) DESC,
    ((SUM(m.pointsfor) / SUM(m.pointsagainst)) * 100) DESC
;

-- Plain Data

TRUNCATE `afl`.`competition`;
INSERT INTO `afl`.`competition` SET id=1, name='AFL Home and Away Series';
INSERT INTO `afl`.`competition` SET id=2, name='AFL Pre-Season Cup';

TRUNCATE `afl`.`team`;
INSERT INTO `afl`.`team` SET id=1, place='Adelaide', name='Crows';
INSERT INTO `afl`.`team` SET id=2, place='Brisbane', name='Lions';
INSERT INTO `afl`.`team` SET id=3, place='Carlton', name='Blues';
INSERT INTO `afl`.`team` SET id=4, place='Collingwood', name='Magpies';
INSERT INTO `afl`.`team` SET id=5, place='Essendon', name='Bombers';
INSERT INTO `afl`.`team` SET id=6, place='Fremantle', name='Dockers';
INSERT INTO `afl`.`team` SET id=7, place='Geelong', name='Cats';
INSERT INTO `afl`.`team` SET id=8, place='Gold Coast', name='Suns';
INSERT INTO `afl`.`team` SET id=9, place='GWS', name='Giants';
INSERT INTO `afl`.`team` SET id=10, place='Hawthorn', name='Hawks';
INSERT INTO `afl`.`team` SET id=11, place='Melbourne', name='Demons';
INSERT INTO `afl`.`team` SET id=12, place='North Melbourne', name='Kangaroos';
INSERT INTO `afl`.`team` SET id=13, place='Port Adelaide', name='Power';
INSERT INTO `afl`.`team` SET id=14, place='Richmond', name='Tigers';
INSERT INTO `afl`.`team` SET id=15, place='Saint Kilda', name='Saints';
INSERT INTO `afl`.`team` SET id=16, place='Sydney', name='Swans';
INSERT INTO `afl`.`team` SET id=17, place='West Coast', name='Eagles';
INSERT INTO `afl`.`team` SET id=18, place='Western', name='Bulldogs';

TRUNCATE `afl`.`stadium`;
INSERT INTO `afl`.`stadium` SET id=1, name='AAMI Stadium', location='South Australia';
INSERT INTO `afl`.`stadium` SET id=2, name='Aurora Stadium', location='Tasmania';
INSERT INTO `afl`.`stadium` SET id=3, name='Blacktown International Sportspark', location='New South Wales';
INSERT INTO `afl`.`stadium` SET id=4, name='Blundstone Arena', location='Tasmania';
INSERT INTO `afl`.`stadium` SET id=5, name='Cazaly''s Stadium', location='Queensland';
INSERT INTO `afl`.`stadium` SET id=6, name='Docklands Stadium', location='Victoria';
INSERT INTO `afl`.`stadium` SET id=7, name='Gabba', location='Queensland';
INSERT INTO `afl`.`stadium` SET id=8, name='Kardinia Park', location='Victoria';
INSERT INTO `afl`.`stadium` SET id=9, name='MCG', location='Victoria';
INSERT INTO `afl`.`stadium` SET id=10, name='Manuka Oval', location='ACT';
INSERT INTO `afl`.`stadium` SET id=11, name='Metricon Stadium', location='Queensland';
INSERT INTO `afl`.`stadium` SET id=12, name='Olympic Park', location='New South Wales';
INSERT INTO `afl`.`stadium` SET id=13, name='Patersons Stadium', location='Western Australia';
INSERT INTO `afl`.`stadium` SET id=14, name='SCG', location='New South Wales';
INSERT INTO `afl`.`stadium` SET id=15, name='Skoda Stadium', location='New South Wales';
INSERT INTO `afl`.`stadium` SET id=16, name='TIO Stadium', location='Northern Territory';

-- Relational Data

TRUNCATE `afl`.`season`;
INSERT INTO `afl`.`season` SET id=1, competition=1,year=2012;
INSERT INTO `afl`.`season` SET id=2, competition=2,year=2012;

TRUNCATE `afl`.`match`;

INSERT INTO `afl`.`match` SET season=1, round=1, stadium=12, starttime='2012-03-24 19:20:00', hometeam=9, awayteam=16, hometeamgoals=5, hometeampoints=7, awayteamgoals=14, awayteampoints=16;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=9, starttime='2012-03-29 19:45:00', hometeam=14, awayteam=3, hometeamgoals=12, hometeampoints=9, awayteamgoals=18, awayteampoints=17;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=9, starttime='2012-03-30 19:50:00', hometeam=10, awayteam=4, hometeamgoals=20, hometeampoints=17, awayteamgoals=16, awayteampoints=19;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=9, starttime='2012-03-31 14:45:00', hometeam=11, awayteam=2, hometeamgoals=11, hometeampoints=12, awayteamgoals=17, awayteampoints=17;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=11, starttime='2012-03-31 15:45:00', hometeam=8, awayteam=1, hometeamgoals=10, hometeampoints=8, awayteamgoals=19, awayteampoints=23;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=13, starttime='2012-03-31 16:45:00', hometeam=6, awayteam=7, hometeamgoals=16, hometeampoints=9, awayteamgoals=15, awayteampoints=1;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=6, starttime='2012-03-31 19:45:00', hometeam=12, awayteam=5, hometeamgoals=15, hometeampoints=12, awayteamgoals=14, awayteampoints=20;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=6, starttime='2012-04-01 13:10:00', hometeam=18, awayteam=17, hometeamgoals=12, hometeampoints=15, awayteamgoals=21, awayteampoints=10;
INSERT INTO `afl`.`match` SET season=1, round=1, stadium=2, starttime='2012-04-01 16:10:00', hometeam=13, awayteam=15, hometeamgoals=13, hometeampoints=11, awayteamgoals=13, awayteampoints=7;

-- INSERT INTO `afl`.`match` SET season=1, round=1, stadium=, starttime='2012-03', hometeam=, awayteam=, hometeamgoals=, hometeampoints=, awayteamgoals=, awayteampoints=;

