module Neoid
  module ModelAdditions
    module ClassMethods
      attr_reader :neoid_config
      attr_reader :neoid_options
      
      def neoid_config
        @neoid_config ||= Neoid::ModelConfig.new(self)
      end
      
      def neoidable(options = {})
        yield(neoid_config) if block_given?
        @neoid_options = options
      end
    
      def neo_index_name
        @index_name ||= "#{self.name.tableize}_index"
      end

      def neo_search_index_name
        @search_index_name ||= "#{self.name.tableize}_search_index"
      end
    end
  
    module InstanceMethods
      def to_neo
        if self.class.neoid_config.stored_fields
          self.class.neoid_config.stored_fields.inject({}) { |all, field|
            all[field] = self.send(field) rescue (raise "No field #{field} for #{self.class.name}")
            all
          }
        else
          {}
        end
      end

      protected
      def neo_properties_to_hash(*attribute_list)
        attribute_list.flatten.inject({}) { |all, property|
          all[property] = self.send(property)
          all
        }
      end

      private
      def _neo_representation
        @_neo_representation ||= begin
          results = neo_find_by_id
          if results
            neo_load(results.first['self'])
          else
            node = neo_create
            node
          end
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      Neoid.models << receiver
    end
  end
end
