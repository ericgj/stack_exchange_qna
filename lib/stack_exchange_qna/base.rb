module StackExchangeQnA

  # Not sure it's advisable to subclass Hashie::Mash. 
  # Could you instead delegate to an internal instance of Hashie::Mash 
  # (composition instead of subclass)?  See note on `method_missing` below.
  class Base < Hashie::Mash
    class << self
    
      # Why does `#all` return the parsed response wrapped in a QueryMethods object, 
      # but `#find` returns the parsed response?  See note on `QueryMethods#each`
      def all(options={})
        response = make_request(resource_name, options)
        collection = parse_response_collection(response)

        QueryMethods.new(self, :collection => collection,
                               :total => response["total"],
                               :page => response["page"],
                               :pagesize => response["pagesize"])
      end

      def find(id)
        response = make_request("#{resource_name}/#{id}")

        parse_response_collection(response).first
      end

      def where(hash)
        QueryMethods.new(self).where(hash)
      end

      def pagesize(number)
        QueryMethods.new(self).pagesize(number)
      end

      def page(number)
        QueryMethods.new(self).page(number)
      end

      def includes(*args)
        QueryMethods.new(self).includes(*args)
      end

      def order(option)
        QueryMethods.new(self).order(option)
      end

      def resource_name
        single_resource_name.pluralize
      end

      def single_resource_name
        self.name.demodulize.underscore
      end

      # You might want to consider `include HTTParty` in your Base class.
      # This lets you declare parts of the URL rather than having to build the url 
      # string manually, and does the query hash to string conversion, etc.
      # Examples here: 
      #    https://github.com/jnunemaker/httparty/tree/master/examples
      #
      # Here is my own example (Posterous API):
      #    https://github.com/ericgj/posterous2nanoc/blob/master/posterous/client.rb
      #
      # Otherwise, if you just need a HTTP client, Net::HTTP or open-uri are 
      # probably faster than HTTParty and do just as well and are included in Ruby
      #
      def make_request(end_point, options={})
        client = StackExchangeQnA.client
        options.merge!(:key => client.api_key)

        HTTParty.get("http://#{client.site}/#{StackExchangeQnA::Client::API_VERSION}/#{end_point}?#{query_string(options)}")
      end

      private

      def query_string(params)
        params.map{ |param, value| "#{param}=#{value}" }.join("&")
      end

      def parse_response_collection(response)
        response[resource_name].map{ |r| self.new(r) }
      end
    end

    # Hashie::Mash depends on method_missing to work, so doesn't this break its functionality?
    def method_missing(method_name, *args, &block)
      return super unless respond_to? association_url(method_name)

      association_class = "StackExchangeQnA::#{method_name.to_s.classify}".constantize
      response = self.class.make_request(self.send(association_url(method_name)))
      self[method_name] = response[method_name.to_s].map{ |r| association_class.new(r) }
    end

    def respond_to?(method_name)
      return true if self.key? association_url(method_name)

      super
    end

    def association_url(method_name)
      "#{self.class.single_resource_name}_#{method_name}_url"
    end
  end
end
