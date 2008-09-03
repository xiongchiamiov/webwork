class WmlController < ApplicationController

  def index
    #!!# THIS WILL GO ONCE STUFF IS BUILT
    @db_options = {
      'subjects'  => '',
      'chapter'   => '',
      'section'   => ''
    }
    
    ## Request Variables
    @description = params[:description]
    
    @db_subject = params[:db_subject]
    @db_chapter = params[:db_chapter]
    @db_section = params[:db_section]
    
    @keywords = params[:keywords]
    
    @book_title = params[:book_title]
    @book_edition = params[:book_edition]
    @book_author = params[:book_author]
    @book_section = params[:book_section]
    @book_problem = params[:book_problem]
    
    @problem_author = params[:problem_author]
    @problem_institution = params[:problem_institution]
    @problem_date = params[:problem_date]
    
    @variable_name = params[:variable_name]
    @variable_low = params[:variable_low]
    @variable_high = params[:variable_high]
    @variable_incrementor = params[:variable_incrementor]
    @variable_list = params[:variable_list]
    
    #@question = params[:question]
    @question = params[:question].to_s + "\n==ans(8)=="
    @question_type = params[:question_type]
    
    @answer = params[:answer]
    @answer_explanation = params[:answer_explanation]
    ## end Request Variables
    
    if request.post?
      ## WML Parsing
      # array of things that need to be parsed through wml
      # make sure to assign references instead of copies
      wml_needed = [@question, @answer_explanation]
      # array of things that only need basic parsing
      basic_parsing_needed = [@answer]
      
      # process them one at a time
      wml_needed.each {|chunk| wml(chunk)}
      basic_parsing_needed.each {|chunk| wml_basic(chunk)}
      ## end WML Parsing
      
      ## Build .pg File
      @pgFile = ''
      
      # if description has newlines, prepend ## to every line except first
      @description.to_s.gsub!("\n", "\n##")
      
      # add description block
      @pgFile += "## DESCRIPTION\n"
      @pgFile += "## #{@description}\n"
      @pgFile += "## ENDDESCRIPTION\n\n"
      
      # surround commas with single quotes so that list items are quoted
      if @keywords != nil:
        @keywords.gsub!(",", "','")
      end
      
      @pgFile += "## DBsubject('#{@db_subject}')\n";
      @pgFile += "## DBchapter('#{@db_chapter}')\n";
      @pgFile += "## DBsection('#{@db_section}')\n";
      @pgFile += "## Date('#{@problem_date}')\n";
      @pgFile += "## Author('#{@problem_author}')\n";
      @pgFile += "## Institution('#{@problem_institution}')\n";
      @pgFile += "## TitleText1('#{@book_title}')\n";
      @pgFile += "## EditionText1('#{@book_edition}')\n";
      @pgFile += "## AuthorText1('#{@book_author}')\n";
      @pgFile += "## Section1('#{@book_section}')\n";
      @pgFile += "## Problem1('#{@book_problem}')\n\n";
      
      @pgFile += "DOCUMENT();\n\n";
      
      #!!# THIS NEEDS TO BE AUTOMAGICALLY GENERATED BASED ON WHAT WE USE
      macroList = ['PGstandard', 'MathObjects']
      
      @pgFile += "loadMacros(\n";
      macroList.each {|macro| @pgFile += "\"#{macro}.pl\",\n"}
      @pgFile += ");\n\n";
      
      @pgFile += "Context(\"Numeric\");\n\n";
      
      # assign random numbers to variables
      @variable_name.to_a.each do |key, name|
        if @variable_low[key] != nil:
          @pgFile += "\$#{name} = random(#{variable_low[key]},#{variable_high[key]},#{variable_incrementor[key]});\n"
        else
          $pgFile += "\$#{name} = list_random(#{variable_list[key]});\n"
        end
      end
      
      @pgFile += "\nTEXT(beginproblem());\n"
      @pgFile += "Context()->texStrings;\n"
      @pgFile += "BEGIN_TEXT\n"
      @pgFile += "$question\n"
      @pgFile += "END_TEXT\n"
      @pgFile += "Context()->normalStrings;\n\n"
      
      @pgFile += "ANS(Compute(\"$answer\")->cmp());\n"
      
      @pgFile += "Context()->texStrings;\n"
      @pgFile += "SOLUTION(EV3(<<'END_SOLUTION'));\n"
      @pgFile += "$answer_explanation\n"
      @pgFile += "END_SOLUTION\n"
      @pgFile += "Context()->normalStrings;\n\n"
      
      @pgFile += 'ENDDOCUMENT();'
      ## end Build .pg File
    end
  end
  
  def wml(text)
    curlies = text.to_s.scan('/{{.*?}}/')
    equals = text.to_s.scan('/==.*==/')
    
    curlies[0].each do |curlyBlock|
      # trim brackets off the ends
      result = curlyBlock.gsub('/^{+|}+$/', '')
      result = curly(result)
      
      curlies[1][] = result
      
      #!!# use %r{[pattern]}?
      # add delimiters around each $curlyBlock for regex subst
      curlyBlock = '|' + curlyBlock + '|'
    end unless curlies[0].blank?
    
    equals[0].each do |equalsBlock|
      # trim brackets off the ends
      result = equalsBlock.gsub('/^{+|}+$/', '')
      result = equals(result)
      
      equals[1][] = result
      
      #!!# use %r{[pattern]}?
      # add delimiters around each $curlyBlock for regex subst
      equalsBlock = '#' + equalsBlock + '#';
      # and escape out characters that throw a wrench in the regex-ing later
      find = ['+', '(', ')', '*', '|', '^']
      replace = ['\+', '\(', '\)', '\*', '\|', '\^']
      equalsBlock.gsub!(find, replace)
    end unless equals[0].blank?
    
    #text.gsub!(curlies[0].to_a, curlies[1].to_a)
    #text.gsub!(equals[0], equals[1])
    [curlies[0], curlies[1]].transpose.each do |search, replace|
      text.gsub!(search, replace)
    end unless curlies[0].blank?
    [equals[0], equals[1]].transpose.each do |search, replace|
      text.gsub!(search, replace)
    end unless equals[0].blank?
    
    return text
  end
  
  #########
  private #
  #########
  
  ## Helper Functions for wml()
  def curly(text)
    case text.downcase
      when 'par'
        return '$PAR'
      when 'bold'
        return '${BBOLD}'
      when '/bold'
        return '${EBOLD}'
      when 'center'
        return '${BCENTER}'
      when '/center'
        return '${ECENTER}'
      else
        return text
    end
  end
  
  def equals(text)
    # check to see if equation's not supposed to be inline
    inline = text[0]!='|';
    if !inline
      # remove | at beginning of string
      text = text.slice(1..-1)
    end
    
    # check if there's an answer box
    if text =~ 'ans\([0-9]+\)'
      return '\{' + text.gsub('ans(', 'ans_rule(') + '\}'
    # is there a fraction?
    elsif text =~ '([a-zA-Z0-9-+`]|[{(].*[)}])+/([a-zA-Z0-9-+`]|[{(].*[)}])+'
      # select out the numerator
      num = text.match('([a-zA-Z0-9\-+`]|[{(].*[)}])+(?=/([a-zA-Z0-9\-+`]|[{(].*[)}])+)')
      # and the denominator
      denom = text.match('(?<=(([a-zA-Z0-9-+`])|[})])/)([a-zA-Z0-9-+`]|[{(].*[)}])+')
      #!!# THIS NEEDS TO BE A SUBSTITUTION, NOT A REPLACEMENT
      $text = '\frac{'+num[0]+'}{'+denom[0]+'}'
      
      # remove any double curly brackets (meaning we used them to group expressions)
      if text =~ '{{'
        text.gsub!('/{{/', '{')
        text.gsub!('/}}/', '}')
      end
    # otherwise we'll assume what's in there is just a variable, assuming it's something perl will accept
    elsif text =~ '^[a-zA-Z^`][a-zA-Z0-9_]*$'
      text = '$' + text
    end
    
    # substitute all the variables that are included with backticks
    text = wml_basic($text)
    
    # set equation to be either inline or block
    if inline
      text = '\('+text+'\)'
    else
      text = '\['+text+'\]'
    end
    
    return text
  end
  
  def wml_basic(text)
    # substitute all the variables that are included with backticks
    text.gsub!(%r{`([A-z][A-z0-9_]*?)`},'\$\1') unless text.nil?
    
    # change carets to double-asterisks
    #text.gsub!('^', '**')
    # perl uses ** for exponents, but TeX uses ^
    # so in an equation, they need to be ^s
    # but if they're being used to calculate something, we'll have to use **s
    text.gsub!('**', '^') unless text.nil?
    
    return text
  end
  ## end Helper Functions for wml()
end