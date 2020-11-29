require "fileutils"
require "ostruct"

require_relative "mal_readline"

FILES = OpenStruct.new

$shutdown_done = false
$__debug = !true
$exit_status = 0

module TermColor
  RESET  = "\e[m"
  RED    = "\e[0;31m"
  BLUE   = "\e[0;34m"
end

def color_text(str, color)
  if ENV.key?("NO_COLOR")
    str
  else
    color + str + TermColor::RESET
  end
end

def print_e(*args)
  $stderr.print *args if $__debug
end

def puts_e(*args)
  $stderr.puts *args if $__debug
end

def file_path(path)
  File.join(__dir__, path)
end

def file_write(path, text)
  File.open(path, "wb") { |f| f.print text }
end

def file_rm(path)
  if File.exist? path
    FileUtils.rm path
  end
end

def file_clear(path)
  File.open(path, "w") { |f| f.print "" }
end

def file_wait(path, timeout_sec = 5)
  t0 = Time.now
  interval_sec = 0.01

  loop do
    sleep interval_sec
    interval_sec += 0.01

    break if File.exist?(path)

    unless timeout_sec.nil?
      if timeout_sec < Time.now - t0
        raise "timeout"
      end
    end
  end
end

def check_pid
  return unless $__debug

  print_e "pid file exists ... "
  if File.exist?(FILES.PID)
    pid = File.read(FILES.PID)
    puts_e "yes (#{pid}) (check_pid)"
    system "ps ax | grep #{pid}"
  else
    puts_e "no (check_pid)"
  end
end

def escape(str)
  str
    .gsub("&", "&amp;")
    .gsub("<", "&lt;")
    .gsub('"', "&quot;")
    .gsub("'", "&apos;")
end

def proc_throw(src)
  proc_type = nil
  proc_name = nil

  src.lines.map { |line|
    case line
    when /^function ([a-z0-9_]+)/i
      proc_type = "function"
      proc_name = $1
      line
    when /^sub ([a-z0-9_]+)/i
      proc_type = "sub"
      proc_name = $1
      line
    when /^ *' CHECK_MAL_ERROR$/
      retval_line = ""
      if proc_type == "function"
        retval_line = "#{proc_name} = null"
      end

      <<-SRC
                        ' --------------------------------
                        Utils.log0 "-->> CHECK_ERROR (in #{proc_name})"
                        ' Utils.logkv0 "112 type", type_name_ex(mal_error)
                        ' Utils.logkv0 "112 mal_error", mal_error
                        if mal_error_exists() then
                            Utils.log0 "... error exists"
                            #{retval_line}
                            Utils.log0 "exit #{proc_name}"
                            exit #{proc_type}
                        else
                            Utils.log0 "... ok"
                        end if
                        ' --------------------------------

      SRC
    when /^ *' ON_ERROR_TRY$/
      <<-SRC
                        ' --------------------------------
                            On Local Error GoTo error_handler__#{proc_name}
                        ' --------------------------------
      SRC
    when /^ *' ON_ERROR_CATCH$/
      <<-SRC
                        ' --------------------------------
                            exit #{proc_type}
                        error_handler__#{proc_name}:
                            panic format_err_msg("#{proc_name}", err, erl, error$)
                        ' --------------------------------
      SRC
    else
      line
    end
  }.join("")
end

def embed_src(template, key, src)
  parts = template.split(key)
  parts[0] + src + parts[1]
end

def embed_sample_mal(text, mal_code)
#      <text:p text:style-name="P1"><text:span text:style-name="T1">; __MAL_SRC__</text:span></text:p>
  lines = []
  text.each_line { |line|
    line.chomp!
    if /^(.+); __MAL_SRC__(.+)/ =~ line
      pre, post = $1, $2
      mal_code.each_line { |mal_line|
        lines << pre + escape(mal_line.chomp) + post
      }
    else
      lines << line
    end
  }

  lines.join("\n")
end

