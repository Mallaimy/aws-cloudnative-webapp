CREATE SEQUENCE IF NOT EXISTS questions_id_seq;
CREATE SEQUENCE IF NOT EXISTS responses_id_seq;

CREATE TABLE IF NOT EXISTS questions (
    id         INTEGER PRIMARY KEY DEFAULT nextval('questions_id_seq'),
    content    TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS responses (
    id          INTEGER PRIMARY KEY DEFAULT nextval('responses_id_seq'),
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_responses_question_id ON responses(question_id);