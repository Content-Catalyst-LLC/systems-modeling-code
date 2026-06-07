program urban_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 100
  integer :: step_index
  real(8) :: population_value
  real(8) :: housing_value
  real(8) :: transport_value
  real(8) :: service_capacity_value
  real(8) :: accessibility_value
  real(8) :: congestion_value
  real(8) :: housing_gap_value
  real(8) :: service_pressure_value
  real(8) :: policy_investment_value
  real(8) :: population_change_value

  population_value = 100.0d0
  housing_value = 112.0d0
  transport_value = 90.0d0
  service_capacity_value = 120.0d0

  print '(A)', 'time,population,housing,transport,service_capacity,accessibility,congestion,housing_gap,service_pressure,policy_investment'

  do step_index = 1, n_steps
    accessibility_value = transport_value / (1.0d0 + 0.010d0 * population_value)
    congestion_value = population_value / max(transport_value, 1.0d0)
    housing_gap_value = max(population_value - housing_value, 0.0d0)
    service_pressure_value = population_value / max(service_capacity_value, 1.0d0)

    if (mod(step_index, 20) == 0) then
      policy_investment_value = 8.0d0
    else
      policy_investment_value = 0.0d0
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      step_index, ',', population_value, ',', housing_value, ',', transport_value, ',', &
      service_capacity_value, ',', accessibility_value, ',', congestion_value, ',', &
      housing_gap_value, ',', service_pressure_value, ',', policy_investment_value

    population_change_value = 1.10d0 + 1.25d0 * accessibility_value / 55.0d0
    population_change_value = population_change_value - 0.70d0 * max(congestion_value - 1.0d0, 0.0d0)
    population_change_value = population_change_value - 0.45d0 * housing_gap_value / 20.0d0
    population_change_value = population_change_value - 0.70d0 * max(service_pressure_value - 1.0d0, 0.0d0)

    population_value = max(0.0d0, population_value + population_change_value)
    housing_value = max(0.0d0, housing_value + 0.65d0 + 0.020d0 * population_value - 0.004d0 * housing_value)
    transport_value = max(1.0d0, transport_value + 0.45d0 + 0.010d0 * housing_value - 0.030d0 * max(congestion_value - 1.0d0, 0.0d0))
    service_capacity_value = max(1.0d0, service_capacity_value + 0.35d0 + policy_investment_value - 0.003d0 * service_capacity_value)
  end do

end program urban_recurrence_solver
