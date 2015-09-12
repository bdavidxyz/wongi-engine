module Wongi::Engine

  class Token

    include CoreExt

    attr_reader :children
    attr_reader :wme
    attr_reader :node
    attr_accessor :owner, :parent
    attr_reader :neg_join_results
    attr_reader :opt_join_results
    attr_reader :ncc_results
    attr_reader :generated_wmes
    attr_predicate :optional
    attr_predicate :deleted

    def initialize node, token, wme, assignments
      @node, @parent, @wme, @assignments = node, token, wme, assignments
      @children = []
      @deleted = false
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
      token.children << self if token
      wme.tokens << self if wme
    end

    def ancestors
      if parent
        parent.ancestors.unshift parent
      else
        []
      end
    end

    def subst variable, value
      @cached_assignments = nil
      if @assignments.has_key? variable
        @assignments[ variable ] = value
      end
    end

    def assignments
      @cached_assignments ||= all_assignments
    end

    def [] var
      if a = assignments[ var ]
        a.respond_to?(:call) ? a.call( self ) : a
      end
    end

    # TODO ignore assignments?
    def duplicate? other
      self.parent.equal?(other.parent) && @wme.equal?(other.wme) && self.assignments == other.assignments
    end

    def to_s
      str = "TOKEN [ parent=#{parent ? parent.object_id : 'nil'} "
      all_assignments.each_pair { |key, value| str << "#{key} => #{value} " }
      str << "]"
      str
    end

    def destroy
      # delete_children
      # #@node.tokens.delete self unless @node.kind_of?( NccPartner )
      # @wme.tokens.delete self if @wme
      # @parent.children.delete self if @parent

      # retract_generated
      deleted!
      # @node.delete_token self
    end

    # def delete_children
    #   children = @children
    #   @children = []
    #   children.each do |token|
    #     token.parent = nil
    #     token.destroy
    #   end
    # end

    # for neg feedback loop protection
    def generated? wme
      return true if generated_wmes.any? { |w| w == wme }
      return children.any? { |t| t.generated? wme }
    end

    protected

    # def retract_generated
    #   for_retraction = []

    #   @generated_wmes.dup.each do |wme|
    #     unless wme.manual?  # => TODO: does this ever fail at all?
    #       wme.generating_tokens.delete self
    #       if wme.generating_tokens.empty?
    #         for_retraction << wme
    #       end
    #     end
    #   end
    #   @generated_wmes = []
    #   for_retraction.each { |wme| wme.rete.retract wme, true }

    # end

    def all_assignments
      raise "Assignments is not a hash" unless @assignments.kind_of?( Hash )
      if @parent
        @parent.assignments.merge @assignments
      else
        @assignments
      end
    end

  end

  class FakeToken < Token
    def initialize token, wme, assignments
      @parent, @wme, @assignments = token, wme, assignments
      @children = []
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
    end
  end

end
