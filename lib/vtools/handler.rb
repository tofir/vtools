# -*- encoding: binary -*-

module VTools

  # callback handler
  # allows to execute external script callbacks
  # multiple callbacs in one placeholder are allowed
  #
  # usage:
  #   Handler.set :placeholder_name, &block
  # or
  #   Handler.collection do
  #     set :placeholder_one, &block
  #     set :placeholder_other, &block
  #   end
  class Handler
    include SharedMethods

    @callbacks = {}

    class << self
      # callbacks setter
      def set action, &block
        action = action.to_sym
        @callbacks[action] = [] unless @callbacks[action].is_a? Array
        @callbacks[action] << block if block_given?
      end

      # pending callbacks exectuion
      def exec action, *args
        action = action.to_sym
        @callbacks[action].each do |block|
          block.call(*args)
        end if @callbacks[action].is_a? Array
      end

      # collection setup
      def collection &block
        instance_eval &block if block_given?
      end
    end # << self
  end # Handler
end # VTools
