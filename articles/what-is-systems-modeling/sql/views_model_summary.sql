-- views_model_summary.sql
-- Summary views for systems modeling runs and outputs.

CREATE VIEW IF NOT EXISTS v_model_run_summary AS
SELECT
  r.run_id,
  r.article_slug,
  r.model_name,
  r.scenario_name,
  r.purpose,
  COUNT(o.output_id) AS output_count,
  AVG(o.metric_value) AS average_metric_value
FROM model_runs r
LEFT JOIN model_outputs o
  ON r.run_id = o.run_id
GROUP BY
  r.run_id,
  r.article_slug,
  r.model_name,
  r.scenario_name,
  r.purpose;

CREATE VIEW IF NOT EXISTS v_validation_pass_rate AS
SELECT
  run_id,
  COUNT(*) AS diagnostic_count,
  SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) AS passed_count,
  CAST(SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) AS pass_rate
FROM validation_diagnostics
GROUP BY run_id;
