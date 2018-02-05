require 'test_helper'

class DecorateTest < Minitest::Test
  module TestModule
    def self.foo
      'bar'
    end

    def bar
      'wonder'
    end
  end

  class TestClass
    include TestModule

    def self.foo
      'bar'
    end

    def foo
      'bar'
    end
  end

  module Namespace
    class TestClass < TestClass
      def foo
        'baz'
      end
    end
  end

  class DifferentTestClass
    def bar
      'hershey bar'
    end
  end

  class ChildClass < TestClass
  end

  module StaticModule
    mattr_accessor :foo
    self.foo = :bar

    def foo
      'bar'
    end
  end

  class StaticModuleMixinTarget
    include StaticModule

    def foo
      "#{super} baz"
    end
  end

  decorate(TestClass, with: 'testing') do
    class_methods do
      def foo
        "#{super}|baz"
      end
    end

    before_decorate { alias_method :foobar, :foo }
    decorated { attr_reader :test }

    def foo
      "#{super}|baz"
    end
  end

  decorate(ChildClass, with: 'testing') do
    def baz
      'decorated'
    end
  end

  decorate(Namespace::TestClass, with: 'testing') do
    def foo
      'namespace decorated'
    end
  end

  def test_decorate
    assert(TestClass.new.respond_to?(:test))
    assert_equal('bar|baz', TestClass.new.foo)
    assert_equal('bar|baz', TestClass.foo)
    assert_equal('bar', TestClass.new.foobar)
  end

  def test_subclass_decoration
    assert_equal('decorated', ChildClass.new.baz)
  end

  def test_decorating_within_a_namespace
    assert_equal('namespace decorated', Namespace::TestClass.new.foo)
  end

  def test_module_definition
    decorate(TestClass, with: 'more_tests') {}
    assert(TestClass.const_defined?(:MoreTestsDecorateTestTestClassDecorator))
  end

  def test_module_class_methods_decoration
    decorate(TestModule, with: 'tests') do
      class_methods do
        def foo
          "wonder #{super}"
        end

        def bar
          'baz'
        end
      end
    end

    assert_equal('wonder bar', TestModule.foo)
    assert_equal('baz', TestModule.bar)
  end

  def test_decorators_array
    decorate(TestClass, with: 'collection') {}
    decorators = TestClass.decorators.map(&:to_s)

    refute_includes(decorators, 'BasicObject')
    assert_includes(decorators, 'DecorateTest::TestClass::CollectionDecorateTestTestClassDecorator')
  end

  class SomeOtherClass
    def bar
      'hello'
    end
  end

  def test_mixin_module_decoration
    SomeOtherClass.include(TestModule)

    decorate(TestModule, with: 'mixin') do
      def bar
        "#{super} bar"
      end
    end

    DifferentTestClass.include(TestModule)

    assert_includes(TestModule.mixed_into, TestClass)
    assert_includes(TestModule.mixed_into, DifferentTestClass)

    assert_equal('hershey bar', DifferentTestClass.new.bar)
    assert_equal('wonder bar', TestClass.new.bar)
    assert_equal('hello bar', SomeOtherClass.new.bar)
  end

  def test_static_decoration
    decorate(StaticModule, with: 'static') do
      decorated static: true do
        mattr_accessor :baz
        self.baz = :bat
      end
    end

    target = StaticModuleMixinTarget.new

    assert_equal(:bar, StaticModule.foo)
    assert_equal(:bat, StaticModule.baz)
    assert_equal('bar baz', target.foo)
  end
end
