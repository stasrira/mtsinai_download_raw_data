smtp.mssm.edu 25

swaks --to stasrirak.ms@gmail.com --server smtp.mssm.edu:25


#=======>with multiple attachment
swaks --server smtp.mssm.edu:25 --to stasrirak.ms@gmail.com,stasrira@yahoo.com --from stas.rirak@mssm.edu --header "Subject: Custom Subject #4" --body "Test body email #5" --attach "/ext_data/stas/config/logs/20191101_153153_process_requests_logs/20191101_153153_error_log.txt" --attach "/ext_data/stas/config/logs/20191101_153153_process_requests_logs/20191101_153153_request_log.txt" 


swaks --server smtp.mssm.edu:25 --to stasrirak.ms@gmail.com,stasrira@yahoo.com --from stas.rirak@mssm.edu --header "Subject: Custom Subject #4"  --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body "Test <b>body aaa</b> email #51" --attach-type text/html --attach "/ext_data/stas/config/logs/20191101_153153_process_requests_logs/20191101_153153_error_log.txt" --attach-type text/plain --attach "/ext_data/stas/config/logs/20191101_153153_process_requests_logs/20191101_153153_request_log.txt"

#html email (winthout attachments)
swaks --to stasrirak.ms@gmail.com,stasrira@yahoo.com --from stas.rirak@mssm.edu --header "Subject: Custom Subject #3" --add-header "MIME-Version: 1.0" --add-header "Content-Type: text/html" --body 'Test <b>body aaa</b> email #5' --server smtp.mssm.edu:25




swaks --to stasrirak.ms@gmail.com,stasrira@yahoo.com --from stas.rirak@mssm.edu --header "Subject: Custom Subject #7"  --attach-type text/html --attach "<b>html <i>body</i></b>" --server smtp.mssm.edu:25

--attach-type text/html --attach "<b>html <i>body</i></b>"