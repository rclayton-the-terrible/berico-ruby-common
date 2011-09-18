module Berico

  # Enable the use of properties on a class
  # that are not explicitly defined within
  # the class.  These properties exist as a
  # hash on the object, which can be accessed
  # via the instance property "properties" or
  # by calling the property's name (key) on
  # the object.  Properties can also be
  # dynamically set and added to the hash by
  # invoking the "{property_name}=" method.
  module DynamicProperties

    attr_reader :properties, :configured

    # Called on the first method_missing invocation.
    # Configure the mixin using configuration
    # properties from the class including the mixin,
    # or use default configuration if those properties
    # are missing.
    # @param configuration [Object] (optional) config hash
    def configure(configuration = {})
      # Initialize the Property Bag
      @properties = {}

      # default configuration
      @_configuration = {}

      # has the config been checked?
      # since we rely on state from an initialized
      # object or class, and can't guarantee that
      # the info has been applied before including
      # this module, we need to lazy-load the functionality
      # on the first missing_method call.
      # This is the flag that will tell us whether
      # that was performed.
      @configured = true

      # Merge existing properties if the configuration
      # hash has a :properties key
      if configuration.has_key? :properties
        configuration[:properties].each do |k, value|
          key = (k.instance_of? Symbol)? k.to_s : k
          @properties.store(key, value)
        end
      end

      # If the class we are mixing
      # has supplied configuration
      # details for the mixin
      unless configuration == {}
        configuration = {} unless self.config_valid?(configuration)
      end
      # Create a parser for the property name
      @name_parser = create_name_parser(configuration)
      true
    end

    # Create a lambda that will parse the correct
    # property name based on the supplied naming strategy
    # (found in the config hash).
    # @param config [Hash] configuration of the property parser;
    #  options include a prefix, suffix, regex (or identity)
    # @return [Lambda] property name parser (default is identity)
    def create_name_parser(config)
      # Regex Matcher
      return lambda do |method_name|
          return $1 if method_name =~ config[:matcher]
        end if config.has_key? :matcher
      # Prefix Parser
      return lambda do |method_name|
          return method_name.sub(config[:prefix], "") if method_name.start_with? config[:prefix]
        end if config.has_key? :prefix
      # Suffix Parser
      return lambda do |method_name|
          return method_name.chomp(config[:suffix]) if method_name.end_with? config[:suffix]
        end if config.has_key? :suffix
      # Identity Parser
      lambda { |method_name| return method_name }
    end

    # Is the supplied configuration valid
    # for the DynamicProperties mixin?
    # @param config [Hash] Hash of config properties
    def config_valid?(config)
      valid_for_key? config, :prefix, String or
          valid_for_key? config, :suffix, String or
          valid_for_key? config, :matcher, Regexp
    end

    # Is the configuration valid for the given key
    # @param config_hash [Hash] Configuration
    # @param key [String or Symbol] Key to look up
    # @param class_type [Class] class the value should be
    # @return [TrueClass or FalseClass] whether the key is valid
    def valid_for_key?(config_hash, key, class_type)
      # Hash has the key
      if config_hash.has_key? key
        # Value is the right type
        config_hash[key].instance_of? class_type
      end
    end

    # Here's the magic! Every time a method
    # goes missing, we will test the method name
    # to see if it matches our requirements.
    # If the requirements are a match,
    def method_missing(name, *args)
      if not @configured
        @configured = configure
      end
      # By default, we are getting properties
      mode = :getter
      # if the method name is a symbol,
      # convert it to a string,
      # otherwise, clone the name string
      # (we're going to modify it)
      method = (name.instance_of? Symbol) ? name.to_s : name.clone
      # If this is a setter
      if method.end_with? "="
        # remove the "=" sign
        method.chomp! "="
        # change the mode to set
        mode = :setter
      end
      # get the property name
      property_name = @name_parser.call(method)
      # if the property name is null, call the
      # base object's method_missing
      if property_name.nil?
        super
      else
        # if we are dealing with a getter
        if mode == :getter
          if @properties.has_key? property_name
            return @properties[property_name]
          else
            super
          end
        # else, this is a setter!
        else
          # create the property
          @properties[property_name] = args[0]
        end
      end
    end

  end
end