# frozen_string_literal: true

module Setsy
  class Configuration
    extend ActiveModel::Naming
    include ActiveModel::Model
    include ActiveModel::Serializers::JSON

    def self.readers
      @readers ||= {}
    end

    def self.reader(name, &block)
      readers[name] = block
      readers
    end

    def self.from_set(record, set, readers = {})
      settings = {}
      set = set.dup.with_indifferent_access
      record.class.setsy_default.each do |k, v|
        result = {}
        result[:value] = v.is_a?(Hash) ? v[:value] : v
        result[:default] = result[:value]
        result[:value] = set[k] if set[k]
        settings[k] = Attribute.new(result)
      end
      new(record, settings, readers)
    end

    def initialize(record, settings, readers = {})
      @record = record
      @settings = settings

      @attributes = {}
      write_readers(readers)
    end

    def method_missing(m, *args, &block)
      if @settings.key?(m)
        if @settings[m].is_a?(Hash)
          @settings[m][:value]
        else
          @settings[m]
        end
      elsif respond_to?("setting__#{m}")
        send("setting__#{m}")
      else
        super
      end
    end

    def attributes
      keys = @settings.keys
      keys.push(*methods.select { |m| m.to_s.starts_with?('setting__') }.map { |m| m.to_s.gsub('setting__', '') })
      h = {}
      keys.each do |k|
        h[k.to_sym] = k
      end
      h
    end

    private

    def write_readers(readers)
      readers.each do |k, v|
        write_reader(k, v)
      end
    end

    def value_for(k)
      if @record.class.setsy_default[k].is_a?(Hash)
        @record.class.setsy_default[k][:value]
      else
        @record.class.setsy_default[k]
      end.class
    end

    def write_reader(k, v)
      class_eval do
        define_method("setting__#{k}") do
          instance_eval &v
        end
      end
    end
  end
end
