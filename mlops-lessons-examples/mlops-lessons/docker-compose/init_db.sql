-- init_db.sql
CREATE TABLE IF NOT EXISTS predictions (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    filename VARCHAR(255) NOT NULL,
    prediction VARCHAR(50) NOT NULL
);