# Supabase 数据库设置指南

为了保存聊天记录，你需要在 Supabase 后台创建一个 `messages` 表。

## 1. 进入 SQL 编辑器
登录 Supabase 控制台，进入你的项目，点击左侧菜单的 **SQL Editor**。

## 2. 运行建表语句
复制以下 SQL 代码并运行：

```sql
-- 创建 messages 表
create table public.messages (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  content text not null,
  is_user boolean not null default true,
  user_id uuid not null references auth.users (id),
  constraint messages_pkey primary key (id)
);

-- 开启行级安全 (RLS)
alter table public.messages enable row level security;

-- 允许用户查看自己的消息
create policy "Users can view their own messages"
on public.messages
for select
to authenticated
using (
  (select auth.uid()) = user_id
);

-- 允许用户插入自己的消息
create policy "Users can insert their own messages"
on public.messages
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
);
```

## 3. 验证
创建成功后，你可以在 **Table Editor** 中看到 `messages` 表。
