module Api
  module V1
    class MortgageApplicationsController < ApplicationController
      before_action :set_application, only: [ :show ]

      def index
        @applications = MortgageApplication.all
        render json: @applications, status: :ok
      end

      def create
        @application = MortgageApplication.create(application_params)

        if @application.save
          render json: @application, status: :created
        else
          render json: { errors: @application.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        render json: @application, status: :ok
      end

      private

      def set_application
        @application = MortgageApplication.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Mortgage Application not found" }, status: :not_found
      end

      def application_params
        params.expect(mortgage_application: [ :annual_income, :monthly_expenses, :deposit_amount, :property_value, :term_years ])
      end
    end
  end
end