
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS tags;
-- DROP TABLE IF EXISTS users;


PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
  
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(id)
  FOREIGN KEY (question_id) REFERENCES questions(id)
  
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (reply_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id) 
  
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_like INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  
  FOREIGN KEY (question_like) REFERENCES questions(id)
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Mason', 'Anders'),
  ('Joonho', 'Syn');
  
INSERT INTO 
  questions (title, body, author_id)
VALUES
  ('Color', 'What is your favorite color?', 2),
  ('Food', 'What is your favorite food?', 1);
  
INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (2, 1),
  (1, 2),
  (1, 1);
  
INSERT INTO
  replies (question_id, reply_id, user_id, body)
VALUES
  (1, null, 1, 'Purple'),
  (2, null, 2, 'Beef'),
  (1, 1, 2, 'Cool!');
  
INSERT INTO
  question_likes (question_like, user_id)
VALUES
  (1, 1),
  (2, 2);
  