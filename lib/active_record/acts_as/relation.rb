
module ActiveRecord
  module ActsAs
    module Relation
      extend ActiveSupport::Concern

      module ClassMethods
        def acts_as(name, scope = nil, options = {})
          options, scope = scope, nil if Hash === scope
          options = {as: :actable, dependent: :destroy, validate: false, autosave: true}.merge options

          cattr_reader(:validates_actable) { options.delete(:validates_actable) == false ? false : true }

          reflections = has_one name, scope, options
          default_scope -> { eager_load(name) }
          validate :actable_must_be_valid

          cattr_reader(:acting_as_reflection) { reflections.stringify_keys[name.to_s] }
          cattr_reader(:acting_as_name) { name.to_s }
          cattr_reader(:acting_as_model) { (options[:class_name] || name.to_s.camelize).constantize }
          class_eval "def acting_as() #{name} || build_#{name} end"
          alias_method :acting_as=, "#{name}=".to_sym

          after_initialize :acting_as

          include ActsAs::InstanceMethods
        end

        def acting_as?(other = nil)
          if respond_to?(:acting_as_reflection) &&
              acting_as_reflection.is_a?(ActiveRecord::Reflection::AssociationReflection)
            case other
            when Class
              acting_as_reflection.class_name == other.to_s
            when Symbol, String
              acting_as_reflection.class_name.underscore == other.to_s
            when NilClass
              true
            end
          else
            false
          end
        end

        def is_a?(klass)
          super || acting_as?(klass)
        end

        def actable(options = {})
          name = options.delete(:as) || :actable

          reflections = belongs_to name, {polymorphic: true, dependent: :delete, autosave: true}.merge(options)

          cattr_reader(:actable_reflection) { reflections.stringify_keys[name.to_s] }

          alias_method :specific, name
        end

        def actable?
          respond_to?(:actable_reflection) &&
            actable_reflection.is_a?(ActiveRecord::Reflection::AssociationReflection)
        end
      end
    end
  end
end
