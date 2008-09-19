require File.dirname(__FILE__) + '/../test_helper'

class WmlControllerTest < ActionController::TestCase
  # I don't think I need this, but I'm leaving it for the moment
  def escape(text)
    return text.gsub('/', '//')
  end
  
  def setup
    #foo = WmlController.new
  end
  
  ## formatting
  def test_formatting
    foo = WmlController.new
    tests = {
      '{{bold}}'                      => '${BBOLD}',
      '{{/bold}}'                     => '${EBOLD}',
      '{{bold}}filler text{{/bold}}'  => '${BBOLD}filler text${EBOLD}',
    }
    
    tests.each { |in_, out| assert_equal out, foo.send(:wml, in_) }
  end
  
  ## basic equations
  def test_basic_equations
    foo = WmlController.new
    tests = {}
    
    tests['inline'] = {
      '==x+3=='       => '\(x+3\)',
    }
    tests['block'] = {
      '==|x+3=='      => '\[x+3\]',
    }
    tests['exponents'] = {
      '==x**2=='      => '\(x^2\)',
    }
    tests['variables'] = {
      '==a=='         => '\($a\)',
      '==xyz=='       => '\($xyz\)',
      '==`a`=='       => '\($a\)',
      '==`xyz`=='     => '\($xyz\)',
    }
    tests['absolute value'] = {
      '== |52|=='     => '\(abs(52)\)',
      '==  |4|=='     => '\(abs(4)\)',
      '== |`a`|=='    => '\(abs($a)\)',
      '== 5+|-14|=='  => '\(5+abs(-14)\)',
    }
    
    tests.each do
      |key,test|
      test.each { |in_, out| assert_equal out, foo.send(:wml, in_) }
    end
  end

  ## fractions
  def test_fractions
    foo = WmlController.new
    tests = {}
    
    tests['numerator'] = {
      '==a/b=='             => '\(\frac{a}{b}\)',
      '==5+a/b=='           => '\(\frac{5+a}{b}\)',
      '==5+ a/b=='          => '\(5+ \frac{a}{b}\)',
      '==5+ -a/b=='         => '\(5+ \frac{-a}{b}\)',
      '=={5+ a}/b=='        => '\(\frac{5+ a}{b}\)',
      '==(5+ a)/b=='        => '\(\frac{(5+ a)}{b}\)',
      '==(1*2)(5+a)/b=='    => '\(\frac{(1*2)(5+a)}{b}\)',
    }
    tests['denominator'] = {
      '==a/b=='             => '\(\frac{a}{b}\)',
      '==a/5+b=='           => '\(\frac{a}{5+b}\)',
      '==a/b +5=='          => '\(\frac{a}{b} +5\)',
      '==a/-b +5=='         => '\(\frac{a}{-b} +5\)',
      '==a/{b +5}=='        => '\(\frac{a}{b +5}\)',
      '==a/(b +5)=='        => '\(\frac{a}{(b +5)}\)',
      '==(5+a)/b(1*2)=='    => '\(\frac{(5+a)}{b(1*2)}\)',
    }
    tests['variables'] = {
      '==`a`/b=='           => '\(\frac{$a}{b}\)',
      '==`a`/`b`=='         => '\(\frac{$a}{$b}\)',
      '==5+ `a`/b=='        => '\(5+ \frac{$a}{b}\)',
      '==5+ -`a`/b=='       => '\(5+ \frac{-$a}{b}\)',
      '==5+`b`/2*`a`=='     => '\(\frac{5+$b}{2*$a}\)',
    }
    
    tests.each do
      |key,test|
      test.each { |in_, out| assert_equal out, foo.send(:wml, in_) }
    end
  end
  
  def test_database_options_list
    foo = WmlController.new
    tests = {}
    
    tests['http://production.xyztextbooks.com/database_options.php'] = {
      'subjects'  => "<option>Foo</option>\n<option>Bar</option>\n",
      'chapters'  => "<optgroup label=\"Foo\">\n<option>FooFoo</option>\n<option>FooBar</option>\n</optgroup>\n<optgroup label=\"Bar\">\n<option>BarFoo</option>\n<option>BarBar</option>\n</optgroup>\n",
      'sections'  => "<optgroup label=\"FooFoo\">\n<option>FooFooFoo</option>\n<option>FooFooBar</option>\n</optgroup>\n<optgroup label=\"FooBar\">\n<option>FooBarFoo</option>\n<option>FooBarBar</option>\n</optgroup>\n<optgroup label=\"BarFoo\">\n<option>BarFooFoo</option>\n<option>BarFooBar</option>\n</optgroup>\n<optgroup label=\"BarBar\">\n<option>BarBarFoo</option>\n<option>BarBarBar</option>\n</optgroup>\n",
    }
    
    tests.each do
      |key,test|
      # make sure scrape() returns *something*
      assert_not_nil foo.send(:scrape, key)
      # get the <option> lists
      lists = foo.send(:database_options_list, key)
      test.each { |in_, out| assert_equal out, lists[in_] }
    end
  end
end
