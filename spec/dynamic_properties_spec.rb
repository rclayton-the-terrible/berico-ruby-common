require "rspec"
require_relative "../dynamic_properties"

module Berico

  class BasicDynoClass
    include DynamicProperties
  end

  describe DynamicProperties do

    context "Utility Methods" do

      context "create_name_parser" do

        it "should return the identity lambda when supplied an empty hash" do

          dp = BasicDynoClass.new
          name_parser = dp.create_name_parser({})
          expected = "method_name"
          name_parser.call(expected).should == expected

        end

        it "should return the prefix lambda when supplied the prefix key" do

          dp = BasicDynoClass.new
          prefix = "blah_"
          name_parser = dp.create_name_parser({:prefix => prefix})
          expected = "method_name"
          name_parser.call(prefix + expected).should == expected

        end

        it "should return the suffix lambda when supplied the suffix key" do

          dp = BasicDynoClass.new
          suffix = "_blah"
          name_parser = dp.create_name_parser({:suffix => suffix})
          expected = "method_name"
          name_parser.call(expected + suffix).should == expected

        end

        it "should return the regex lambda when supplied the match key" do

          dp = BasicDynoClass.new
          regex = /([a-z]{3}[0-9]{3})/
          name_parser = dp.create_name_parser({:matcher => regex})
          expected = "abc123"
          name_parser.call(expected).should == expected

        end

      end

      context "configure" do

        it "should merge a set of initial properties if provided on the configuration object" do

          class TestInitialPropertyClass
            include DynamicProperties
            def initialize
              configure({ :properties => { "name" => "Richard Clayton", :age => 30 }})
            end
          end

          test_object = TestInitialPropertyClass.new
          test_object.configured.should == true
          test_object.properties.length.should == 2
          test_object.name.should == "Richard Clayton"
          test_object.age.should == 30

        end

        it "should use a prefix for properties if the class is configured to use one" do

            class PrefixDynoClass
              include DynamicProperties
              def initialize
                configure({ :prefix => "p_" })
              end
            end

            prefix_object = PrefixDynoClass.new
            expected = "Richard Clayton"
            prefix_object.p_name = expected
            prefix_object.properties.length.should == 1
            prefix_object.p_name.should == expected

        end

        it "should use a suffix for properties if the class is configured to use one" do

          class SuffixDynoClass
            include DynamicProperties
            def initialize
              self.configure({ :suffix => "_prop" })
            end
          end

          suffix_object = SuffixDynoClass.new
          expected = "Richard Clayton"
          suffix_object.name_prop = expected
          suffix_object.properties.length.should == 1
          suffix_object.name_prop.should == expected

        end

        it "should use a regex for properties if the class is configured to use one" do

          class MatcherDynoClass
            include DynamicProperties
            def initialize
              self.configure({ :matcher => /p_(.*)_prop/ })
            end
          end

          regex_object = MatcherDynoClass.new
          expected = "Richard Clayton"
          regex_object.p_name_prop = expected
          regex_object.properties.length.should == 1
          regex_object.p_name_prop.should == expected

        end

      end

      context "Validation Functions" do

        it "should return whether a configuration hash is valid" do

          dp = BasicDynoClass.new

          dp.config_valid?({ :prefix => "prefix" }).should == true
          dp.config_valid?({ :prefix => 22 }).should_not == true

          dp.config_valid?({ :suffix => "suffix" }).should == true
          dp.config_valid?({ :suffix => true }).should_not == true

          dp.config_valid?({ :matcher => /abcdefg/ }).should == true
          dp.config_valid?({ :matcher => "matcher" }).should_not == true

        end

        it "should validate a key's existence and value's type within a hash" do

          dp = BasicDynoClass.new

          dp.valid_for_key?({ :prefix => "prefix" }, :prefix, String).should == true
          dp.valid_for_key?({ :suffix => "suffix" }, :prefix, String).should_not == true
          dp.valid_for_key?({ :prefix => 22 }, :prefix, String).should_not == true

        end

      end

    end

  end
end