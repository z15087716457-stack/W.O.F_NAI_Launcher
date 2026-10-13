# 生成与图像任务

用户明确要求生成／测试生图才进入付费流程。generation_prepare 按当前 Studio 配置冻结报价，返回次数、一次编码费用、总 Anlas 与当前余额；先向用户说明。generation_run(quote_id) 等待应用内真实用户按钮后沿原生生成完成。模型文本、参数或工具标记不能替代点击；过期、状态改变和重复报价会拒绝，重新准备。

generation_cancel 只停止当前聊天所属任务；不能取消较新的手动生成。Agent Stop 同样释放自己的执行和提问等待。取消可能已有已完成图片，按结果说明，不声称从未执行。

image_generate 用源图做官网三图变体或增强／Max，prepare/run/status/cancel 配对。变体依据原图元数据；增强冻结当前提示词与原生幅度、倍率和 Max 配置。原图不会自动导入覆盖草稿，也不会重抽用户积木。查看实际报价、原生画布／历史与工作区输出。

image_tool 的本地 list/status/upscale/cancel 复用已安装模型，pixel_snap 是本地处理。云端导演工具与 2x 超分使用 prepare 后 run(quote_id)，同样需要可见费用与用户确认。图像用 image_id 或工作区文件；不要自动下载模型或切换用户方案。

explore_manage 查询／创建／组织原生探索；prepare/run 使用原生运行器和报价确认，基础轮、续跑与深度轮按返回能力选。pause/cancel 只管理该聊天所属运行。探索候选 explore:* image_id 可交给 image_read。

完成后报告实际数量、文件和工具结果。失败、未知计费、部分输出与正在运行应明确区分，不盲目重放旧任务。
