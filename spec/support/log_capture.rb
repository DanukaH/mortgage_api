module LogCapture
  # Captures Rails.logger output during the block and returns it as a string.
  def capture_logs
    original = Rails.logger
    io = StringIO.new
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = original
  end
end

RSpec.configure do |config|
  config.include LogCapture
end
