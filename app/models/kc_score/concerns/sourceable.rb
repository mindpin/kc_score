module KcScore
  module Concerns
    module Sourceable
      extend ActiveSupport::Concern

      included do
        include Mongoid::Document
        include Mongoid::Timestamps

        cattr_accessor :sourceable_collect
      end

      module ClassMethods
        # 不限制评价分数
        # act_as_score_sourceable :target
        # 限制评价分数
        # act_as_score_sourceable :target => [-1, 0, 1]
        # act_as_score_sourceable :target => -1..1

        def act_as_score_sourceable(*fields, &block)
          options = fields.extract_options!

          self.sourceable_collect ||= {}
          selfkey = self.name.underscore
          self.sourceable_collect[selfkey] ||= {}

          if options.blank?
            # no hash maybe array
            fields.each do |key|
              self.sourceable_collect[selfkey][key] = nil

              key.to_s.camelize.constantize.class_eval do
                include KcScore::Concerns::Targetable
              end
            end
          else
            options.each do |key, val|
              case val.class.name
              when 'Array', 'Range'
                self.sourceable_collect[selfkey][key] = val.to_a

                key.to_s.camelize.constantize.class_eval do
                  include KcScore::Concerns::Targetable
                end
              when 'NilClass'
                self.sourceable_collect[selfkey][key] = nil

                key.to_s.camelize.constantize.class_eval do
                  include KcScore::Concerns::Targetable
                end
              else
              end
            end
          end

          has_many :scores, as: :score_sourceable, class_name: 'KcScore::Score'

          define_method :score_it do |target, score, text = nil|
            # TODO 判断限制
            scores.create score_targetable: target, score: score, text: text
          end

          define_method :scored? do |target|
            scores.where(score_targetable: target).any?
          end
        end
      end
    end
  end
end
