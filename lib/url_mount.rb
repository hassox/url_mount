class UrlMount
  # Inspiration for this is taken straight from Usher.  http://github.com/joshbuddy/usher
  DELIMETERS = ['/', '(', ')']

  attr_accessor :raw_path, :options
  def initialize(path, opts = {})
    @raw_path, @options = path, opts
    @url_split_regex = Regexp.new("[^#{DELIMETERS.collect{|d| Regexp.quote(d)}.join}]+|[#{DELIMETERS.collect{|d| Regexp.quote(d)}.join}]")
  end

  def local_segments
    @local_segments || parse_local_segments
  end

  def required_variables
    @required_variables ||= begin
      local_segments.map{|s| s.required_variable_segments}.flatten.map{|s| s.name }.compact
    end
  end

  def optional_variables
    @optional_variables ||= begin
      local_segments.map{|s| s.optional_variable_segments}.flatten.map{|s| s.name }.compact
    end
  end

  def variables
    {
      :required => required_variables,
      :optional => optional_variables
    }
  end

  def to_s(opts = {})
    raise "Missing required variables" if (opts.keys & required_variables) != required_variables
    File.join(local_segments.inject([]){|url, segment| url << segment.to_s(opts)}) =~ /(.*?)\/?$/
    $1
  end

  private
  def parse_local_segments
    stack = []
    @local_segments = []
    raw_path.scan(@url_split_regex).each do |segment|
      case segment
      when '/'
        if stack.empty?
          @local_segments << Segment::Delimeter.new
        else
          stack.last.segments << Segment::Delimeter.new
        end
      when '('
        stack << Segment::Conditional.new(options)
      when ')'
        conditional = stack.pop
        if !stack.empty?
          stack.last.segments << conditional
        else
          @local_segments << conditional
        end
      when /^\:(.*)/
        if stack.empty?
          @local_segments << Segment::Variable.new($1, true, options)
        else
          stack.last.segments << Segment::Variable.new($1, false, options)
        end
      else
        seg = Segment::Static.new(segment)
        if stack.empty?
          @local_segments << seg
        else
          stack.last.segments << seg
        end
      end
    end
    @local_segments
  end

  class Segment

    class Base
      attr_accessor :name

      def required!; @required = true; end
      def required?; !!@required; end

      def optional_variable_segments; []; end
      def required_variable_segments; []; end
    end

    class Delimeter < Base
      def to_s(opts = {}); "/"; end
    end

    class Static < Base
      def initialize(name); @name = name; end
      def to_s(opts = {}); @name; end
    end

    class Variable < Base
      def initialize(name, required, options)
        @name, @required = name.to_sym, true
      end

      def optional_variable_segments
        []
      end

      def required_variable_segments
        [self]
      end

      def to_s(opts = {})
        opts[name]
      end
    end

    class Conditional < Base
      attr_reader :segments
      def initialize(options)
        @options, @segments, @required = options, [], false
      end

      def optional_variable_segments
        @segments.inject([]) do |coll, segment|
          case segment
          when Variable
            coll << segment
          when Conditional
            coll << segment.optional_variable_segments
          end
          coll
        end
      end

      def required_variable_segments; []; end

      def to_s(opts={})
        File.join(@segments.map{|s| s.to_s(opts)}.flatten.compact)
      end
    end

  end
end
