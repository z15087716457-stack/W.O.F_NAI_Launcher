# Generation

Enter the paid flow only when the user explicitly asks to generate or test-generate.

- `generation_prepare` freezes a quote from the current Studio configuration without any network request or generation. It returns request count, per-request encoding cost, total Anlas and current balance. Tell the user these numbers first.
- `generation_run(quote_id)` waits for the real in-app user button, then follows native generation to completion. Expired quotes, changed state and repeated quotes are rejected; prepare again.
- `generation_cancel(run_id?)` stops only this chat's admitted generation. It never cancels another chat or a newer manual generation, and does not guarantee a refund. Agent Stop also releases a waiting `generation_run` and pending questions.

After completion report the actual number of images and where they are. Do not replay an old run when state looks inconsistent; read current state first.
