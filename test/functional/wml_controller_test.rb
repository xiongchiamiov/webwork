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
    
    tests.each { |in_, out| assert_equal out, foo.wml(in_) }
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
    
    tests.each do
      |key,test|
      test.each { |in_, out| assert_equal out, foo.wml(in_) }
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
    
    tests.each do
      |key,test|
      test.each { |in_, out| assert_equal out, foo.wml(in_) }
    end
  end
end
