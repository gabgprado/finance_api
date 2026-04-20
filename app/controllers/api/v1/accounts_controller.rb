module Api
  module V1
    class AccountsController < ApplicationController
      before_action :set_account, only: %i[show update destroy]

      def index
        @accounts = query_prepare(policy_scope(Account))
        standard_index(@accounts)
      end

      def show
        authorize @account
        standard_show(@account)
      end

      def create
        @account = current_user.accounts.build(account_params)
        authorize @account
        if @account.save
          standard_create(@account)
        else
          render_json_api_msg_errors('Erro ao criar conta', @account.errors.full_messages.join(', '), 422)
        end
      end

      def update
        authorize @account
        if @account.update(account_params)
          render_api(@account)
        else
          render_json_api_msg_errors('Erro ao atualizar conta', @account.errors.full_messages.join(', '), 422)
        end
      end

      def destroy
        authorize @account
        @account.destroy
        head :no_content
      end

      private

      def set_account
        @account = Account.find(params[:id])
      end

      def account_params
        create_params(%i[name account_type balance currency])
      end
    end
  end
end
