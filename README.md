# rime-xh-aux
在oh-my-rime的auxCode_filter.lua插件上进行修改，目的是为了更方便通过辅助码来定位词组。

> ⚠️**注意**：本人不会lua，该插件为边学边改，目前能正常使用，发现问题再修改。

> ⚠️**注意**：目前只测试了**小鹤双拼+小鹤形码作为辅助码**的情况，其他情况还未测试。

## 功能介绍
以「**双拼**」词组为例，两字音形分别为：`ulyy`、`pbfk`。原本输入方式只能根据首字的形码来定位词组，即根据「双」的形码，`ulpb;yy`。

修改过后：
1. 双拼部分不变：ulpb
2. **辅助码改为**：第一个字任意形码 + 第二个字任意形码 + 第一个字任意形码 + 第二个字任意形码

完整形式：`ulpb;yfyk`

为了方便，辅助码可以不用输入完全：
- `ulpb;yf`
- ``ulpf;`f``

其中（`` ` ``）为通配符，方便忘记某个字的形码时可暂时跳过输入。

![图片](https://github.com/user-attachments/assets/afdcecc5-f0b9-43c8-8ee0-cbb0273011ef)
![图片](https://github.com/user-attachments/assets/3fa58ab2-87aa-4a1b-8660-59487dab7088)

