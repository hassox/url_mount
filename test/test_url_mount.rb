require 'helper'

class TestUrlMount < Test::Unit::TestCase
  should "initialize with a path and options" do
    u = UrlMount.new("/some/path", :some => "options")
    assert_equal u.raw_path, "/some/path"
    assert_equal u.options,  :some => "options"
  end

  context "required variables" do
    should "calculate the required variables of the mount as an emtpy array when there are none" do
      u = UrlMount.new("/foo")
      assert_equal [], u.required_variables
    end

    should "calculate the required variables as part of the variables when there are none" do
      u = UrlMount.new("/foo")
      assert_equal( {:required => [], :optional => []}, u.variables )
    end

    should "calculate the required variables when there are some" do
      u = UrlMount.new("/foo/:bar/baz/:homer")
      assert_equal [:bar, :homer], u.required_variables
      assert_equal( {:required => [:bar, :homer], :optional => []}, u.variables )
    end

    should "generate a static url mount" do
      u = UrlMount.new("/foo/bar")
      assert_equal "/foo/bar", u.to_s
    end

    should "generate a dynamic url with static and variable segments" do
      u = UrlMount.new("/foo/:bar/baz/:barry")
      assert_equal "/foo/bar/baz/sue", u.to_s(:bar => "bar", :barry => "sue")
    end

    should "raise an exception when a required variable is missing" do
      u = UrlMount.new("/foo/:bar/:baz")
      assert_raises UrlMount::Ungeneratable do
        u.to_s(:bar => "baz")
      end
    end
  end

  context "optional variables" do
    should "calculate the optional varialbles of the mount as an emtpy array when there are none" do
      u = UrlMount.new("/foo/bar")
      assert_equal [], u.optional_variables
    end

    should "calculate optional variables when there are some" do
      u = UrlMount.new("/foo(/:bar(/:baz))")
      assert_equal [:bar, :baz], u.optional_variables
    end

    should "calculate optional variables when there are some" do
      u = UrlMount.new("/foo(/:bar(/:baz))")
      assert_equal "/foo/gary", u.to_s(:bar => "gary")
    end

    should "skip nested optional variables when the optional parent is not present" do
      u = UrlMount.new("/foo(/:bar(/:baz))")
      assert_equal "/foo", u.to_s(:baz => "sue")
    end
  end

  context "complex compound urls" do
    should "generate complex urls containing multiple nested conditionals and multiple required variables" do
      u = UrlMount.new("/foo(/:bar(/:baz))/:gary")
      assert_equal "/foo/gary",           u.to_s(:gary => "gary")
      assert_equal "/foo/bar/gary",       u.to_s(:gary => "gary", :bar => "bar")
      assert_equal "/foo/bar/baz/gary",   u.to_s(:gary => "gary", :bar => "bar", :baz => "baz")
      assert_raises UrlMount::Ungeneratable do
        u.to_s(:bar => "bar")
      end
    end
  end

  context "nested url mounts" do
    should "allow a mount to accept a mount" do
      u1 = UrlMount.new("/root/:bar")
      u2 = UrlMount.new("/baz/barry")
      u1.url_mount = u2
    end

    should "generate the mount" do
      u1 = UrlMount.new("/root/bar")
      u2 = UrlMount.new("/baz/barry")
      u1.url_mount = u2
      assert "/root/bar", u1.to_s
      assert "/root/bar/baz/barry", u2.to_s
    end
  end
end
