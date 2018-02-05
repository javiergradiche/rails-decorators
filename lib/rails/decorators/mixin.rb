module Rails
  module Decorators
    # Functionality for mixin modules. Instead of decorating the module
    # at runtime, mixin decorations are applied when included into a
    # class.
    module Mixin
      # This method runs when the module is included into another
      # object, and is responsible for applying decorations into that
      # object if it's a `Class`.
      #
      # @return [Module] base - Object that the module is included into
      def append_features(base)
        super

        if base.class == Module
          base.extend(Mixin)
        else
          decorators.each { |decorator| decorator.decorates(base) }
        end
      end
    end
  end
end
