class Module
  # All objects that this module has been included in.
  #
  # @return [Array<Module>]
  def mixed_into
    @mixed_into ||= []
  end

  def included(base)
    mixed_into << base
    super if defined? super
  end

  # All ancestors of this object that are an extension of
  # +Rails::Decorators::Decorator+. Used in `#append_features` of mixin
  # modules to apply decorations to the class that the module is being
  # mixed into.
  #
  # @return [Array<Module>]
  def decorators
    ancestors.select do |ancestor|
      ancestor.is_a?(Rails::Decorators::Decorator)
    end
  end
end
