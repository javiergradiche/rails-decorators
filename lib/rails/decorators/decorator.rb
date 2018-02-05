module Rails
  module Decorators
    module Decorator
      def self.loader(roots)
        Proc.new do
          roots.each do |root|
            decorators = Dir.glob("#{root}/app/**/*.#{Rails::Decorators.extension}")
            decorators.sort!
            decorators.each { |d| require_dependency(d) }
          end
        end
      end

      def self.decorate(*targets, &module_definition)
        options = targets.extract_options!

        targets.each do |target|
          namespace = target.to_s.remove('::')
          decorator_name = "#{options[:with].to_s.camelize}#{namespace}Decorator"

          if target.const_defined?(decorator_name)
            # We are probably reloading in Rails development env if this happens
            next if !Rails.application.config.cache_classes

            raise(
              InvalidDecorator,
              <<-eos.strip_heredoc

                Problem:
                  #{decorator_name} is already defined in #{target.name}.
                Summary:
                  When decorating a class, Rails::Decorators dynamically defines
                  a module for prepending the decorations passed in the block. In
                  this case, the name for the decoration module is already defined
                  in the namespace, so decorating would redefine the constant.
                Resolution:
                  Please specify a unique `with` option when decorating #{target.name}.
              eos
            )
          end

          mod = Module.new do
            extend Rails::Decorators::Decorator
            module_eval(&module_definition)
          end
          instance_methods = mod.instance_methods - Object.public_instance_methods
          mixin = instance_methods.any? && !target.is_a?(Class)

          target.const_set(decorator_name, mod)

          if mixin
            target.mixed_into.each { |klass| mod.decorates(klass) }
            target.extend(Mixin)
          else
            mod.decorates(target)
          end

          nil
        end
      end

      def prepend_features(base)
        if instance_variable_defined?(:@_before_decorate_block)
          base.class_eval(&@_before_decorate_block)
        end

        super

        if const_defined?(:ClassMethodsDecorator)
          base
            .singleton_class
            .send(:prepend, const_get(:ClassMethodsDecorator))
        end

        if base.class == Module
          base.extend(Mixin)

          if instance_variable_defined?(:@_static_decorated_block)
            base.class_eval(&@_static_decorated_block)
          end
        elsif instance_variable_defined?(:@_decorated_block)
          base.class_eval(&@_decorated_block)
        end
      end

      def before_decorate(&block)
        instance_variable_set(:@_before_decorate_block, block)
      end

      def decorated(static: false, &block)
        ivar = static ? :@_static_decorated_block : :@_decorated_block
        instance_variable_set(ivar, block)
      end

      def class_methods(&class_methods_module_definition)
        mod = const_set(:ClassMethodsDecorator, Module.new)
        mod.module_eval(&class_methods_module_definition)
      end
      alias_method :module_methods, :class_methods

      def decorates(klass)
        klass.send(:prepend, self)
      end
    end
  end
end