def render_fods(step)
  template = File.read("template_v5.fods")

  src_step =
    if ENV.key?("SRC_STEP")
      ENV["SRC_STEP"]
    else
      step
    end
  bas_file = Dir.glob("step#{src_step}_*.libo.bas").to_a[0]

  basic_src = escape(proc_throw(File.read(bas_file)))

  basic_src_utils          = escape(proc_throw(File.read("mod_utils.libo.bas"))    )
  basic_src_list           = escape(proc_throw(File.read("mod_list.libo.bas"))     )
  basic_src_vector         = escape(proc_throw(File.read("mod_vector.libo.bas"))   )
  basic_src_map            = escape(proc_throw(File.read("mod_map.libo.bas"))      )
  basic_src_env            = escape(proc_throw(File.read("mod_env.libo.bas"))      )
  basic_src_symbol         = escape(proc_throw(File.read("mod_symbol.libo.bas"))   )
  basic_src_reader         = escape(proc_throw(File.read("mod_reader.libo.bas"))   )
  basic_src_printer        = escape(proc_throw(File.read("mod_printer.libo.bas" )) )
  basic_src_core           = escape(proc_throw(File.read("mod_core.libo.bas"    )) )
  basic_src_function       = escape(proc_throw(File.read("mod_function.libo.bas")) )
  basic_src_named_function = escape(proc_throw(File.read("mod_named_function.libo.bas")) )
  basic_src_atom           = escape(proc_throw(File.read("mod_atom.libo.bas"))     )
  basic_src_calc           = escape(proc_throw(File.read("mod_calc.libo.bas"))     )
  mal_sample_code = File.read("sample.mal")

  template = embed_src(template, "rem __BASIC_SRC__"               , "\n" + basic_src)
  template = embed_src(template, "rem __BASIC_SRC_UTILS__"         , "\n" + basic_src_utils)
  template = embed_src(template, "rem __BASIC_SRC_LIST__"          , "\n" + basic_src_list)
  template = embed_src(template, "rem __BASIC_SRC_VECTOR__"        , "\n" + basic_src_vector)
  template = embed_src(template, "rem __BASIC_SRC_MAP__"           , "\n" + basic_src_map)
  template = embed_src(template, "rem __BASIC_SRC_ENV__"           , "\n" + basic_src_env)
  template = embed_src(template, "rem __BASIC_SRC_SYMBOL__"        , "\n" + basic_src_symbol)
  template = embed_src(template, "rem __BASIC_SRC_READER__"        , "\n" + basic_src_reader)
  template = embed_src(template, "rem __BASIC_SRC_PRINTER__"       , "\n" + basic_src_printer)
  template = embed_src(template, "rem __BASIC_SRC_CORE__"          , "\n" + basic_src_core)
  template = embed_src(template, "rem __BASIC_SRC_FUNCTION__"      , "\n" + basic_src_function)
  template = embed_src(template, "rem __BASIC_SRC_NAMED_FUNCTION__", "\n" + basic_src_named_function)
  template = embed_src(template, "rem __BASIC_SRC_ATOM__"          , "\n" + basic_src_atom)
  template = embed_src(template, "rem __BASIC_SRC_CALC__"          , "\n" + basic_src_calc)
  template = embed_sample_mal(template, mal_sample_code)

  File.open("z_000.fods", "wb"){ |f|
    f.print template
  }
end

