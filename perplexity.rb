require 'test/unit'

class TrigramRuleTest < Test::Unit::TestCase
  
  def test_should_know_probability_of_a_word_given_previous_two
    model = TrigramRule.new(:the)
    model.add_condition([:*, :*], 1)
    
    assert_equal 1, model.probability_given([:*, :*])
  end
  
  def test_can_add_multiple_rules_for_one_word
    model = TrigramRule.new(:STOP)
    model.add_condition([:cat, :walks], 1)
    model.add_condition([:dog, :walks], 0.5)
    
    assert_equal 1, model.probability_given([:cat, :walks])
    assert_equal 0.5, model.probability_given([:dog, :walks])
  end
    
end

class TrigramModelTest < Test::Unit::TestCase

  def test_should_know_probability_of_sentence
    model = TrigramModel.new
    model.add_rule(:the, [:*, :*], 1)
    model.add_rule(:dog, [:*, :the], 0.5)
    model.add_rule(:runs, [:the, :dog], 1)
    model.add_rule(:STOP, [:dog, :runs], 1)
    assert_equal 0.5, model.probability_of(:the, :dog, :runs, :STOP)
  end
    
end

class PerplexityTest < Test::Unit::TestCase
  
  def test_should_know_perplexity
    model = TrigramModel.new
    model.add_rule(:the, [:*, :*], 1)
    model.add_rule(:cat, [:*, :the], 0.5)
    model.add_rule(:STOP, [:cat, :walks], 1)
    model.add_rule(:STOP, [:dog, :runs], 1)
    model.add_rule(:dog, [:*, :the], 0.5)
    model.add_rule(:walks, [:the, :cat], 1)
    model.add_rule(:runs, [:the, :dog], 1)
    
    sentences = [
                  [:the, :dog, :runs, :STOP],
                  [:the, :cat, :walks, :STOP],
                  [:the, :dog, :runs, :STOP]
                ]
    
    perplixity = Perplexity.new(model)
    assert_equal 1.189, perplixity.calculate(sentences)
  end
  
end

class Perplexity
  
  def initialize(model)
    @model = model
  end
  
  def calculate(sentences)
    result = 0
    sentences.each do |s|
      result = result + Math.log2(@model.probability_of(*s))
    end
    (2**-(result / sentences.flatten.size)).round(3)
  end
  
end

class TrigramModel
  
  def initialize
    @rules = []
  end
  
  def add_rule(word, previous_two_words, probablity)
    rule = find_rule_for(word)
    @rules << rule = TrigramRule.new(word) unless rule
    rule.add_condition(previous_two_words, probablity)
  end
  
  def probability_of(*words)
    two_ago = :*
    one_ago = :*
    probabilities = []
    words.each do |word|
      probabilities << find_rule_for(word).probability_given([two_ago, one_ago])
      two_ago = one_ago
      one_ago = word
    end
    
    probabilities.inject(:*)
  end
  
  private 
  
  def find_rule_for(word)
    @rules.find{|r| r.word == word }
  end
  
end

class TrigramRule
  
  attr_reader :word
  
  def initialize(word)
    @word = word
    @conditions = {}
  end
  
  def add_condition(previous_two_words, probabilty)
    @conditions[previous_two_words] = probabilty
  end
  
  def probability_given(previous_two_words)
    @conditions[previous_two_words]
  end
  
end

