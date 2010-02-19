require 'helper'

class TestUrlMount < Test::Unit::TestCase
  should "initialize with a path and options" do
    u = UrlMount.new("/some/path", :some => "options")
    assert_equal u.raw_path, "/some/path"
    assert_equal u.options,  :some => "options"
    assert_equal({:some => "options"}, u.defaults)
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
      u = UrlMount.new("/foo/:bar/baz/:homer", :bar => "bar", :homer => "homer")
      assert_equal [:bar, :homer], u.required_variables
      assert_equal( {:required => [:bar, :homer], :optional => []}, u.variables )
    end

    should "generate a static url mount" do
      u = UrlMount.new("/foo/bar")
      assert_equal "/foo/bar", u.to_s
    end

    should "generate a dynamic url with static and variable segments" do
      u = UrlMount.new("/foo/:bar/baz/:barry", :bar => "bar", :barry => "sue")
      assert_equal "/foo/bar/baz/sue", u.to_s
    end

    should "raise an exception when a required variable is missing" do
      assert_raises UrlMount::Ungeneratable do
        UrlMount.new("/foo/:bar/:baz")
      end
    end

    should "consume the options so the router does not use them" do
      opts = {:bar => "bar", :other => "other"}
      u = UrlMount.new("/foo/:bar", :bar => "some_default_bar")
      u.to_s(opts)
      assert_equal( {:bar => "bar", :other => "other"}, opts )
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

  context "default variables" do
    should "generate a simple url with a variable with a default" do
      u = UrlMount.new("/foo/:bar", :bar => "default")
      assert_equal "/foo/default", u.to_s
    end

    should "generate urls with multiple varilables using defaults" do
      u = UrlMount.new("/foo/:bar/:baz", :bar => "bar", :baz => "baz")
      assert_equal "/foo/bar/baz", u.to_s
    end

    should "generate urls with optional variables" do
      u = UrlMount.new("/foo(/:bar)", :bar => "bar")
      assert_equal "/foo/bar", u.to_s
    end

    should "generate urls with mixed variables" do
      u = UrlMount.new("/foo/:bar(/:baz(/:barry))", :barry => "bazz", :bar => "clue")
      assert_equal "/foo/clue", u.to_s
      assert_equal "/foo/clue/sue/bazz", u.to_s(:baz => "sue")
    end

    should "generate urls with overwritten defaults" do
      u = UrlMount.new("/foo/:bar(/:baz)", :bar => "barr", :baz => "bazz")
      assert_equal "/foo/sue/larry",  u.to_s(:bar => "sue", :baz => "larry")
      assert_equal "/foo/barr/gary",  u.to_s(:baz => "gary")
      assert_equal "/foo/harry/bazz", u.to_s(:bar => "harry")
    end
  end

  context "complex compound urls" do
    should "generate complex urls containing multiple nested conditionals and multiple required variables" do
      u = UrlMount.new("/foo(/:bar(/:baz))/:gary", :gary => "gary")
      assert_equal "/foo/gary",           u.to_s
      assert_equal "/foo/bar/gary",       u.to_s(:bar => "bar")
      assert_equal "/foo/bar/baz/gary",   u.to_s(:bar => "bar", :baz => "baz")
    end
  end

  context "nested url mounts" do
    should "allow a mount to accept a mount" do
      u1 = UrlMount.new("/root/:bar", :bar => "bar")
      u2 = UrlMount.new("/baz/barry")
      u1.url_mount = u2
    end

    should "generate the mount" do
      u1 = UrlMount.new("/root/bar")
      u2 = UrlMount.new("/baz/barry")
      u2.url_mount = u1
      assert_equal "/root/bar", u1.to_s
      assert_equal "/root/bar/baz/barry", u2.to_s
    end

    should "overwrite a parents options" do
      u1 = UrlMount.new("/root/:bar", :bar => "bar")
      u2 = UrlMount.new("/baz/barry")
      u2.url_mount = u1
      assert_equal "/root/different/baz/barry", u2.to_s(:bar => "different")
    end

    should "not consume params to nested routes" do
      u1 = UrlMount.new("/root/:bar",   :bar => "bar")
      u2 = UrlMount.new("/baz/:barry",  :barry => "barry")
      u2.url_mount = u1
      opts = {:bar => "sue", :barry => "wendy"}
      assert_equal "/root/sue/baz/wendy", u2.to_s(opts)
      assert_equal({:bar => "sue", :barry => "wendy"}, opts)
    end
  end
end
