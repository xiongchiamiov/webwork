class WmlController < ApplicationController
  
  layout 'base'
  
  def index
    #!!# THIS WILL GO ONCE STUFF IS BUILT
    @db_options = {
      'subjects'  => '',
      'chapter'   => '',
      'section'   => ''
    }
    
    @question = params[:question]
    params[:question] = params[:question].to_s + "\n==ans(8)=="
    
    if request.post?
      ## WML Parsing
      # array of things that need to be parsed through wml
      wml_needed = [:question, :answer_explanation]
      # array of things that only need basic parsing
      basic_parsing_needed = [:answer]
      
      # process them one at a time
      wml_needed.each {|chunk| params[chunk] = wml(params[chunk])}
      basic_parsing_needed.each {|chunk| params[chunk] = wml_basic(params[chunk])}
      ## end WML Parsing
      
      ## Build .pg File
      @pgFile = ''
      
      # if description has newlines, prepend ## to every line except first
      params[:description].gsub!("\n", "\n##") unless params[:description].nil?
      
      # add description block
      @pgFile += "## DESCRIPTION\n"
      @pgFile += "## #{params[:description]}\n"
      @pgFile += "## ENDDESCRIPTION\n\n"
      
      # surround commas with single quotes so that list items are quoted
      if !params[:keywords].nil?:
        params[:keywords].gsub!(",", "','")
      end
      
      @pgFile += "## DBsubject('#{params[:db_subject]}')\n";
      @pgFile += "## DBchapter('#{params[:db_chapter]}')\n";
      @pgFile += "## DBsection('#{params[:db_section]}')\n";
      @pgFile += "## Date('#{params[:problem_date]}')\n";
      @pgFile += "## Author('#{params[:problem_author]}')\n";
      @pgFile += "## Institution('#{params[:problem_institution]}')\n";
      @pgFile += "## TitleText1('#{params[:book_title]}')\n";
      @pgFile += "## EditionText1('#{params[:book_edition]}')\n";
      @pgFile += "## AuthorText1('#{params[:book_author]}')\n";
      @pgFile += "## Section1('#{params[:book_section]}')\n";
      @pgFile += "## Problem1('#{params[:book_problem]}')\n\n";
      
      @pgFile += "DOCUMENT();\n\n";
      
      #!!# THIS NEEDS TO BE AUTOMAGICALLY GENERATED BASED ON WHAT WE USE
      macroList = ['PGstandard', 'MathObjects']
      
      @pgFile += "loadMacros(\n";
      macroList.each {|macro| @pgFile += "\"#{macro}.pl\",\n"}
      @pgFile += ");\n\n";
      
      @pgFile += "Context(\"Numeric\");\n\n";
      
      # assign random numbers to variables
      params[:variable_name].to_a.each do |key, name|
        if params[:variable_low[key]] != nil:
          @pgFile += "\$#{name} = random(#{params[:variable_low[key]]},#{params[:variable_high[key]]},#{params[:variable_incrementor[key]]});\n"
        else
          @pgFile += "\$#{name} = list_random(#{params[:variable_list[key]]});\n"
        end
      end
      
      @pgFile += "\nTEXT(beginproblem());\n"
      @pgFile += "Context()->texStrings;\n"
      @pgFile += "BEGIN_TEXT\n"
      @pgFile += "#{params[:question]}\n"
      @pgFile += "END_TEXT\n"
      @pgFile += "Context()->normalStrings;\n\n"
      
      @pgFile += "ANS(Compute(\"$answer\")->cmp());\n"
      
      @pgFile += "Context()->texStrings;\n"
      @pgFile += "SOLUTION(EV3(<<'END_SOLUTION'));\n"
      @pgFile += "#{params[:answer_explanation]}\n"
      @pgFile += "END_SOLUTION\n"
      @pgFile += "Context()->normalStrings;\n\n"
      
      @pgFile += 'ENDDOCUMENT();'
      ## end Build .pg File
    end
    
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
    
    @question_type = params[:question_type]
    
    @answer = params[:answer]
    @answer_explanation = params[:answer_explanation]
    
    @db_options = database_options_list()
    ## end Request Variables
  end
  
  ## AJAX
  def addVariable
    render :partial => 'addVariable', :locals => { :params => params }
  end
  
  #########
  private #
  #########
  
  def wml(input_text)
    text = input_text.to_s.dup
    
    curlies = [[],[]]
    equals = [[],[]]
    curlies[0] = text.scan(/\{\{.*?\}\}/)
    equals[0] = text.scan(/==.*==/)
    
    curlies[0].each do |curlyBlock|
      # trim brackets off the ends
      result = curlyBlock.gsub(/^\{+|\}+$/, '')
      result = curly(result)
      
      curlies[1].push result
    end unless curlies[0].blank?
    
    equals[0].each do |equalsBlock|
      # trim brackets off the ends
      result = equalsBlock.gsub(/^=+|=+$/, '')
      result = equals(result)
      
      equals[1].push result
      
      #!!# use %r{[pattern]}?
      # add delimiters around each $curlyBlock for regex subst
      equalsBlock = '#' + equalsBlock + '#';
      # and escape out characters that throw a wrench in the regex-ing later
      find = ['+', '(', ')', '*', '|', '^']
      replace_with = ['\+', '\(', '\)', '\*', '\|', '\^']
      #equalsBlock.gsub!(find, replace)
      [find, replace_with].transpose.each do |search, replace|
        equalsBlock.gsub!(search, replace)
      end
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
  
  ## Helper Functions for wml()
  def curly(text)
    case text.downcase
      when 'par'
        return '${PAR}'
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
    require 'oniguruma'
    
    # check to see if equation's not supposed to be inline
    inline = text[0]!=124; # 124 is the pipe (|) character
    if !inline
      # remove | at beginning of string
      text = text.slice(1..-1)
    end
    
    # check if there's an answer box
    if text =~ /ans\([0-9]+\)/
      return '\{' + text.gsub('ans(', 'ans_rule(') + '\}'
    # is there a fraction?
    elsif text =~ /([a-zA-Z0-9\-\+`]|[{(].*[)}])+\/([a-zA-Z0-9\-\+`]|[{(].*[)}])+/
      # select out the numerator
      num = text.match('([a-zA-Z0-9\-+`]|[{(].*[)}])+(?=/([a-zA-Z0-9\-+`]|[{(].*[)}])+)')
      # and the denominator
      #denom = text.match('(?<=(([a-zA-Z0-9\-+`])|[\}\)])/)([a-zA-Z0-9\-+`]|[\{\(].*[\)\}])+')
      # ruby <1.9 doesn't have lookbehinds built-in, so we need oniguruma
      denom = Oniguruma::ORegexp.new('(?<=(([a-zA-Z0-9\-+`])|[\}\)])/)([a-zA-Z0-9\-+`]|[\{\(].*[\)\}])+').match(text)
      
      text.gsub!(/([a-zA-Z0-9\-\+`]|[{(].*[)}])+\/([a-zA-Z0-9\-\+`]|[{(].*[)}])+/, '\frac{'+num[0]+'}{'+denom[0]+'}')
      
      # remove any double curly brackets (meaning we used them to group expressions)
      if text =~ /\{\{/
        text.gsub!(/\{\{/, '{')
        text.gsub!(/\}\}/, '}')
      end
    # otherwise we'll assume what's in there is just a variable, assuming it's something perl will accept
    elsif text =~ %r{^[a-zA-Z^`][a-zA-Z0-9_]*$}
      text = '$' + text
    end
    
    # substitute all the variables that are included with backticks
    text = wml_basic(text)
    
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
    text.gsub!(%r{`([A-z][A-z0-9_]*?)`},'$\1') unless text.nil?
    
    # change carets to double-asterisks
    #text.gsub!('^', '**')
    # perl uses ** for exponents, but TeX uses ^
    # so in an equation, they need to be ^s
    # but if they're being used to calculate something, we'll have to use **s
    text.gsub!('**', '^') unless text.nil?
    
    return text
  end
  ## end Helper Functions for wml()
  
  ## Information Scraping
  # returns the html of url
  def scrape(url)
    require 'open-uri'
    
    return open(url).read
  end
  # we don't actually do anything with this yet
  def keywords()    
    html = scrape('http://hobbes.la.asu.edu/Holt/keywords.html')
    
    # remove everything before the first <br>
    match = html.match('<br>')
    html = match[0] + match.post_match
    # and everything after (and including) </body>
    match = html.match("\n</body>")
    html = match.pre_match
    
    # change into an option list
    html.gsub!('<br>&nbsp;', '<option>')
    html.gsub!("\n", "</option>\n")
    
    return html
  end
  # returns an array $html, of which keys 'subject', 'chapter' and 'section'
  # provide option lists for their respectives
  def database_options_list(site='http://hobbes.la.asu.edu/Holt/chaps-and-secs.html')    
    scraped_html = scrape(site)
    
    # remove everything before the first <p><b>
    match = scraped_html.match('<p><b>')
    scraped_html = match[0] + match.post_match
    # and everything after (and including) </body>
    match = scraped_html.match("\n</body>")
    scraped_html = match.pre_match
    
    html = {}
    
    ## Subjects Scraping
    # get all the matches and put them in a hash table
    subjects = scraped_html.scan %r{<p><b>'(.*?)'</b><br>}
    subjects.each { |subject| html['subjects'] = html['subjects'].to_s + "<option>#{subject}</option>\n" }
    ## end Subjects Scraping
    
    ## Chapters Scraping
    # divide into groupings so that each has one subject
    subjects = scraped_html.split("<p><b>")
    # get rid of the first element, since it holds junk we don't want
    subjects = subjects[1..-1]
    subjects.each do |subject|
      # add subject as a grouping label
      subject_name = subject.match("'(.*?)'</b><br>")
      html['chapters'] = html['chapters'].to_s + '<optgroup label="'+subject_name[1]+"\">\n"
      # then extract each chapter
      chapters = subject.scan %r{<i>'(.*?)'</i><br>}
      # and add them in as options
      chapters.each {|chapter| html['chapters'] = html['chapters'].to_s + "<option>#{chapter}</option>\n" }
      html['chapters'] += "</optgroup>\n"
    end
    ## end Chapters Scraping
    
    ## Sections Scraping
    # divide into groupings so that each one has one chapter
    chapters = scraped_html.split("<i>")
    # get rid of the first element, since it holds junk we don't want
    chapters = chapters[1..-1]
    chapters.each do |chapter|
      # add chapter as a grouping label
      chapter_name = chapter.match("'(.*?)'</i><br>")
      html['sections'] = html['sections'].to_s + '<optgroup label="'+chapter_name[1]+"\">\n"
      # then extract each section
      sections = chapter.scan %r{&nbsp;'(.*?)'<br>}
      # and add them in as options
      sections.each {|section| html['sections'] = html['sections'].to_s + "<option>#{section}</option>\n" }
      html['sections'] += "</optgroup>\n"
    end
    ## end Sections Scraping
    
    return html
  end
  ## end Information Scraping
end
