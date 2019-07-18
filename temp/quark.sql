\echo "What is my script absolute path?"
\set QUIET ON
\s psql_command_line_history
\! cat psql_command_line_history | grep "\\i '" | tail -1 > psql_command_line_history_last_line
\set script_path `cat psql_command_line_history_last_line | tail -1`
\echo "My script absolute filename is: ":script_path
