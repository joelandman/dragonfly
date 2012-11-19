CREATE  TABLE jobs (
--        id          	INTEGEREGER PRIMARY KEY AUTOINCREMENT,
-- different in postgres
        id          	serial8 unique PRIMARY KEY ,
        jobname     	TEXT,
	jobid	    	TEXT,
	job_owner_uid   INTEGER,
	job_directory   TEXT,	
	queue_jobid     TEXT,
	queue_jobname   TEXT,
        created         timestamp,
        submitted       timestamp,
	queued          timestamp,
	started         timestamp,
	completed       timestamp,
	hold            INTEGER DEFAULT 0,
	assigned_to_cluster TEXT,
	running_on_node TEXT,
	NCPU            INTEGER,
	wallclock_run   TEXT,
	wallclock_queued TEXT,
        jobxml          TEXT,
	job_stdout      TEXT,
	job_stderr      TEXT,
	job_return_code TEXT,
	project		TEXT,
	status		TEXT
	application	TEXT
    );

