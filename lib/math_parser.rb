# Taken from http://lukaszwrobel.pl/blog/math-parser-part-3-implementation
module MathParser

  class Token
    Plus     = 0
    Minus    = 1
    Multiply = 2
    Divide   = 3

    Number   = 4

    LParen   = 5
    RParen   = 6

    MOD      = 7
    GThan    = 8
    LThan    = 9
    Equal    = 10
    NotEqual = 11
    GThanE   = 12
    LThanE   = 13

    End      = 14

    attr_accessor :kind
    attr_accessor :value

    def initialize
      @kind = nil
      @value = nil
    end

    def unknown?
      @kind.nil?
    end
  end

  class Lexer
    def initialize(input)
      @input = input
      @return_previous_token = false
    end

    def get_next_token
      if @return_previous_token
	@return_previous_token = false
	return @previous_token
      end

      token = Token.new

      @input.lstrip!

      case @input
      when /\A\+/ then
	token.kind = Token::Plus
      when /\A-/ then
	token.kind = Token::Minus
      when /\A\*/ then
	token.kind = Token::Multiply
      when /\Adiv/ then
	token.kind = Token::Divide
      when /\A\// then
	token.kind = Token::Divide
      when /\A\d+(\.\d+)?/
	token.kind = Token::Number
	token.value = $&.to_f
      when /\A\(/
	token.kind = Token::LParen
      when /\A\)/
	token.kind = Token::RParen
      when ''
	token.kind = Token::End
      when /\Ae/
	token.kind = Token::Number
	token.value = 2.718281828459
      when /\Api/
	token.kind = Token::Number
	token.value = 3.1415926535898
      when /\Amod/
	token.kind = Token::MOD
      when /\A!=/
	token.kind = Token::NotEqual
      when /\A<>/
	token.kind = Token::NotEqual
      when /\A>=/
	token.kind = Token::GThanE
      when /\A>/
	token.kind = Token::GThan
      when /\A<=/
	token.kind = Token::LThanE
      when /\A</
	token.kind = Token::LThan
      when /\A=/
	token.kind = Token::Equal
      end

      raise "Unknown token #{@input}" if token.unknown?
      @input = $'

      @previous_token = token
      token
    end

    def revert
      @return_previous_token = true
    end
  end

  class Parser
    def parse(input)
      @lexer = Lexer.new(input)

      expression_value = expression
      token = @lexer.get_next_token
      if token.kind == Token::End
	expression_value
      else
	case token.kind
        when Token::GThan
	  expression_value > expression ? 1 : 0
	when Token::LThan
	  expression_value < expression ? 1 : 0
	when Token::Equal
	  expression_value == expression ? 1 : 0
	when Token::NotEqual
	  expression_value != expression ? 1 : 0
	when Token::GThanE
	  expression_value >= expression ? 1 : 0
	when Token::LThanE
	  expression_value <= expression ? 1 : 0
	else
	  raise 'End expected'
	end
      end
    end

    protected
    def expression
      component1 = factor

      additive_operators = [Token::Plus, Token::Minus]

      token = @lexer.get_next_token
      while additive_operators.include?(token.kind)
	component2 = factor

	if token.kind == Token::Plus
	  component1 += component2
	else
	  component1 -= component2
	end

	token = @lexer.get_next_token
      end
      @lexer.revert

      component1
    end

    def factor
      factor1 = number

      multiplicative_operators = [Token::Multiply, Token::Divide, Token::MOD]

      token = @lexer.get_next_token
      while multiplicative_operators.include?(token.kind)
	factor2 = number

	if token.kind == Token::Multiply
	  factor1 *= factor2
	elsif token.kind == Token::MOD
	  factor1 %= factor2
	else
	  factor1 /= factor2
	end

	token = @lexer.get_next_token
      end
      @lexer.revert

      factor1
    end

    def number
      token = @lexer.get_next_token

      if token.kind == Token::LParen
	value = expression

	expected_rparen = @lexer.get_next_token
	raise 'Unbalanced parenthesis' unless expected_rparen.kind == Token::RParen
      elsif token.kind == Token::Number
	value = token.value
      else
	raise 'Not a number'
      end

      value
    end
  end

end
