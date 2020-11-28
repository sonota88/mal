require "readline"

$history_loaded = false
# $histfile = "#{ENV['HOME']}/.mal-history"
$histfile = File.join(__dir__, ".mal-history")

$prev_line = nil

def _readline(prompt)
    if !$history_loaded && File.exist?($histfile)
        $history_loaded = true
        if File.readable?($histfile)
            File.readlines($histfile).each { |l| Readline::HISTORY.push(l.chomp) }
        end
    end

    if line = Readline.readline(prompt, true)
        if File.writable?($histfile) && line != $prev_line
            File.open($histfile, 'a+') { |f| f.write(line + "\n") }
        end
        $prev_line = line
        return line
    else
        return nil
    end
end
