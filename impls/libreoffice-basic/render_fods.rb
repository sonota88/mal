require_relative "libo_v2"

if ARGV.size < 1
  raise "ARGV[0] must be the step"
end

render_fods ARGV[0]
