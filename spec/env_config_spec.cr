require "./spec_helper"

class BasicConfig
  include EnvConfig

  getter string : String
  getter int : Int32
  getter float : Float64
  getter boolean : Bool
end

class ConfigWithDefaults
  include EnvConfig

  getter string : String = "foo"
  getter int : Int32 = 2
  getter float : Float64
end

class ConfigWithIgnoredSettings
  include EnvConfig

  getter not_ignored : String

  @[EnvConfig::Setting(ignore: true)]
  getter ignored : String = "foobar"
end

class ConfigWithKeyOverrides
  include EnvConfig

  @[EnvConfig::Setting(key: "foo")]
  getter string : String = "foo"

  getter int : Int32 = 2
  getter float : Float64 = 1
end

class NestedConfig
  include EnvConfig

  getter sub : SubConfig

  class SubConfig
    include EnvConfig

    getter foo : String
    getter bar : String = "sub_bar"
  end
end

class ConfigWithConverters
  include EnvConfig

  @[EnvConfig::Setting(converter: ConfigWithConverters::DateConverter)]
  getter date : Time

  module DateConverter
    def self.from_env(value)
      Time.parse(value, "%Y-%m-%d", location: Time::Location.load("UTC"))
    end
  end
end

describe EnvConfig do
  Spec.before_each do
    ENV.clear
  end

  context "BasicConfig" do
    it "reads string values from ENV" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["FLOAT"] = "2"
      ENV["BOOLEAN"] = "1"

      BasicConfig.new(ENV).string.should eq("test")
    end

    it "reads int values from ENV" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["FLOAT"] = "2"
      ENV["BOOLEAN"] = "1"

      BasicConfig.new(ENV).int.should eq(3)
    end

    it "reads float values from ENV" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["FLOAT"] = "2"
      ENV["BOOLEAN"] = "1"

      BasicConfig.new(ENV).float.should eq(2.0)
    end

    it "fails if a required ENV var is missing" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["BOOLEAN"] = "1"

      expect_raises(KeyError) do
        BasicConfig.new(ENV)
      end
    end

    it "reads boolean values from truthy ENV values" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["FLOAT"] = "2"

      %w[1 true TRUE True 42 foo].each do |value|
        ENV["BOOLEAN"] = value
        BasicConfig.new(ENV).boolean.should be_true
      end
    end

    it "reads boolean values from falsey ENV values" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["FLOAT"] = "2"

      %w[0 false].each do |value|
        ENV["BOOLEAN"] = value
        BasicConfig.new(ENV).boolean.should be_false
      end
    end

    it "sets boolean values to false if the ENV var was not found" do
      ENV["STRING"] = "test"
      ENV["INT"] = "3"
      ENV["FLOAT"] = "2"

      BasicConfig.new(ENV).boolean.should be_false
    end
  end

  context "ConfigWithIgnoredSettings" do
    it "doesn't set values for ignored settings from ENV" do
      ENV["NOT_IGNORED"] = "foo"
      ENV["IGNORED"] = "bar"

      ConfigWithIgnoredSettings.new(ENV).ignored.should eq("foobar")
    end
  end

  context "ConfigWithDefaults" do
    it "requires only ENV vars for which there is no default" do
      ENV["FLOAT"] = "2"

      ConfigWithDefaults.new(ENV)
    end

    it "fails if a required ENV var is missing" do
      expect_raises(KeyError) do
        ConfigWithDefaults.new(ENV)
      end
    end
  end

  context "ContextWithKeyOverrides" do
    it "reads values from overridden ENV vars" do
      ENV["FOO"] = "test"

      ConfigWithKeyOverrides.new(ENV).string.should eq("test")
    end
  end

  context "BasicConfig with prefix" do
    it "reads values from ENV vars prepended with given prefix" do
      ENV["TEST_STRING"] = "foo"
      ENV["TEST_INT"] = "1"
      ENV["TEST_FLOAT"] = "2"
      ENV["TEST_BOOLEAN"] = "1"

      BasicConfig.new(ENV, prefix: "test").string.should eq("foo")
    end
  end

  context "NestedConfig" do
    it "prepends ENV vars for nested values with the name of the nesting" do
      ENV["SUB_FOO"] = "test"

      NestedConfig.new(ENV).sub.foo.should eq("test")
    end
  end

  context "ConfigWithConverters" do
    it "uses given converters to convert the value from the ENV var" do
      ENV["DATE"] = "2018-07-25"

      ConfigWithConverters.new(ENV).date.should eq(
        Time.new(2018, 7, 25, location: Time::Location.load("UTC"))
      )
    end
  end
end
