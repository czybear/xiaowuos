CREATE TABLE IF NOT EXISTS courses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    external_id TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT '',
    teacher TEXT NOT NULL DEFAULT '澄木老师',
    summary TEXT NOT NULL DEFAULT '',
    cover_url TEXT NOT NULL DEFAULT '',
    price TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT '',
    source TEXT NOT NULL DEFAULT '',
    raw_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_courses_title ON courses(title);
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category);
CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status);

CREATE TABLE IF NOT EXISTS student_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    external_id TEXT NOT NULL UNIQUE,
    student_name TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    course_title TEXT NOT NULL DEFAULT '',
    teacher TEXT NOT NULL DEFAULT '澄木老师',
    status TEXT NOT NULL DEFAULT '',
    record_time TEXT NOT NULL DEFAULT '',
    remark TEXT NOT NULL DEFAULT '',
    source TEXT NOT NULL DEFAULT '',
    raw_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_student_records_student_name ON student_records(student_name);
CREATE INDEX IF NOT EXISTS idx_student_records_phone ON student_records(phone);
CREATE INDEX IF NOT EXISTS idx_student_records_course_title ON student_records(course_title);
CREATE INDEX IF NOT EXISTS idx_student_records_status ON student_records(status);
CREATE INDEX IF NOT EXISTS idx_student_records_record_time ON student_records(record_time);

CREATE TABLE IF NOT EXISTS members (
    id TEXT PRIMARY KEY,
    phone TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL DEFAULT '',
    avatar_initials TEXT NOT NULL DEFAULT '',
    provider TEXT NOT NULL DEFAULT 'official_account_code',
    member_level TEXT NOT NULL DEFAULT 'course',
    source TEXT NOT NULL DEFAULT 'direct',
    vip_level INTEGER NOT NULL DEFAULT 0,
    growth_points INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending_review',
    joined_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_members_phone ON members(phone);
CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);

CREATE TABLE IF NOT EXISTS auth_verification_codes (
    id TEXT PRIMARY KEY,
    phone TEXT NOT NULL,
    code_hash TEXT NOT NULL,
    purpose TEXT NOT NULL DEFAULT 'login',
    attempts INTEGER NOT NULL DEFAULT 0,
    consumed_at TEXT NOT NULL DEFAULT '',
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_codes_phone ON auth_verification_codes(phone);
CREATE INDEX IF NOT EXISTS idx_auth_codes_expires_at ON auth_verification_codes(expires_at);

CREATE TABLE IF NOT EXISTS auth_sessions (
    id TEXT PRIMARY KEY,
    member_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    device_name TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    revoked_at TEXT NOT NULL DEFAULT '',
    FOREIGN KEY(member_id) REFERENCES members(id)
);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_member_id ON auth_sessions(member_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_expires_at ON auth_sessions(expires_at);

CREATE TABLE IF NOT EXISTS invite_codes (
    id TEXT PRIMARY KEY,
    code_hash TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL DEFAULT '',
    source TEXT NOT NULL DEFAULT 'direct',
    member_level TEXT NOT NULL DEFAULT 'course',
    course_tracks_json TEXT NOT NULL DEFAULT '[]',
    max_uses INTEGER NOT NULL DEFAULT 1,
    used_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    expires_at TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_status ON invite_codes(status);
CREATE INDEX IF NOT EXISTS idx_invite_codes_source ON invite_codes(source);

CREATE TABLE IF NOT EXISTS member_devices (
    id TEXT PRIMARY KEY,
    member_id TEXT NOT NULL,
    device_id_hash TEXT NOT NULL,
    device_name TEXT NOT NULL DEFAULT '',
    platform TEXT NOT NULL DEFAULT 'ios',
    status TEXT NOT NULL DEFAULT 'active',
    first_seen_at TEXT NOT NULL,
    last_seen_at TEXT NOT NULL,
    UNIQUE(member_id, device_id_hash),
    FOREIGN KEY(member_id) REFERENCES members(id)
);

CREATE INDEX IF NOT EXISTS idx_member_devices_member_id ON member_devices(member_id);
CREATE INDEX IF NOT EXISTS idx_member_devices_status ON member_devices(status);

CREATE TABLE IF NOT EXISTS chat_conversations (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    kind TEXT NOT NULL DEFAULT 'direct',
    avatar_text TEXT NOT NULL DEFAULT '',
    participants_json TEXT NOT NULL DEFAULT '[]',
    openclaw_channel TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL DEFAULT 'student',
    body TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text',
    created_at TEXT NOT NULL,
    FOREIGN KEY(conversation_id) REFERENCES chat_conversations(id)
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);

CREATE TABLE IF NOT EXISTS ops_tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    command TEXT NOT NULL DEFAULT '',
    target_node TEXT NOT NULL DEFAULT 'xiaowuOSa',
    status TEXT NOT NULL DEFAULT 'queued',
    source TEXT NOT NULL DEFAULT 'ios',
    dedupe_key TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ops_logs (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL DEFAULT '',
    node_id TEXT NOT NULL DEFAULT '',
    level TEXT NOT NULL DEFAULT 'info',
    message TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ops_tasks_status ON ops_tasks(status);
CREATE INDEX IF NOT EXISTS idx_ops_tasks_created_at ON ops_tasks(created_at);
CREATE INDEX IF NOT EXISTS idx_ops_logs_created_at ON ops_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_ops_logs_task_id ON ops_logs(task_id);
