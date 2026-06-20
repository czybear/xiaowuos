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
