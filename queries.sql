

-- Top 10 by words (all episodes)
select name, sum(wc)
from speakers s join speeches e on s.speaker_id = e.speaker_id
  join eps_panel p on s.speaker_id = p.speaker_id and e.ep_id = p.ep_id
group by name
order by sum(wc) desc
limit 10;

-- Top 10 by words (complete panels)
select name, sum(wc)
from speakers s join speeches e on s.speaker_id = e.speaker_id
  join eps_panel_complete p on s.speaker_id = p.speaker_id and e.ep_id = p.ep_id
group by name
order by sum(wc) desc
limit 10;

-- Top 10 by app (complete panels)
select name, count(ep_id)
from speakers s join eps_panel_complete p on s.speaker_id = p.speaker_id
group by name
order by count(ep_id) desc
limit 10;

-- Top 10 by app (non politicians)
select name, count(ep_id)
from speakers s join eps_panel_complete p on s.speaker_id = p.speaker_id
where p.occ <> 'POLITICIAN'
group by name
order by count(ep_id) desc
limit 10;









-- Total number of unique panellists by sex
DROP VIEW IF EXISTS unique_by_sex;
CREATE VIEW unique_by_sex
AS
SELECT sex, count(*)
FROM
(SELECT DISTINCT sex,
                 s.speaker_id
FROM     eps_panel q JOIN speakers s ON q.speaker_id = s.speaker_id)
GROUP BY sex
ORDER BY sex;

-- Total number of appearances by sex
DROP VIEW IF EXISTS apps_by_sex;
CREATE VIEW apps_by_sex
AS
SELECT   sex,
         count(*) as apps
FROM     eps_panel q JOIN speakers s ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of speeches by sex
DROP VIEW IF EXISTS speeches_by_sex;
CREATE VIEW speeches_by_sex
AS
SELECT   sex,
         count(*) as speeches
FROM     eps_panel q
    JOIN speeches
    ON q.ep_id = speeches.ep_id AND q.speaker_id = speeches.speaker_id
    JOIN speakers s
    ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of words by sex
DROP VIEW IF EXISTS  words_by_sex;
CREATE VIEW words_by_sex
AS
SELECT    sex,
          sum(wc) as words
FROM      eps_panel q
    JOIN speeches
    ON q.ep_id = speeches.ep_id AND q.speaker_id = speeches.speaker_id
    JOIN speakers s
    ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of unique panellists by sex (complete panels)
DROP VIEW IF EXISTS unique_by_sex_complete;
CREATE VIEW unique_by_sex_complete
AS
SELECT sex, count(*)
FROM
(SELECT DISTINCT sex,
                 s.speaker_id
FROM     eps_panel_complete q JOIN speakers s ON q.speaker_id = s.speaker_id)
GROUP BY sex
ORDER BY sex;

-- Total number of appearances by sex (complete panels)
DROP VIEW IF EXISTS apps_by_sex_complete;
CREATE VIEW apps_by_sex_complete
AS
SELECT   sex,
         count(*) as apps
FROM     eps_panel_complete q JOIN speakers s ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of speeches by sex (complete panels)
DROP VIEW IF EXISTS speeches_by_sex_complete;
CREATE VIEW speeches_by_sex_complete
AS
SELECT   sex,
         count(*) as speeches
FROM     eps_panel_complete q
    JOIN speeches
    ON q.ep_id = speeches.ep_id AND q.speaker_id = speeches.speaker_id
    JOIN speakers s
    ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of words by sex (complete panels)
DROP VIEW IF EXISTS  words_by_sex_complete;
CREATE VIEW words_by_sex_complete
AS
SELECT    sex,
          sum(wc) as words
FROM      eps_panel_complete q
    JOIN speeches
    ON q.ep_id = speeches.ep_id AND q.speaker_id = speeches.speaker_id
    JOIN speakers s
    ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of unique panellists by sex (Trioli panels)
DROP VIEW IF EXISTS unique_by_sex_trioli;
CREATE VIEW unique_by_sex_trioli
AS
SELECT sex, count(*)
FROM
(SELECT DISTINCT sex,
                 s.speaker_id
FROM     eps_panel_trioli q JOIN speakers s ON q.speaker_id = s.speaker_id)
GROUP BY sex
ORDER BY sex;

-- Total number of appearances by sex (Trioli panels)
DROP VIEW IF EXISTS apps_by_sex_trioli;
CREATE VIEW apps_by_sex_trioli
AS
SELECT   sex,
         count(*) as apps
FROM     eps_panel_trioli q JOIN speakers s ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of speeches by sex (Trioli panels)
DROP VIEW IF EXISTS speeches_by_sex_trioli;
CREATE VIEW speeches_by_sex_trioli
AS
SELECT   sex,
         count(*) as speeches
FROM     eps_panel_trioli q
    JOIN speeches
    ON q.ep_id = speeches.ep_id AND q.speaker_id = speeches.speaker_id
    JOIN speakers s
    ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Total number of words by sex (complete panels)
DROP VIEW IF EXISTS  words_by_sex_trioli;
CREATE VIEW words_by_sex_trioli
AS
SELECT    sex,
          sum(wc) as words
FROM      eps_panel_trioli q
    JOIN speeches
    ON q.ep_id = speeches.ep_id AND q.speaker_id = speeches.speaker_id
    JOIN speakers s
    ON q.speaker_id = s.speaker_id
GROUP BY sex
ORDER BY sex;

-- Scores for panellists
SELECT    s.name, m.party, ((ms.answer1 + ms.answer2)/2) as score, count(*)
FROM      mentions m
  JOIN    mentions_scores ms
  ON      m.mention_id = ms.mention_id
  JOIN    speakers s
  ON      s.speaker_id = m.mention_speaker_id
GROUP BY  s.name, m.party, score;

-- Score
CREATE VIEW daily_mention_score AS
SELECT mention_speaker_id, 
   hdate,
   first_name,
   last_name,
   house,
   member_id,
   party,
   count (*) as mention_count,
   MIN (score) as min_score,
   MAX (score) as max_score
FROM
   mentions m JOIN mentions_scores_amw ms ON m.mention_id = ms.mention_id
WHERE
   ABS (score) <= 2
GROUP BY
mention_speaker_id, 
   hdate,
   first_name,
   last_name,
   house,
   member_id,
   party;
   
 CREATE VIEW daily_mention_aggscore AS
 SELECT *,
    CASE
      WHEN min_score = max_score THEN min_score
      WHEN min_score < 0 AND max_score > 0 THEN 0
      WHEN min_score >= 0 AND max_score > 0 THEN max_score
      WHEN min_score < 0 AND max_score <= 0 THEN min_score
      ELSE 999
    END as agg_score
 FROM daily_mention_score;
   
  