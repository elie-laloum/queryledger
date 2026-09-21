# frozen_string_literal: true
module QueryLedger
  class Error < StandardError; end
  class BudgetExceeded < Error; end
end
