WITH part_1_accounts AS (
-- Main metrics by accounts
SELECT
s.date,
sp.country,
a.send_interval,
a.is_verified,
a.is_unsubscribed,
COUNT(DISTINCT a.id) AS account_cnt,
0 AS sent_msg,
0 AS open_msg,
0 AS visit_msg
FROM DA.account a
JOIN DA.account_session acs
ON a.id = acs.account_id
JOIN DA.session s
ON acs.ga_session_id = s.ga_session_id
JOIN DA.session_params sp
ON s.ga_session_id = sp.ga_session_id
GROUP BY s.date, sp.country, a.send_interval, a.is_verified, a.is_unsubscribed
),

part_2_emails AS (
-- Main metrics by emails
SELECT
s.date,
sp.country,
a.send_interval,
a.is_verified,
a.is_unsubscribed,
0 AS account_cnt,
COUNT(DISTINCT es.id_message) AS sent_msg,
COUNT(DISTINCT eo.id_message) AS open_msg,
COUNT(DISTINCT ev.id_message) AS visit_msg
FROM DA.email_sent es
JOIN DA.account_session acs
ON es.id_account = acs.account_id
JOIN DA.session s
ON acs.ga_session_id = s.ga_session_id
JOIN DA.session_params sp
ON s.ga_session_id = sp.ga_session_id
JOIN DA.account a
ON acs.account_id = a.id
LEFT JOIN DA.email_open eo
ON es.id_message = eo.id_message
LEFT JOIN DA.email_visit ev
ON es.id_message = ev.id_message
GROUP BY s.date, sp.country, a.send_interval, a.is_verified, a.is_unsubscribed
),

part_3_union AS (
-- Union of accounts and emails
SELECT * FROM part_1_accounts
UNION ALL
SELECT * FROM part_2_emails
),

part_4_grouped AS (
-- Grouping by all dimensions
SELECT
date,
country,
send_interval,
is_verified,
is_unsubscribed,
SUM(account_cnt) AS account_cnt,
SUM(sent_msg) AS sent_msg,
SUM(open_msg) AS open_msg,
SUM(visit_msg) AS visit_msg
FROM part_3_union
GROUP BY date, country, send_interval, is_verified, is_unsubscribed
),

part_5_totals AS (
-- Totals by country (window functions)
SELECT
*,
SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,
SUM(sent_msg)   OVER (PARTITION BY country) AS total_country_sent_cnt
FROM part_4_grouped
),

part_6_ranked AS (
-- Rankings by totals
SELECT
*,
DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_country_sent_cnt
FROM part_5_totals
)

-- Final result
SELECT *
FROM part_6_ranked
WHERE rank_total_country_account_cnt <= 10 OR rank_total_country_sent_cnt <= 10
ORDER BY date, country;
