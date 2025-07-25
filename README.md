# rime-xh-aux
在oh-my-rime的auxCode_filter.lua插件上进行修改，目的是为了更方便通过辅助码来定位词组、短语。

> ⚠️**注意**：本人不会lua，该插件为边学边改，目前能正常使用，发现问题再修改。

> ⚠️**注意**：目前只测试了**小鹤双拼+小鹤形码作为辅助码**的情况，其他情况还未测试。

## 使用方法
方法1：
1. 将`auxCode_filter2.lua`下载到`RimeUserFolder\lua`目录内。
2. 在「RimeUserFolder」中找到`double_pinyin_flypy.schema.yaml`文件，打开并找到`engine`下的`filters`选项。
3. 将`filters`选项下的`lua_filter@*auxCode_filter@flypy_full`改为`lua_filter@*auxCode_filter2@flypy_full`后保存文件。
4. 重新部署输入法。

方法2:
1. 也可以将仓库中`auxCode_filter2.lua`内的代码用来直接覆盖掉`RimeUserFolder\lua`下的`auxCode_filter.lua`文件代码。
2. 重新部署输入法。

## 功能介绍
> 理念：匹配词组/短语时，使用多字形码组合的形式比完整单字形码更容易精确定位到一个词组。

### 概览
1. 重新定义了**形码匹配模式**；
2. 支持对**多字形码**进行匹配；
3. 添加了**形码通配符**(`` ` ``)。

### 功能说明
#### 一、与原版形码匹配模式的对比
以「双拼」这个词组为例：
- **原版**：输入`ulpb;yy`，可匹配到「双拼」、「双频」两个短语。
- **修改版**：输入`ulpb;yf`，可匹配到的短语只有「双拼」一个了。因为其中的`y`是双的一个形码，`f`是拼的一个形码。

---
##### 1.1 筛选单字
为了适配一次性输入太长，词组不存在的情况，所以增加了**前两个形码可以作为单字匹配项**的设定。

<img width="144" height="190" alt="图片" src="https://github.com/user-attachments/assets/605f295c-70bb-447d-9ccf-1890848c6ed9" />

如上图，此时输入的形码`ub`即表示`真的`两字组成的词组的筛选条件，也表示`真`这个单字的筛选条件。因为：
- 「真」形码是`ub`
- 「真的」词组形码中也包含`ub`。

---
#### 二、多形码模式
匹配规则：`第一个字任意形码 + 第二个字任意形码 ...第n个字的任意形码 [+ 第一个字另一个形码 + 第二个字另一个形码 ...第n个字的另一个形码]`；

常规：
- 双拼：`ulpb;yfyk`，其中`y`为「双」的一个形码，`f`为「拼」的一个形码，`y`为「双」的另一个形码，`k`为「拼」的另一个形码。
- 小鹤：`xnhe;lddn`，其中`l`为「小」的一个形码，`d`为「鹤」的一个形码，`d`为「小」的另一个形码，`n`为「鹤」的另一个形码。

单字形码乱序输入：
- 双拼：`ulpb;ykyf`，其中「拼」的形码`yk`调换了位置，结果依然一样。
- 小鹤：`xnhe;dnld`，其中「小」的形码`ld`互换了位置，「鹤」的形码`dn`也互换了位置，结果依然相同。

---
#### 三、形码通配符
其中（`` ` ``）为通配符，方便忘记某个字的形码时可暂时跳过输入；不过由于形码可以乱序输入，所以此功能一般情况下可以忽略。
- 小鹤：``xnhe;l`dk``，其中「鹤」字的一个形码`d`被通配符`` ` ``代替了。
- 双拼：```ulpb;``yk```，其中「双」、「拼」的各有一个形码被通配符代替了。

### 真实输入截图
![图片](https://github.com/user-attachments/assets/afdcecc5-f0b9-43c8-8ee0-cbb0273011ef)
![图片](https://github.com/user-attachments/assets/3fa58ab2-87aa-4a1b-8660-59487dab7088)



## 更新记录
- 2025-07-22 新增[单字筛选方案](#11-筛选单字)。
