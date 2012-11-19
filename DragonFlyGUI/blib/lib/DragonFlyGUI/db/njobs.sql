CREATE  TABLE jobs (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        jobname     TEXT,
        submitted   INT DEFAULT 0,
        jobxml      TEXT
    );
