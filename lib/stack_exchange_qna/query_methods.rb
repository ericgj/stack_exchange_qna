class StackExchangeQnA::QueryMethods
  include Enumerable

  attr_reader :query_options

  def initialize(model, query_options={})
    @model = model
    @query_options = query_options
  end

  def where(hash)
    @query_options.merge!(hash)
    self
  end

  def pagesize(number)
    @query_options[:pagesize] = number
    self
  end

  def page(number)
    @query_options[:page] = number
    self
  end

  def includes(*args)
    @query_options.merge!(Hash[args.flatten.map{ |a| [a, true] }])
    self
  end

  def order(option)
    @query_options[:sort] = option
    @query_options[:sort], @query_options[:order] = option.first if option.is_a? Hash

    self
  end

  def total
    @query_options[:total] || load_data.total
  end

  # you don't need &block here, you can just yield(resource)
  def each(&block)
    # This seems convoluted to me. Why not instead cache load_data right here?
    # instead of caching it in Base.all and within the query_options hash?
    # i.e. simply
    #    load_data.each { |resource| yield(resource) }
    # and
    #    def load_data
    #      @collection ||= @model.all(@query_options)
    #    end
    #
    resources = @query_options[:collection] || load_data

    resources.each{ |resource| block.call(resource) }
  end

  private

  def load_data
    @model.all(@query_options)
  end
end
