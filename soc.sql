BEGIN;
-- ============================================================
-- 1. ROLES
-- ============================================================

CREATE TABLE roles (
    id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO roles (name)
VALUES
    ('STUDENT'),
    ('TEACHER'),
    ('ADMIN');



-- ============================================================
-- 2. MEDIA FILES
-- ============================================================

CREATE TABLE media_files (
    id BIGSERIAL PRIMARY KEY,

    object_key VARCHAR(255) NOT NULL UNIQUE,
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,

    file_size BIGINT NOT NULL
        CHECK (file_size > 0),

    uploaded_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 3. USERS
-- ============================================================

CREATE TABLE users (
    id UUID PRIMARY KEY,

    keycloak_id UUID NOT NULL UNIQUE,

    role_id SMALLINT NOT NULL
        REFERENCES roles(id),

    email VARCHAR(255) NOT NULL UNIQUE,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,

    about TEXT,

    faculty VARCHAR(255),
    study_program VARCHAR(255),
    study_group VARCHAR(50),

    avatar_media_id BIGINT
        REFERENCES media_files(id)
        ON DELETE SET NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 4. POSTS
-- ============================================================

CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,

    author_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    text TEXT NOT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP
);


CREATE INDEX idx_posts_author
    ON posts(author_id);

CREATE INDEX idx_posts_created
    ON posts(created_at DESC);


-- ============================================================
-- 5. POST MEDIA
-- Связь публикаций и медиафайлов
-- ============================================================

CREATE TABLE post_media (
    post_id BIGINT NOT NULL
        REFERENCES posts(id)
        ON DELETE CASCADE,

    media_id BIGINT NOT NULL
        REFERENCES media_files(id)
        ON DELETE CASCADE,

    order_number SMALLINT NOT NULL
        DEFAULT 1,

    PRIMARY KEY (post_id, media_id),

    UNIQUE (post_id, order_number)
);


-- ============================================================
-- 6. COMMENTS
-- ============================================================

CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,

    post_id BIGINT NOT NULL
        REFERENCES posts(id)
        ON DELETE CASCADE,

    author_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    text TEXT NOT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_comments_post
    ON comments(post_id);


-- ============================================================
-- 7. LIKES
-- ============================================================

CREATE TABLE post_likes (
    post_id BIGINT NOT NULL
        REFERENCES posts(id)
        ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (post_id, user_id)
);


-- ============================================================
-- 8. DIALOGS
-- Только личные диалоги 1-на-1
-- ============================================================

CREATE TABLE dialogs (
    id BIGSERIAL PRIMARY KEY,

    user1_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    user2_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    -- Нельзя создать диалог пользователя с самим собой
    CONSTRAINT chk_dialog_different_users
        CHECK (user1_id <> user2_id),

    -- Пользователи всегда хранятся в одном порядке.
    -- Это предотвращает A-B и B-A как два разных диалога.
    CONSTRAINT chk_dialog_user_order
        CHECK (user1_id < user2_id),

    -- Между двумя пользователями может быть только один диалог.
    CONSTRAINT uq_dialog_users
        UNIQUE (user1_id, user2_id)
);


CREATE INDEX idx_dialogs_user1
    ON dialogs(user1_id);

CREATE INDEX idx_dialogs_user2
    ON dialogs(user2_id);


-- ============================================================
-- 9. MESSAGES
-- ============================================================

CREATE TABLE messages (
    id BIGSERIAL PRIMARY KEY,

    dialog_id BIGINT NOT NULL
        REFERENCES dialogs(id)
        ON DELETE CASCADE,

    sender_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    text TEXT NOT NULL,

    sent_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_messages_dialog_sent
    ON messages(dialog_id, sent_at);




-- ============================================================
-- ЗАВЕРШЕНИЕ
-- ============================================================

COMMIT;