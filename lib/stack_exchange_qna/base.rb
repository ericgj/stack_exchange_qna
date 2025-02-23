module StackExchangeQnA
  class Base < Hashie::Mash
    class << self
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
