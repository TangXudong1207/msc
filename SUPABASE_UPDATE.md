# Supabase 数据库更新指南

为了支持“意义卡”功能，我们需要在 `messages` 表中添加一个新的字段。

## 1. 进入 SQL 编辑器
登录 Supabase 控制台，进入你的项目，点击左侧菜单的 **SQL Editor**。

## 2. 运行更新语句
复制以下 SQL 代码并运行：

```sql
-- 添加 meaning_card 字段
alter table public.messages 
add column meaning_card text;
```

## 3. 验证
运行成功后，你可以在 **Table Editor** 中看到 `messages` 表多了一列 `meaning_card`。
