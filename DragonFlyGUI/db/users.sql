CREATE TABLE users (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name              TEXT,
        last_name               TEXT,
        login_name              TEXT,
        email_addr              TEXT,
        phone_office            TEXT,
        phone_cell              TEXT,
        date_added              TEXT,
        enabled                 INTEGER
    );
--- users has-many user_id

CREATE TABLE user_id (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        'uid'                   int,
        'gid'                   int,
        'user'                  integer REFERENCES users(id)
    );
--- user_id has-one user_auth

CREATE TABLE user_auth (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        'password'              text,
        'ssh_key'               text,
        'user'                  integer REFERENCES user_id(id)
    );

CREATE TABLE roles (
            id   INTEGER PRIMARY KEY,
            role TEXT
    );

CREATE TABLE user_roles (
            user_id INTEGER,
            role_id INTEGER,
            PRIMARY KEY (user_id, role_id)
    );

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
--- project has-many project_users


CREATE TABLE project_users (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        'user'                  integer REFERENCES users(id),
        project                 integer REFERENCES projects(id),
        role                    TEXT,
        date_joined             TEXT,
        date_left               TEXT,
        data_repository         integer REFERENCES data_motion(id),
        access_type             varchar(10),
        active                  INTEGER,
        access                  TEXT
    );
--- project_users has-many data_motion repositories

CREATE TABLE data_motion (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        'uri_depository'        text,
        project                 integer REFERENCES projects(id)
    );