def libo_up
  file_rm FILES.PID

  opts = ""
  opts << " --headless" if ENV["LIBO_HEADLESS"] == "1"
  opts << " --norestore"
  opts << " --nologo"
  # opts << " --minimized"
  opts << " --nofirststartwizard"
  opts << " --nolockcheck"
  opts << " --pidfile=#{ FILES.PID }"

  cmd = %(libreoffice #{opts} z_000.fods macro://z_000/mylib.main.Main &)

  system cmd
end

def process_alive?
  libo_pid = File.read(FILES.PID).strip
  out = `ps -e`
  
  out.each_line { |line|
    /^ *(\d+) / =~ line
    pid = $1
    if pid == libo_pid
      return true
    end
  }

  false
end

def print_output
  return unless File.exist?(FILES.OUT)

  File.read(FILES.OUT).each_line { |line|
    line.chomp!
    case line
    when /^$/
      # skip
    when /^OUT (.*)/
      msg = $1
      print msg
      print "\n"
    when /^ERR (.*)/
      msg = $1
      unless msg.empty?
        $stderr.print color_text($1, TermColor::RED)
        print "\n"
      end
    else
      $stderr.print "?(#{ line.inspect })"
      print "\n"
    end
  }

  file_rm FILES.OUT
end

def write_msg_to_libo(msg)
  file_in_temp = FILES.IN + ".temp"
  file_write(file_in_temp, msg)
  FileUtils.mv file_in_temp, FILES.IN
end

def wait_command(cmd)
  loop do
    file_wait FILES.DONE, 60 * 60

    done_content = File.read(FILES.DONE)
    file_rm FILES.DONE
    if /^SETUP_DONE/ =~ done_content
      break
    end
  end

  print_output()

  file_rm FILES.IN

  write_msg_to_libo ""
end

# --pidfile で指定したファイルは、libo が正常終了した場合自動で削除される
def shutdown(args_p: false)
  puts_e ""
  puts_e "-->> shutdown"
  check_pid

  if $shutdown_done
    # 2度以上実行しない
    return
  end

  puts_e "kill"

  if File.exist?(FILES.PID)
    puts_e "pid file exists ... yes"

    if process_alive?()
      puts_e "prcess alive ... yes"

      if File.exist?(FILES.PID)
        pid = File.read(FILES.PID).strip
        puts_e "pid (#{pid})"
        raise unless /^\d+$/ =~ pid
        system %(kill #{pid} && rm #{FILES.PID})
      end
    else
      puts_e "process alive ... no"
    end

    file_rm FILES.PID
  else
    puts_e "pid file exists ... no (shutdown)"
  end

  puts_e "-->> shutdown > done"
  $shutdown_done = true
end

# TODO write_msg_to_libo と一本化
def respond_to_libo(msg)
  write_msg_to_libo msg
end

def main_argv_mode
  File.open(FILES.ARGS, "wb") { |f|
    f.puts ARGV.size
    ARGV.each { |arg| f.puts arg }
  }

  file_rm FILES.DONE

  # libo 起動
  libo_up
  wait_command "SETUP_DONE"

  # libo からの命令を待ち受け
  loop do
    file_wait FILES.DONE, 60 * 60
    cmd_from_libo = File.read(FILES.DONE)
    file_rm FILES.DONE

    print_output()

    if /^ERROR/ =~ cmd_from_libo
      $stderr.puts cmd_from_libo
      exit 1

    elsif /^READLINE (.+)/ =~ cmd_from_libo
      prompt = $1
      puts_e "357 _readline"
      line = _readline(prompt)
      respond_to_libo(line)

    elsif /^PRINT_OUTPUT$/ =~ cmd_from_libo
      # 出力は上の print_output で済んでいる
      respond_to_libo("print output done")

    elsif /^EXIT (\d+)/ =~ cmd_from_libo
      $exit_status = $1.to_i
      break
    else
      $stderr.puts "ERROR: unexpected command: " + cmd_from_libo.inspect
    end
  end
end

def main
  file_rm FILES.DONE

  # libo 起動
  libo_up
  wait_command "SETUP_DONE"

  # libo からの命令を待ち受け
  loop do
    file_wait FILES.DONE, nil
    cmd_from_libo = File.read(FILES.DONE)
    file_rm FILES.DONE

    print_output()

    if /^ERROR/ =~ cmd_from_libo
      $stderr.puts cmd_from_libo # TODO たぶん不要
      exit 1

    elsif /^READLINE (.+)/ =~ cmd_from_libo
      prompt = $1
      puts_e "396 _readline"
      line = _readline(prompt)
      if line.nil?
        puts "exit"
        respond_to_libo("exit")
      else
        respond_to_libo(line)
      end

    elsif /^PRINT_OUTPUT$/ =~ cmd_from_libo
      # 出力は上の print_output で済んでいる
      respond_to_libo("print output done")

    elsif /^EXIT (\d+)/ =~ cmd_from_libo
      puts_e "409 exit"
      $exit_status = $1.to_i
      break

    else
      $stderr.puts "ERROR: unexpected command: " + cmd_from_libo.inspect
    end
  end
end

# --------------------------------

def setup
  FILES.IN  = file_path("z_in.txt")
  FILES.OUT = file_path("z_out.txt")
  FILES.LOG = file_path("z_log.txt")
  FILES.LOG_SETUP = file_path("z_log_setup.txt")
  FILES.PID = file_path("z_pid.txt")
  FILES.ERR = file_path("z_err.txt")
  FILES.DONE = file_path("z_done.txt")
  FILES.ARGS = file_path("z_args.txt")

  ENV["FILE_IN" ] = FILES.IN
  ENV["FILE_OUT"] = FILES.OUT
  ENV["FILE_LOG"] = FILES.LOG
  ENV["FILE_LOG_SETUP"] = FILES.LOG_SETUP
  ENV["FILE_ERR"] = FILES.ERR
  ENV["FILE_DONE"] = FILES.DONE
  ENV["FILE_ARGS"] = FILES.ARGS
  ENV["AUTO_CLOSE"] = "1"
end

def start_repl(step)
  setup()

  Signal.trap(:INT) do
    puts_e ""
    puts_e "---->> trap SIGINT"
    # C-c で止めた場合はここですでに libo も終了しているが
    # pifile は残った状態になる
    check_pid
    # file_rm FILES.PID
    puts_e "----"
    shutdown
    puts_e "<<---- trap SIGINT"
    exit
  end

  begin
    file_rm FILES.IN
    file_rm FILES.DONE

    file_clear FILES.OUT
    file_clear FILES.LOG
    file_clear FILES.LOG_SETUP

    render_fods step

    file_rm FILES.ARGS

    if 0 < ARGV.size
      puts_e "argv mode"
      main_argv_mode()

      shutdown(args_p: true)
    else
      main
    end

  rescue => e
    p e.class, e.message, e.backtrace
  ensure
    puts_e "---->> ensure"
    check_pid
    # libo 停止

    shutdown
    puts_e "<<---- ensure"

    exit $exit_status
  end
end

if $0 == __FILE__
  cmd = ARGV.shift
  case cmd
  when "render"
    render_fods ARGV[0]
  else
    $stderr.puts "invalid command"
    exit 1
  end
end
