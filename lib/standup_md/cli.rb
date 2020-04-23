require 'json'
require 'yaml'
require 'optparse'
require_relative '../standup_md'

class StandupMD
  ##
  # Class for handing the command-line interface.
  class CLI

    ##
    # The user's preference file.
    PREFERENCE_FILE =
      File.expand_path(File.join(ENV['HOME'], '.standup_md.yml')).freeze

    ##
    # Creates an instance of +StandupMD+ and runs what the user requested.
    def self.execute(options = [])
      exe = new(options)
      exe.append_to_previous_entry_tasks if exe.should_append?

      exe.print_current_entry if exe.print_current_entry?
      exe.print_all_entries   if exe.print_all_entries?
      exe.write_file          if exe.write?
      exe.edit                if exe.edit?
    end

    ##
    # Arguments passed at runtime.
    #
    # @return [Array] ARGV
    attr_reader :options

    ##
    # Preferences after reading config file and parsing ARGV.
    #
    # @return [Array] ARGV
    attr_reader :preferences

    ##
    # Constructor. Sets defaults.
    #
    # @param [Array] options
    def initialize(options)
      @options             = options
      @print_current_entry = false
      @json                = false
      @print_all_entries   = false
      @verbose             = false
      @write               = true
      @edit                = true
      @append_previous     = true
      @preferences         = get_preferences
    end

    ##
    # Sets up an instance of +StandupMD+ and passes all user preferences.
    #
    # @return [StandupMD]
    def standup
      @standup ||= ::StandupMD.new do |s|
        echo "Runtime options:"
        preferences.each do |k, v|
          if s.respond_to?(k)
            echo "  #{k} = #{v}"
            s.send("#{k}=", v)
          else
            puts "Method `Standup##{k}=` does not exist"
          end
        end
      end.load
    end

    ##
    # Tries to determine the editor, first by checking if the user has one set
    # in their preferences. If not, the +VISUAL+ and +EDITOR+ environmental
    # variables are checked. If none of the above are set, defaults to +vim+.
    #
    # @return [String] The editor
    def editor
      @editor ||=
        if preferences.key?('editor')
          preferences.delete('editor')
        elsif ENV['VISUAL']
          ENV['VISUAL']
        elsif ENV['EDITOR']
          ENV['EDITOR']
        else
          'vim'
        end
    end

    ##
    # Prints all entries to the command line.
    #
    # @return [nil]
    def print_all_entries
      echo "Display all entries"
      if json?
        echo '  ...as json'
        puts standup.all_entries.to_json
        return
      end
      standup.all_entries.each do |head, s_heads|
        puts '#' * standup.header_depth + ' ' + head
        s_heads.each do |s_head, tasks|
          puts '#' * standup.sub_header_depth + ' ' + s_head
          tasks.each { |task| puts standup.bullet_character + ' ' + task }
        end
        puts
      end
    end

    ##
    # Prints the current entry to the command line.
    #
    # @return [nil]
    def print_current_entry
      echo "Print current entry"
      echo '  ...as json' if json?
      entry = standup.current_entry
      puts json? ? entry.to_json : entry
    end

    ##
    # Appends entries passed at runtime to existing previous entries.
    #
    # @return [Hash]
    def append_to_previous_entry_tasks
      echo 'Appending previous entry tasks'
      additions = preferences.delete('previous_entry_tasks')
      standup.previous_entry_tasks.concat(additions)
    end

    ##
    # Opens the file in an editor. Abandons the script.
    def edit
      echo "  Opening file in #{editor}"
      exec("#{editor} #{standup.file}")
    end

    ##
    # Writes entries to the file.
    #
    # @return [Boolean] true if file was written
    def write_file
      echo '  Writing file'
      standup.write
    end

    ##
    # Should current entry be printed? If true, disables editing.
    #
    # @return [Boolean] Default is false
    def print_current_entry?
      @print_current_entry
    end

    ##
    # If printing an entry, should it be printed as json?
    #
    # @return [Boolean] Default is false
    def json?
      @json
    end

    ##
    # Should all entries be printed? If true, disables editing.
    #
    # @return [Boolean] Default is false
    def print_all_entries?
      @print_all_entries
    end

    ##
    # Should debug info be printed?
    #
    # @return [Boolean] Default is false
    def verbose?
      @verbose
    end

    ##
    # Should the file be written?
    #
    # @return [Boolean] Default is true
    def write?
      @write
    end

    ##
    # Should the standup file be opened in the editor?
    #
    # @return [Boolean] Default is true
    def edit?
      @edit
    end

    ##
    # Should `previous_entry_tasks` be appended? If false,
    # +previous_entry_tasks+ will be overwritten.
    #
    # @return [Boolean] Default is true
    def append_previous?
      @append_previous
    end

    ##
    # Did the user pass +previous_entry_tasks+, and should we append?
    #
    # @return [Boolean]
    def should_append?
      preferences.key?('previous_entry_tasks') && append_previous?
    end

    ##
    # Prints output if +verbose+ is true.
    #
    # @return [nil]
    def echo(msg)
      puts msg if verbose?
    end

    private

    ##
    # Parses options passed at runtime and concatenates them with the options in
    # the user's preferences file. Reveal source to see options.
    #
    # @return [Hash]
    def get_preferences
      prefs = {}

      OptionParser.new do |opts|
        opts.banner = 'The Standup Doctor'
        opts.version = ::StandupMD::VERSION
        opts.on('--current-entry-tasks=ARRAY', Array, "List of current entry's tasks") do |v|
          prefs['current_entry_tasks'] = v
        end
        opts.on('--previous-entry-tasks=ARRAY', Array, "List of yesterday's tasks") do |v|
          prefs['previous_entry_tasks'] = v
        end
        opts.on('--impediments=ARRAY', Array, 'List of impediments for current entry') do |v|
          prefs['impediments'] = v
        end
        opts.on('--notes=ARRAY', Array, 'List of notes for current entry') do |v|
          prefs['notes'] = v
        end
        opts.on('--sub-header-order=ARRAY', Array, 'The order of the sub-headers when writing the file') do |v|
          prefs['sub_header_order'] = v
        end
        opts.on('--[no-]append-previous', 'Append previous tasks? Default is true') do |v|
          @append_previous = v
        end
        opts.on('-f', '--file-name-format=STRING', 'Date-formattable string to use for standup file name') do |v|
          prefs['file_name_format'] = v
        end
        opts.on('-e', '--editor=EDITOR', 'Editor to use for opening standup files') do |v|
          prefs['editor'] = v
        end
        opts.on('-d', '--directory=DIRECTORY', 'The directories where standup files are located') do |v|
          prefs['directory'] = v
        end
        opts.on('--[no-]write', "Write current entry if it doesn't exist. Default is true") do |v|
          @write = v
        end
        opts.on('--[no-]edit', 'Open the file in the editor. Default is true') do |v|
          @edit = v
        end
        opts.on('-j', '--[no-]json', 'Print output as formatted json. Default is false.') do |v|
          @json = v
        end
        opts.on('-v', '--[no-]verbose', 'Verbose output. Default is false.') do |v|
          @verbose = v
        end
        opts.on('-c', '--current', "Print current entry. Disables editing") do |v|
          @print_current_entry = v
          @edit = false
        end
        opts.on('-a', '--all', "Print all previous entries. Disables editing") do |v|
          @print_all_entries = v
          @edit = false
        end
      end.parse!(options)

      (File.file?(PREFERENCE_FILE) ? YAML.load_file(PREFERENCE_FILE) : {}).merge(prefs)
    end
  end
end
