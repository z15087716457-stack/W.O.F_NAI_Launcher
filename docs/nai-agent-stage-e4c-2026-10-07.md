# NAI Agent E4C: native image workflow snapshots

2026-10-07, Asia/Taipei. Source: `E:/A.I/NovelAI/.devin/wt/nai-launcher-src`, HEAD `af54e9ac`. E4C fixes the workflow gap reproduced in E4B; the complete E/F product remains in progress. Actual tool count remains 18.

The failing probe saved an infill source/mask, cleared the source, then loaded the configuration. ImageParams restored but ImageWorkflowState stayed `base` with `sourceWidth=null`. The same probe now reports `inpaint` and `sourceWidth=128`.

Configuration snapshots now include native workflow mode, source and original pixel dimensions, base dimensions/strength/noise used when exiting a mode, enhance settings, local/legacy upscale settings and per-model SeedVR2 options. The typed decoder validates modes, finite/ranged scalars, source/mask/focus geometry and model options before importing dependencies or applying draft changes. The native controller restores parameters and workflow synchronously, invalidates pending source imports, clears temporary tool ownership, and persists the same preferences as its normal controls.

Saving while a canvas tool is open keeps the sidebar source/mask and current prompt/reference edits, rather than adopting the tool's temporary source. Temporary jobs, popup expansion and canvas ownership are excluded. Closing an old panel after load cannot restore its former image over the loaded configuration. Reference and generation backups include workflow configuration too.

The shared draft acknowledgement covers workflow content, including settings that do not change ImageParams, such as the selected local upscaler. During loading, the workflow object is also checked again across asynchronous backup/dependency operations. New user changes, Stop, active jobs and disposed bindings retain their existing protection.

Older snapshots without `image_workflow` remain readable: the tool explicitly returns `workflow_settings_saved=false`; image action/geometry are derived and current workflow preferences retained. Missing historical enhance/upscale settings are not presented as saved data. Workspaces still never auto-load configurations.

Validation: 333 distinct domain/native/bridge/Pi checks across 36 test files, 24 existing real-font UI checks and 14 Node checks, total 371. The separate original probe also passes and is not added to that count. The 13 snapshot-provider cases cover native infill/outpaint/focus, enhance exit, local post-generation enhancement and persisted SeedVR2 settings, native upscale exit, both temporary canvas modes, old snapshots, malformed settings, draft/dependency conflicts and workflow-only edits before/during load. Scoped analyze reports no issues; CRLF-aware diff-check passes.

The official Pi subprocess performs save → read → fresh Studio context after native clear → load → read through production schemas and bindings: six local synthetic SSE requests and five tools. Native mode/geometry/parameters are compared after load. Image geometry remains visible in the summary, while original pixel Base64 and private credentials are absent. No real provider/NAI request or Anlas was used.

No annotated generation input, dependency or visible UI strings changed. No Studio build/install/launch/restart/hot reload, commit or push. Installed receipt and app.so hashes are unchanged. Existing closed-Hive fixture logs are retained; those cases pass. Initial compile/test-fixture errors and the obsolete substring assertion are diagnostic history, not successful verification.

Next: reference library/import/export, gallery management, native image tools, exploration and limited settings; then F manuals, official runtime/licenses, isolated Windows input/native-package QA and the complete update package.
