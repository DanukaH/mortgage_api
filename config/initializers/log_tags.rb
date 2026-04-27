# Tag every log line with the request ID, remote IP, and a timestamp.
# This lets us trace a single request through web → controller → job logs.
Rails.application.configure do
  config.log_tags = [ :request_id, :remote_ip ]
end
