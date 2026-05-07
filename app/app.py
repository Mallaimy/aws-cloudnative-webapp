import os
import re
import psycopg2
import psycopg2.pool
import psycopg2.extras
from flask import Flask, request, jsonify, render_template, g

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Connection pool — created once at startup
# ---------------------------------------------------------------------------
pool = psycopg2.pool.SimpleConnectionPool(
    minconn=1,
    maxconn=5,
    host=os.environ["DB_HOST"],
    port=os.environ.get("DB_PORT", 5432),
    dbname=os.environ["DB_NAME"],
    user=os.environ["DB_USER"],
    password=os.environ["DB_PASSWORD"],
)


def get_conn():
    """Return a connection from the pool, stored on Flask's request context."""
    if "db" not in g:
        g.db = pool.getconn()
    return g.db


@app.teardown_appcontext
def release_conn(exc):
    conn = g.pop("db", None)
    if conn is not None:
        pool.putconn(conn)


# ---------------------------------------------------------------------------
# Startup: schema init + idempotent seeding
# ---------------------------------------------------------------------------
def init_db():
    conn = pool.getconn()
    try:
        # Schema setup (race-tolerant)
        try:
            with conn, conn.cursor() as cur:
                with open("schema.sql") as f:
                    cur.execute(f.read())
        except psycopg2.errors.UniqueViolation:
            conn.rollback()

        # Seed setup (using advisory lock to serialize across workers)
        with conn, conn.cursor() as cur:
            cur.execute("SELECT pg_try_advisory_lock(12345)")
            (got_lock,) = cur.fetchone()
            if got_lock:
                try:
                    cur.execute("SELECT COUNT(*) FROM questions")
                    (count,) = cur.fetchone()
                    if count == 0:
                        _seed_questions(cur)
                finally:
                    cur.execute("SELECT pg_advisory_unlock(12345)")
    finally:
        pool.putconn(conn)


def _seed_questions(cur):
    """Insert questions from seed_questions.txt (skips empty lines and comments)."""
    with open("seed_questions.txt") as f:
        lines = f.readlines()

    questions = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # Strip leading "N. " numbering if present
        text = re.sub(r"^\d+\.\s*", "", line)
        if text:
            questions.append((text,))

    if questions:
        cur.executemany("INSERT INTO questions (content) VALUES (%s)", questions)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.route("/")
def index():
    conn = get_conn()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT id, content FROM questions ORDER BY RANDOM() LIMIT 1")
        question = cur.fetchone()
    return render_template("index.html", question=question)


@app.route("/api/question")
def api_random_question():
    conn = get_conn()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(
            "SELECT id, content, created_at FROM questions ORDER BY RANDOM() LIMIT 1"
        )
        question = cur.fetchone()
    if question is None:
        return jsonify({"error": "No questions found"}), 404
    question["created_at"] = question["created_at"].isoformat()
    return jsonify(question)


@app.route("/api/question/<int:question_id>/responses")
def api_question_responses(question_id: int):
    conn = get_conn()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT id FROM questions WHERE id = %s", (question_id,))
        if cur.fetchone() is None:
            return jsonify({"error": "Question not found"}), 404

        try:
            page = max(1, int(request.args.get("page", 1)))
        except ValueError:
            page = 1
        per_page = 20
        offset = (page - 1) * per_page

        cur.execute(
            """
            SELECT id, content, created_at
            FROM responses
            WHERE question_id = %s
            ORDER BY created_at DESC
            LIMIT %s OFFSET %s
            """,
            (question_id, per_page, offset),
        )
        rows = cur.fetchall()
        for row in rows:
            row["created_at"] = row["created_at"].isoformat()

        cur.execute(
            "SELECT COUNT(*) FROM responses WHERE question_id = %s", (question_id,)
        )
        (total,) = cur.fetchone()

    return jsonify(
        {
            "question_id": question_id,
            "page": page,
            "per_page": per_page,
            "total": total,
            "responses": rows,
        }
    )


@app.route("/api/responses", methods=["POST"])
def api_submit_response():
    data = request.get_json(silent=True) or {}
    question_id = data.get("question_id")
    content = data.get("content", "")

    if not question_id:
        return jsonify({"error": "question_id is required"}), 400
    if not isinstance(content, str) or not content.strip():
        return jsonify({"error": "content is required"}), 400
    if len(content) > 2000:
        return jsonify({"error": "content must be 2000 characters or fewer"}), 400

    conn = get_conn()
    with conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT id FROM questions WHERE id = %s", (question_id,))
        if cur.fetchone() is None:
            return jsonify({"error": "Question not found"}), 404

        cur.execute(
            """
            INSERT INTO responses (question_id, content)
            VALUES (%s, %s)
            RETURNING id, question_id, content, created_at
            """,
            (question_id, content.strip()),
        )
        row = cur.fetchone()
        row["created_at"] = row["created_at"].isoformat()

    return jsonify(row), 201


@app.route("/health")
def health():
    try:
        conn = get_conn()
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        return jsonify({"status": "healthy"}), 200
    except Exception as exc:
        return jsonify({"status": "unhealthy", "error": str(exc)}), 503


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=8080)
else:
    # Called by gunicorn: init once before serving
    with app.app_context():
        init_db()
