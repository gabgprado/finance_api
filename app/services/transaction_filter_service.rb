class TransactionFilterService
  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end

  def call
    transactions = @current_user.transactions
    transactions = transactions.by_account(@params[:account_id]) if @params[:account_id].present?
    transactions = transactions.by_category(@params[:category_id]) if @params[:category_id].present?
    transactions = transactions.by_type(@params[:transaction_type]) if @params[:transaction_type].present?

    if @params[:start_date].present? && @params[:end_date].present?
      transactions = transactions.by_period(@params[:start_date], @params[:end_date])
    end

    transactions = transactions.ordered
    
    page_number = @params[:page] || 1
    per_page_count = @params[:per_page] || 10

    transactions.page(page_number).per_page(per_page_count)
  end
end
