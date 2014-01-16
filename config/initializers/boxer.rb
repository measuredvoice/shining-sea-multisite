# Load all box definitions from lib/boxes/*.rb
Dir[File.join(Rails.root, 'lib', 'boxes', '**', '*.rb')].each do |f|
  require_dependency f
end
