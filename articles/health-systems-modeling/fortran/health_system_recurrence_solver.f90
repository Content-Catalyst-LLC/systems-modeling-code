program health_system_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 120
  integer :: time_index
  real(8) :: capacity_value
  real(8) :: demand_value
  real(8) :: initial_demand_value
  real(8) :: trust_value
  real(8) :: backlog_value
  real(8) :: burnout_value
  real(8) :: pressure_value
  real(8) :: slack_value
  real(8) :: attrition_value
  real(8) :: surge_value
  real(8) :: effective_capacity_value
  real(8) :: served_value
  real(8) :: unmet_need_value
  real(8) :: access_gap_value
  real(8) :: prevention_reduction_value

  capacity_value = 100.0d0
  demand_value = 92.0d0
  initial_demand_value = 92.0d0
  trust_value = 0.64d0
  backlog_value = 0.0d0
  burnout_value = 0.12d0

  print '(A)', 'time,demand,capacity,effective_capacity,pressure,slack,burnout,attrition,served,unmet_need,backlog,access_gap,trust,surge_active'

  do time_index = 0, n_steps - 1
    pressure_value = demand_value / max(capacity_value, 1.0d0)
    slack_value = max(1.0d0 - pressure_value, 0.0d0)
    burnout_value = max(0.0d0, burnout_value + 0.085d0 * max(pressure_value - 1.0d0, 0.0d0) - 0.035d0 * slack_value)
    attrition_value = 0.030d0 * burnout_value * capacity_value

    if (time_index >= 45 .and. time_index <= 65) then
      surge_value = 18.0d0
    else
      surge_value = 0.0d0
    end if

    effective_capacity_value = max(0.0d0, capacity_value + 0.50d0 - attrition_value - 0.10d0 * max(pressure_value - 1.0d0, 0.0d0) * capacity_value)
    served_value = min(demand_value, effective_capacity_value)
    unmet_need_value = max(demand_value - served_value, 0.0d0)
    access_gap_value = 0.18d0 * demand_value + unmet_need_value
    backlog_value = max(0.0d0, backlog_value + demand_value - served_value)

    trust_value = trust_value + 0.012d0 * slack_value - 0.020d0 * max(pressure_value - 1.0d0, 0.0d0) - 0.004d0 * access_gap_value / max(demand_value, 1.0d0)
    trust_value = max(0.0d0, min(1.0d0, trust_value))

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,I0)', &
      time_index, ',', demand_value, ',', capacity_value, ',', effective_capacity_value, ',', &
      pressure_value, ',', slack_value, ',', burnout_value, ',', attrition_value, ',', &
      served_value, ',', unmet_need_value, ',', backlog_value, ',', access_gap_value, ',', &
      trust_value, ',', merge(1, 0, surge_value > 0.0d0)

    capacity_value = effective_capacity_value
    prevention_reduction_value = 0.015d0 * dble(time_index + 1)
    demand_value = max(0.0d0, initial_demand_value + 0.35d0 * dble(time_index + 1) + surge_value - prevention_reduction_value + 0.08d0 * backlog_value)
  end do

end program health_system_recurrence_solver
