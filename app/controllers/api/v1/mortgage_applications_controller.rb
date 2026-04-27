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
        case @application.status
        when "pending"
          @application.update!(status: "assessing")
          AffordabilityAssessmentJob.perform_later(@application.id)
          log_event("assessment_queued", @application.id)
          render json: { status: "assessing", message: "Assessment is being queued" }, status: :accepted
        when "assessing"
          render json: { status: "assessing", message: "Assessment is in progress" }, status: :accepted
        else # status = assessed
          render json: assessment_payload(@application), status: :ok
        end
      end

      private

      def log_event(name, application_id)
        Rails.logger.info({ event: name, application_id: application_id }.to_json)
      end

      def assessment_payload(application)
        {
          loan_to_value: application.loan_to_value,
          debt_to_income: application.debt_to_income,
          maximum_borrowing: application.maximum_borrowing,
          decision: application.decision,
          explanation: application.explanation,
          assessed_at: application.assessed_at
        }
      end

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
