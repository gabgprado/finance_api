module Api
  module V1
    class TransactionsController < ApplicationController
      before_action :set_transaction, only: %i[show update destroy]

      def index
        @transactions = TransactionFilterService.new(current_user, filter_params).call
        render_api(@transactions)
      end

      def show
        authorize @transaction
        standard_show(@transaction)
      end

      def create
        @transaction = current_user.transactions.build(transaction_params)
        authorize @transaction
        if @transaction.save
          standard_create(@transaction)
        else
          render_json_api_msg_errors('Erro ao criar transação', @transaction.errors.full_messages.join(', '), 422)
        end
      end

      def update
        authorize @transaction
        if @transaction.update(transaction_params)
          render_api(@transaction)
        else
          render_json_api_msg_errors('Erro ao atualizar transação', @transaction.errors.full_messages.join(', '), 422)
        end
      end

      def destroy
        authorize @transaction
        @transaction.destroy
        head :no_content
      end

      private

      def set_transaction
        @transaction = Transaction.find(params[:id])
      end

      def transaction_params
        create_params(%i[amount description transaction_type date account_id category_id])
      end

      def filter_params
        {
          account_id: params[:account_id],
          category_id: params[:category_id],
          transaction_type: params[:transaction_type],
          start_date: params[:start_date],
          end_date: params[:end_date],
          page: params[:page],
          per_page: params[:per_page]
        }
      end
    end
  end
end
