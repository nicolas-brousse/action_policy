# frozen_string_literal: true

module ActionPolicy
  class VerificationTargetMissing < Error # :nodoc:
    MESSAGE_TEMPLATE = "Missing policy verification target: %s"

    attr_reader :message

    def initialize(id)
      @message = MESSAGE_TEMPLATE % id
    end
  end

  # Authorization context could include multiple parameters.
  #
  # It is possible to provide more verificatio contexts, by specifying them in the policy and
  # providing them at the authorization step.
  #
  # For example:
  #
  #   class ApplicationPolicy < ActionPolicy::Base
  #     # Add user and account to the context; it's required to be passed
  #     # to a policy constructor and be not nil
  #     verify :user, :account
  #
  #     # you can skip non-nil check if you want
  #     # verify :account, allow_nil: true
  #
  #     def manage?
  #       # available as a simple accessor
  #       account.enabled?
  #     end
  #   end
  #
  #   ApplicantPolicy.new(user: user, account: account)
  module Verification
    def self.included(base)
      base.extend ClassMethods
      base.attr_reader :verification_context
    end

    def initialize(params = {})
      @verification_context = {}

      self.class.verification_targets.each do |id, opts|
        raise VerificationTargetMissing, id unless params.key?(id)

        val = params.fetch(id)

        raise VerificationTargetMissing, id if val.nil? && opts[:allow_nil] != true

        verification_context[id] = instance_variable_set("@#{id}", val)
      end

      verification_context.freeze
    end

    module ClassMethods # :nodoc:
      def verify(*ids, **opts)
        ids.each do |id|
          verification_targets[id] = opts
        end

        attr_reader(*ids)
      end

      def verification_targets
        return @verification_targets if instance_variable_defined?(:@verification_targets)

        @verification_targets =
          if superclass.respond_to?(:verification_targets)
            superclass.verification_targets.dup
          else
            {}
          end
      end
    end
  end
end
