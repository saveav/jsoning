class Jsoning::ForDsl
  attr_reader :protocol
  attr_accessor :current_version_object
  @@mutex = Mutex.new

  def initialize(protocol)
    @protocol = protocol
  end

  # inherits can happen inside version block
  # it allows version to inherit specific key from parents
  def inherits(*args)
    fail 'Must be inside version block' unless current_version_object
    all_keys = []
    options = {}

    args.each do |arg|
      if arg.is_a?(String) || arg.is_a?(Symbol)
        all_keys << arg
      elsif arg.is_a?(Hash)
        options = arg
      end
    end

    current_version = self.current_version_object
    if options[:from] || options['from']
      parent_version = current_version.protocol.get_version(options[:from] || options['from'])
    else
      parent_version = current_version.protocol.get_version(:default)
    end

    all_keys.each do |key_name|
      mapper = parent_version.mapper_for(key_name)
      current_version.add_mapper(mapper)
    end
    all_keys
  end

  # specify the version under which key will be executed
  def version(version_name)
    @@mutex.synchronize do
      # todo: make sure version cannot be nester, in order that to be possible
      # version must have its own dsl, dduh
      # fail Jsoning::Error, "Version cannot be nested" if current_version_object

      # retrieve the version, or create a new one if not yet defined
      version = protocol.get_version(version_name)
      version = protocol.add_version(version_name) if version.nil?

      self.current_version_object = version
      yield
      self.current_version_object = nil
    end
  end

  # args is first specifying the name for variable to be displayed in JSON docs,
  # and then the options. options are optional, if set, it can contains:
  # - from
  # - null
  # - default
  def key *args
    mapped_to = nil
    mapped_from = nil
    options = {}

    # iterate the args given, it contains a string/symbol indicating the key name
    # and options, that specify further about the behaviour/mechanism of the key
    args.each do |arg|
      if arg.is_a?(String) || arg.is_a?(Symbol)
        mapped_to = arg
      elsif arg.is_a?(Hash)
        # extract the options if given
        options = arg
      end
    end

    # get the version instance
    version_instance = if self.current_version_object.nil?
      protocol.get_version!(:default)
    else
      current_version_object
    end 

    mapper = Jsoning::Mapper.new(version_instance)
    if block_given?
      raise Jsoning::Error, "Cannot parse block to key"
    else
      mapped_from = options.delete(:from) || options.delete("from") || mapped_to
      mapper.parallel_variable = mapped_from
    end

    mapper.name = mapped_to
    mapper.default_value = options.delete(:default) || options.delete("default")
    mapper.nullable = options.delete(:null)
    mapper.nullable = options.delete("null") if mapper.nullable?.nil?

    # if value is given, it has a value processor to be executed
    # after value is determined
    if options[:value] || options['value']
      mapper.value_processor = options.delete(:value) || options.delete('value')
    end

    options.keys.each { |key| raise Jsoning::Error, "Undefined option: #{key}" }

    # add mapper to the version
    version_instance.add_mapper(mapper)
  end
end
