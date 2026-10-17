# V5／N5

此入口用于 nai-diffusion-5 系列。先通过 studio_context 核对完整模型 ID、当前工作流和原生能力；不要套用 V4／V4.5 规则或根据标签名称猜测支持范围。

用户现有参数是当前任务依据。写入原始主／负面提示词和角色必须使用 scope=draft 返回的字段和版本；保留积木、翻译原文及启用状态。生成预设的生效投影不直接覆盖编辑文本。

源图、遮罩与参考支持以 reference_manage 返回的当前配置和模型能力为准。不能假设旧模型的采样器、权重语法、质量词、角色位置或 Vibe 编码参数在 V5 完全相同。需要具体规则时按需读取用户提供的 V5 资料或用可用网络工具核对官方文档；未经核实的限制明确说明。

生成和增强费用从原生 prepare 返回，实际运行需可见确认。模型名称与服务端能力可能不同，不用旧模型报价或推断资格代替检查。

V5 Full 的 Turbo（官方 Medium Effort）使用 `nai-diffusion-5-full-medium`，局部重绘使用 `nai-diffusion-5-full-medium-inpainting`。读取 `model_constraints` 判断当前限制：固定 14 步、Euler Ancestral、Heavy 负面预设，不支持自定义主／角色负面提示词与 CFG Rescale；引导强度仍可调整。界面中的 Full 家族名称与闪电开关共同表示实际模型，不能只看黑色胶囊的名称。

Turbo 的固定设置在报价与请求时投影生效，`scope=draft`／`draft_summary` 仍可包含为切回 Full 保留的原始步数、采样器和负面内容。不要为了匹配固定值改写这些草稿；实际参数、价格及付费资格读取 `generation_prepare`。不能仅凭图片使用 14 步就认定为 Turbo。

操作语义见 [studio.md](studio.md) 和 [generation.md](generation.md)。
