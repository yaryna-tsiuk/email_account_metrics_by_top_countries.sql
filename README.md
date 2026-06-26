# email_account_metrics_by_top_countries.sql
Aggregates account and email engagement metrics (sent, open, visit) by date, country, send interval, and account status. Uses UNION ALL to combine account and email data, window functions to calculate country-level totals, and DENSE_RANK to filter the top 10 countries by account count and sent messages.
