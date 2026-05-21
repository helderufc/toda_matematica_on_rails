class QuestionSerializer
  include Alba::Resource

  attributes :id, :statement, :points, :order_num

  many :alternatives, resource: AlternativeSerializer
end
