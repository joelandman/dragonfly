CREATE TABLE apps (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        appname     TEXT,
	serial	    TEXT,
	version	    TEXT,
	owner_id    INT,
	changable   TEXT,
	date_added  TEXT,
	derived_from INT,
        app_xml     TEXT
    );

-- test data
insert into apps values (1,'ptb','1','1','1','No','2007-11-06','','<program name="ptb" index="1" version="1.0" >
 <env>
  <!-- must have this for normal operation -->
  <var_copy                 value="1" />

  <!-- Add these to the environment -->
  <var_add     name="alpha"     value="5" />
  <var_add     name="beta"     value="4" />
  <var_add     name="gamma"     value="1" />

  <!-- Append this to the end of the PATH -->
  <var_append     name="PATH"     value="/usr/strange/bin" join=":" />

  <!-- Insert this in front of the PATH -->
  <var_insert     name="PATH"     value="/opt/bin" join=":" />

  <!-- Delete this environment variable -->
  <var_del       name="PGI_BITS" />
 </env>
 <exec>
  <run use_mpi_stack="openmpi" version="1.2.4" />
  <param label="ncpus" name="NCPU" comment="number of cpus" default_value="16" />
  <arg  label="steps" name="-n" comment="number of steps" required="1" input_file="no"  output_file="no" />
  <arg  label="debug" name="-debug" comment="debug flag" required="0" input_file="no"  output_file="no" />
  <arg  label="outfile" name="-out" comment="output file" required="0" input_file="no"  output_file="yes" />
  <arg  label="infile" name="-in" comment="input file" required="0" input_file="yes" output_file="no" />
 </exec>
 <mpi>
  <stack name="openmpi" version="1.2.4">
   <path>/opt/openmpi124/bin</path>
   <mpi_init name="" args="" />
   <!--
        would put any sort of orterun or lamboot or ... environment startup
        that is needed here.  For commercial codes, they *usually* start up
    their own stacks, though some link against stacks that require
    initialization
     -->
   <mpirun name="mpirun" args="-np _NCPUS_" />
  </stack>
 </mpi>
 <data_motion>
 </data_motion>
</program> 
');
