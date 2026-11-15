# Generation

- `generation_prepare` quotes the current Studio configuration: request count, per-request Anlas, one-time encoding, estimated total, loaded balance, local enhancement and readiness. Optional batch overrides leave the draft unchanged; quotes expire after five minutes.
- `generation_run(quote_id)` rechecks current state, backs up and follows native generation to completion, returning image IDs/files or error/cancellation/partial results.
- Quotes report the Studio confirmation policy in `authorization`. Full access automatically approves zero-total actions; paid actions still show the price card unless the user enabled “Skip paid-action confirmation” in Agent settings. Other permission modes keep their existing confirmation behavior. The total includes reference/encoding fees; quotes, balance checks and cancellation still apply.
- `generation_cancel(run_id?)` stops this chat's admitted generation. Finished images remain available; cancellation does not guarantee a refund. Agent Stop also releases a waiting `generation_run` and pending questions.

Report the actual output count and locations.
