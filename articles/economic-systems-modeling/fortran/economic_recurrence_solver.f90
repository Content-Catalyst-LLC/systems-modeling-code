program economic_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 120
  integer :: step_index
  real(8) :: output_value
  real(8) :: capital_value
  real(8) :: debt_value
  real(8) :: government_value
  real(8) :: consumption_value
  real(8) :: investment_value
  real(8) :: new_credit_value
  real(8) :: repayment_value
  real(8) :: shock_value
  real(8) :: noise_value
  real(8) :: fragility_value
  real(8) :: debt_service_value
  real(8) :: demand_gap_value
  real(8) :: demand_sensitivity
  real(8) :: investment_sensitivity
  real(8) :: interest_rate
  real(8) :: depreciation
  real(8) :: credit_sensitivity

  output_value = 100.0d0
  capital_value = 190.0d0
  debt_value = 60.0d0
  government_value = 22.0d0

  demand_sensitivity = 0.62d0
  investment_sensitivity = 0.16d0
  interest_rate = 0.035d0
  depreciation = 0.045d0
  credit_sensitivity = 0.10d0

  print '(A)', 'time,output,consumption,investment,capital,debt,debt_service,fragility,government,demand_gap'

  do step_index = 1, n_steps
    consumption_value = max(0.0d0, 18.0d0 + demand_sensitivity * output_value - 0.025d0 * debt_value)
    investment_value = max(0.0d0, investment_sensitivity * output_value - interest_rate * debt_value)

    if (step_index > 1) then
      capital_value = max(0.0d0, capital_value + investment_value - depreciation * capital_value)
      new_credit_value = max(0.0d0, credit_sensitivity * investment_value)
      repayment_value = 0.025d0 * debt_value
      debt_value = max(0.0d0, debt_value + new_credit_value - repayment_value)

      if (step_index == 70) then
        shock_value = -8.0d0
      else
        shock_value = 0.0d0
      end if

      noise_value = sin(real(step_index, 8) * 1.61803398875d0) * 0.35d0
      output_value = max(0.0d0, 0.33d0 * capital_value + consumption_value + government_value + shock_value + noise_value)
    end if

    debt_service_value = interest_rate * debt_value
    fragility_value = debt_value / max(capital_value, 1.0d0)
    demand_gap_value = output_value - consumption_value - investment_value - government_value

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      step_index, ',', output_value, ',', consumption_value, ',', investment_value, ',', capital_value, ',', debt_value, ',', debt_service_value, ',', fragility_value, ',', government_value, ',', demand_gap_value
  end do

end program economic_recurrence_solver
