-- 1. 创建 world_meanings 表
create table public.world_meanings (
  id uuid not null default gen_random_uuid() primary key,
  created_at timestamp with time zone default now(),
  
  -- 匿名化数据
  latitude double precision not null,
  longitude double precision not null,
  city text,
  country text,
  
  -- 意义数据
  dimension text not null, -- 存储 MeaningDimension 的字符串值
  intensity double precision default 1.0,
  
  -- 关联用户 (可选，如果想区分“我的”和“别人的”)
  user_id uuid references auth.users(id)
);

-- 2. 开启 RLS
alter table public.world_meanings enable row level security;

-- 3. 权限策略

-- 所有人都可以读取所有数据 (为了生成世界地图)
create policy "Public world meanings are viewable by everyone"
on public.world_meanings for select
to authenticated
using (true);

-- 用户可以插入数据 (生成意义卡时自动插入)
create policy "Users can insert world meanings"
on public.world_meanings for insert
to authenticated
with check (true);

-- 用户不能修改或删除 (保证历史数据的不可篡改性)
-- (不创建 update/delete 策略即可)
