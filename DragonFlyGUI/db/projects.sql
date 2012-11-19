CREATE  TABLE projects (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        project_name            TEXT,
        project_id              TEXT,
        project_start           TEXT,
        project_status          TEXT,
        project_uri             TEXT,
        project_description     TEXT,
        project_documentation   TEXT,
        active                  INTEGER,
        locked                  INTEGER
    );
