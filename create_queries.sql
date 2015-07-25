-- Words per speaker per episode
DROP VIEW IF EXISTS speaker_wc;
CREATE VIEW speaker_wc
AS
SELECT   ep_date,speaker_id,name,sum(wc) as total_wc
FROM     speeches NATURAL JOIN speakers
GROUP BY ep_date,speaker_id,name
ORDER BY ep_date ASC, total_wc DESC;

-- Fair panels (complete panels with one lib, one coalition)
DROP VIEW IF EXISTS eps_panel_w_extra;
CREATE VIEW eps_panel_w_extra
AS
SELECT   ep.ep_date as ep_date,ep.speaker_id as speaker_id,name,bio,gender,occupation,party
FROM     eps_panel ep LEFT NATURAL JOIN eps_panel_extra epe
ORDER BY name ASC, ep_date ASC;

-- Count of participants on the panel for each episode
DROP VIEW IF EXISTS panel_count;
CREATE VIEW panel_count
AS
SELECT   ep_date,
         count(*) as c
FROM     eps_panel
GROUP BY ep_date; 

-- Frequency of panel size
DROP VIEW IF EXISTS panel_count_freq; 
CREATE VIEW panel_count_freq
AS
SELECT c, count(*)
FROM panel_count
GROUP BY c;

-- Complete panels (5 participants)
DROP VIEW IF EXISTS eps_panel_complete;
CREATE VIEW eps_panel_complete
AS
SELECT   *
FROM     eps_panel_w_extra q
WHERE    q.ep_date IN (
    SELECT p.ep_date
    FROM   panel_count p
    WHERE  p.c = 5
);

-- Fair panels (complete panels with one labor, one coalition)
DROP VIEW IF EXISTS eps_panel_fair;
CREATE VIEW eps_panel_fair
AS
SELECT   *
FROM     eps_panel_complete ec
WHERE    1 = (
    SELECT count(*)
    FROM   eps_panel_w_extra p
    WHERE  p.ep_date = ec.ep_date
    AND    p.occupation = 'POLITICIAN' AND p.party = 'LABOR'
) AND    1 = (
    SELECT count(*)
    FROM   eps_panel_w_extra p
    WHERE  p.ep_date = ec.ep_date
    AND    p.occupation = 'POLITICIAN' AND p.party IN ('LIBERAL', 'NATIONAL', 'LNP')
);


-- 'Trioli' panels
DROP VIEW IF EXISTS eps_panel_trioli;
CREATE VIEW eps_panel_trioli
AS
SELECT   *
FROM     eps_panel q
WHERE    q.ep_date IN (
  SELECT ep_date
  FROM speeches
  WHERE speaker_id = (
    SELECT speaker_id
    FROM speakers
    WHERE name LIKE "%TRIOLI%" OR name LIKE "%CRABB%"
  )
);

-- Total number of appearances by party (for politicians on panels of 5 only)
DROP VIEW IF EXISTS apps_by_party_pols_complete_panels;
CREATE VIEW apps_by_party_pols_complete_panels
AS
SELECT   party,
         count(*) as apps
FROM     eps_panel_complete q
WHERE    q.occupation = 'POLITICIAN'
GROUP BY party
ORDER BY party;

-- Total number of speeches by party (for politicians on panels of 5 only)
DROP VIEW IF EXISTS speeches_by_party_pols_complete_panels;
CREATE VIEW speeches_by_party_pols_complete_panels
AS
SELECT   party,
         count(*) as speeches
FROM     eps_panel_complete q
    JOIN speeches
    ON q.ep_date = speeches.ep_date AND q.speaker_id = speeches.speaker_id
WHERE    q.occupation = 'POLITICIAN'
GROUP BY  party
ORDER BY  party;


-- Total number of words by party (for politicians on panels of 5 only)
DROP VIEW IF EXISTS words_by_party_pols_complete_panels;
CREATE VIEW words_by_party_pols_complete_panels
AS
SELECT    party,
          sum(wc) as words
FROM      eps_panel_complete q
    JOIN  speeches
    ON    q.ep_date = speeches.ep_date AND q.speaker_id = speeches.speaker_id
WHERE     q.occupation = 'POLITICIAN'
GROUP BY  party
ORDER BY  party;


-- List of words by appearance by party (for politicians on panels of 5 only)
DROP VIEW IF EXISTS sample_words_by_party_pols_complete_panels;
CREATE VIEW sample_words_by_party_pols_complete_panels
AS
SELECT    q.ep_date,
          q.speaker_id,
          party,
          sum(wc) as words
FROM      eps_panel_complete q
    JOIN  speeches
    ON    q.ep_date = speeches.ep_date AND q.speaker_id = speeches.speaker_id
WHERE     q.occupation = 'POLITICIAN'
GROUP BY  q.ep_date, q.speaker_id
ORDER BY  q.ep_date, q.speaker_id;

-- Running total of words by party (for politicians on panels of 5 only)
DROP VIEW IF EXISTS cumwords_by_party_pols_complete_panels;
CREATE VIEW cumwords_by_party_pols_complete_panels
AS
SELECT    q.ep_date,
          seq,
          party,
          wc
FROM      eps_panel_complete q
    JOIN  speeches s
    ON    q.ep_date = s.ep_date AND q.speaker_id = s.speaker_id
WHERE     q.occupation = 'POLITICIAN'
ORDER BY  q.ep_date ASC, seq ASC;

DROP VIEW IF EXISTS cumwords_by_party_pols_fair_panels;
CREATE VIEW cumwords_by_party_pols_fair_panels
AS
SELECT    q.ep_date,
          seq,
          party,
          wc
FROM      eps_panel_fair q
    JOIN  speeches s
    ON    q.ep_date = s.ep_date AND q.speaker_id = s.speaker_id
WHERE     q.occupation = 'POLITICIAN'
ORDER BY  q.ep_date ASC, seq ASC;