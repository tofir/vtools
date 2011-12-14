# -*- encoding: binary -*-

module VTools

  # hooks
  # allows to execute hooks from external script
  # multiple hooks in one placeholder are allowed
  #
  # usage:
  #   Hook.set :placeholder_name, &block
  # or
  #   Hook.collection do
  #     set :placeholder_one, &block
  #     set :placeholder_other, &block
  #   end
  class Hook
    include SharedMethods

    @callbacks = {}

    class << self
      # hooks setter
      def set action, &block
        action = action.to_sym
        @callbacks[action] = [] unless @callbacks[action].is_a? Array
        @callbacks[action] << block if block_given?
      end

      # pending hooks exectuion
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
  end # Hook
end # VTools
