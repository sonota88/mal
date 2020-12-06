require "fileutils"
require "ostruct"

require_relative "mal_readline"

FILES_DIR = "z_files"
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

def file_read(path)
  File.open(path, "rb:utf-8") { |f| f.read }
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

def file_wait_deletion(path, timeout_sec = 5)
  t0 = Time.now
  interval_sec = 0.01

  loop do
    sleep interval_sec
    interval_sec += 0.01

    break unless File.exist?(path)

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
    puts_e "yes (#{pid})"
    system "ps ax | grep #{pid}"
  else
    puts_e "no"
  end
end

def escape(str)
  str
    .gsub("&", "&amp;")
    .gsub("<", "&lt;")
    .gsub(">", "&gt;")
    .gsub('"', "&quot;")
    .gsub("'", "&apos;")
end

def preprocess(src)
  proc_type = nil
  proc_name = nil

  src.lines
    .map do |line|
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
                        ' Utils.log0 "-->> CHECK_ERROR (in #{proc_name})"
                        If mal_error_exists() Then
                            Utils.log0 "... error exists"
                            #{retval_line}
                            Utils.log0 "exit #{proc_name}"
                            Exit #{proc_type}
                        Else
                            Utils.log0 "... ok"
                        End If
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
                            Exit #{proc_type}
                        error_handler__#{proc_name}:
                            panic format_err_msg("#{proc_name}", err, erl, error$)
                        ' --------------------------------
        SRC
      else
        line
      end
    end
    .join("")
end

def embed_src(template, key, src_path)
  src = escape(preprocess(file_read(src_path)))
  parts = template.split(key)
  parts[0] + "\n" + src + parts[1]
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
  template = file_read("template.fods")

  src_step =
    if ENV.key?("SRC_STEP")
      ENV["SRC_STEP"]
    else
      step
    end
  bas_file = Dir.glob("step#{src_step}_*.libo.bas").to_a[0]
  template = embed_src(template, "rem __BASIC_SRC__", bas_file)

  template = embed_src(template, "rem __BASIC_SRC_UTILS__"         , "mod_utils.libo.bas"         )
  template = embed_src(template, "rem __BASIC_SRC_LIST__"          , "mod_list.libo.bas"          )
  template = embed_src(template, "rem __BASIC_SRC_VECTOR__"        , "mod_vector.libo.bas"        )
  template = embed_src(template, "rem __BASIC_SRC_MAP__"           , "mod_map.libo.bas"           )
  template = embed_src(template, "rem __BASIC_SRC_ENV__"           , "mod_env.libo.bas"           )
  template = embed_src(template, "rem __BASIC_SRC_SYMBOL__"        , "mod_symbol.libo.bas"        )
  template = embed_src(template, "rem __BASIC_SRC_READER__"        , "mod_reader.libo.bas"        )
  template = embed_src(template, "rem __BASIC_SRC_PRINTER__"       , "mod_printer.libo.bas"       )
  template = embed_src(template, "rem __BASIC_SRC_CORE__"          , "mod_core.libo.bas"          )
  template = embed_src(template, "rem __BASIC_SRC_FUNCTION__"      , "mod_function.libo.bas"      )
  template = embed_src(template, "rem __BASIC_SRC_NAMED_FUNCTION__", "mod_named_function.libo.bas")
  template = embed_src(template, "rem __BASIC_SRC_ATOM__"          , "mod_atom.libo.bas"          )
  template = embed_src(template, "rem __BASIC_SRC_CALC__"          , "mod_calc.libo.bas"          )

  mal_sample_code = file_read("sample.mal")
  template = embed_sample_mal(template, mal_sample_code)

  File.open(file_path("#{FILES_DIR}/temp.fods"), "wb"){ |f|
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

  fods_path = file_path("#{FILES_DIR}/temp.fods")

  macro_url = "vnd.sun.star.script:mylib.main.Main?language=Basic&location=document"
  cmd = %(libreoffice #{opts} "#{fods_path}" "#{macro_url}" &)

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

  # wait ack
  file_wait_deletion FILES.IN
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

def main_argv_mode(args)
  File.open(FILES.ARGS, "wb") { |f|
    f.puts ARGV.size
    args.each { |arg| f.puts arg }
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
      line = _readline(prompt)
      write_msg_to_libo(line)

    elsif /^PRINT$/ =~ cmd_from_libo
      # 出力は上の print_output で済んでいる
      write_msg_to_libo("print output done")

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
      line = _readline(prompt)
      if line.nil?
        puts "exit"
        write_msg_to_libo("exit")
      else
        write_msg_to_libo(line)
      end

    elsif /^PRINT$/ =~ cmd_from_libo
      # 出力は上の print_output で済んでいる
      write_msg_to_libo("print output done")

    elsif /^EXIT (\d+)/ =~ cmd_from_libo
      $exit_status = $1.to_i
      break

    else
      $stderr.puts "ERROR: unexpected command: " + cmd_from_libo.inspect
    end
  end
end

# --------------------------------

def setup
  FileUtils.mkdir_p FILES_DIR

  FILES.IN        = file_path("#{FILES_DIR}/in.txt")
  FILES.OUT       = file_path("#{FILES_DIR}/out.txt")
  FILES.LOG       = file_path("#{FILES_DIR}/log.txt")
  FILES.LOG_SETUP = file_path("#{FILES_DIR}/log_setup.txt")
  FILES.PID       = file_path("#{FILES_DIR}/pid.txt")
  FILES.ERR       = file_path("#{FILES_DIR}/err.txt")
  FILES.DONE      = file_path("#{FILES_DIR}/done.txt")
  FILES.ARGS      = file_path("#{FILES_DIR}/args.txt")

  ENV["FILE_IN" ]       = FILES.IN
  ENV["FILE_OUT"]       = FILES.OUT
  ENV["FILE_LOG"]       = FILES.LOG
  ENV["FILE_LOG_SETUP"] = FILES.LOG_SETUP
  ENV["FILE_ERR"]       = FILES.ERR
  ENV["FILE_DONE"]      = FILES.DONE
  ENV["FILE_ARGS"]      = FILES.ARGS
  ENV["AUTO_CLOSE"]     = "1"
end

def start_repl(step, args)
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

    if 0 < args.size
      puts_e "argv mode"
      main_argv_mode(ARGV)

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
  when "step"
    arg_step = ARGV.shift
    /^step(.)/ =~ arg_step
    step = $1
    start_repl(step, ARGV)
  when "render"
    render_fods ARGV[0]
  else
    $stderr.puts "invalid command"
    exit 1
  end
end
