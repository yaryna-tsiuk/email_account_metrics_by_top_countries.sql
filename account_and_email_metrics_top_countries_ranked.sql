-- Account aggregation
WITH part_1 AS (
SELECT 
date,
country, 
send_interval,
is_verified,
is_unsubscribed,
COUNT(DISTINCT id) AS account_cnt
FROM DA.session s
JOIN DA.session_params sp
ON s.ga_session_id = sp.ga_session_id
JOIN DA.account_session acs
ON sp.ga_session_id = acs.ga_session_id
JOIN DA.account a
ON acs.account_id = a.id
GROUP BY date, country, send_interval, is_verified, is_unsubscribed),

-- Email metrics by date
part_2 AS (
SELECT s.date AS date,
COUNT(DISTINCT es.id_message) AS sent_msg,
COUNT(DISTINCT eo.id_message) AS open_msg,
COUNT(DISTINCT ev.id_message) AS visit_msg
FROM  DA.email_sent es
JOIN  `DA.account_session` acs
ON es.id_account = acs.account_id
JOIN `DA.session` s
ON acs.ga_session_id = s.ga_session_id
LEFT JOIN `DA.email_open` eo
ON es.id_message = eo.id_message
LEFT JOIN `DA.email_visit` ev
ON es.id_message = ev.id_message
GROUP BY date
),

-- Total metrics by country
part_3 AS (
SELECT 
country,
SUM(account_cnt) AS total_country_account_cnt,
SUM(sent_msg) AS total_country_sent_cnt
FROM (
SELECT
country,
account_cnt,
0 AS sent_msg
FROM part_1
UNION ALL
SELECT sp.country,
0 AS account_cnt,
COUNT(DISTINCT es.id_message) AS sent_msg
FROM DA.email_sent es
JOIN DA.account_session acs
ON es.id_account = acs.account_id
JOIN DA.session_params sp
ON acs.ga_session_id = sp.ga_session_id
GROUP BY sp.country
)
GROUP BY country),

-- Country rankings
part_4 AS (
SELECT
*,
RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
RANK() OVER (ORDER BY total_country_sent_cnt DESC)  AS rank_total_country_sent_cnt
FROM part_3
)

-- Final result
SELECT
p1.date,
p1.country,
p1.send_interval,
p1.is_verified,
p1.is_unsubscribed,
p1.account_cnt,
p2.sent_msg,
p2.open_msg,
p2.visit_msg,
p4.total_country_account_cnt,
p4.total_country_sent_cnt,
p4.rank_total_country_account_cnt,
p4.rank_total_country_sent_cnt
FROM part_1 p1
LEFT JOIN part_2 p2
ON p1.date = p2.date
LEFT JOIN part_4 p4
ON p1.country = p4.country
WHERE
p4.rank_total_country_account_cnt <= 10 OR p4.rank_total_country_sent_cnt <= 10
ORDER BY p1.date, p1.country;
