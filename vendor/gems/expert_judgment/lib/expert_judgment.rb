require "expert_judgment/version"

module ExpertJudgment

  # Expert Judgment gem definition
  class ExpertJudgment
    attr_accessor :effort_per_hour, :minimum, :most_likely, :maximum, :probable

    def initialize(elem)
      @effort_per_hour = elem[:effort_per_hour]
      set_minimum(elem)
      set_maximum(elem)
      set_most_likely(elem)
    end

    def set_minimum(elem)
      @minimum = elem[:minimum].to_f
    end

    def set_maximum(elem)
      @maximum = elem[:maximum].to_f
    end

    def set_most_likely(elem)
      @most_likely = elem[:most_likely].to_f
    end

    def set_probable
      ( (@minimum + (4*@most_likely) + @maximum) / 6 ).to_f
    end

    #Set the WBS-activity node elements effort using aggregation (sum) of child elements (from the bottom up)
    def set_node_effort_per_hour(node)

    end


    #GETTERS
    def get_effort_per_hour
      @effort_per_hour
    end

  end

end