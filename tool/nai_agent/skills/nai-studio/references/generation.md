# Generation

- `generation_prepare` quotes the current Studio configuration: request count, per-request Anlas, one-time encoding, estimated total, loaded balance, local enhancement and readiness. Optional batch overrides leave the draft unchanged; quotes expire after five minutes.
- `generation_run(quote_id)` rechecks current state, backs up and follows native generation to completion, returning image IDs/files or error/cancellation/partial results.
- `generation_cancel(run_id?)` stops this chat's admitted generation. Finished images remain available; cancellation does not guarantee a refund. Agent Stop also releases a waiting `generation_run` and pending questions.

Report the actual output count and locations.
