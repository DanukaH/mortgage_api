module Api
  module V1
    class MortgageApplicationsController < ApplicationController
      include Authenticatable

      before_action :set_application, only: [ :show, :assessment ]

      def index
        @applications = MortgageApplication.all
        render json: @applications, status: :ok
      end

      def create
        @application = MortgageApplication.new(application_params)

        if @application.save
          render json: @application, status: :created
        else
          render json: { errors: @application.errors.full_messages }, status: :unprocessable_content
        end
      end

      def show
        render json: @application, status: :ok
      end

      def assessment
        result = AffordabilityAssessor.new(@application).assess
        @application.update!(status: result[:decision])
        render json: result, status: :ok
      end

      private

      def set_application
        @application = MortgageApplication.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Mortgage Application not found" }, status: :not_found
      end

      def application_params
        params.require(:mortgage_application).permit([ :annual_income, :monthly_expenses, :deposit_amount, :property_value, :term_years ])
      end
    end
  end
end
