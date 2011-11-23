# -*- encoding: binary -*-

module VTools

  # Interface API to the Message Queue or Database Server (AdapterInterface)
  class Storage
    include SharedMethods

    @actions = {}

    class << self

      # constructor (cretes connection)
      def connect
        fails __method__ unless @actions[:connect]
        @actions[:connect].call
      end

      # recv basic method
      def recv
        fails __method__ unless @actions[:recv]
        @actions[:recv].call
      end

      # send masic method
      def send data
        fails __method__ unless @actions[:send]
        @actions[:send].call(data)
      end

      # callback setter to connect to the storage
      def connect_action &block
        @actions[:connect] = block
      end

      # callback setter to recieve data
      def recv_action &block
        @actions[:recv] = block
      end

      # callback setter to send data when done successfully
      # Storage#send will pass Hash with content:
      #     :data   => Job.execution_result,
      #     :action => Job.executed_action
      def send_action &block
        @actions[:send] = block
      end

      # callback setter for the collection
      # usage:
      # VTools::Storage.setup do
      #   connect_action { ... }
      #   send_action { |data| ... }
      #   recv_action { ... }
      def setup &block
        instance_eval &block if block_given?
      end

      private
      # errors generator
      def fails meth
p "fails orig: #{meth}"
        raise NotImplementedError, "VTools::Storage##{meth}_action must be set"
      end
    end # class << self
  end # Storage
end # VTools
