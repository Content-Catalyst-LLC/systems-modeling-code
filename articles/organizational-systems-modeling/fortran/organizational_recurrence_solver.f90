program organizational_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 100
  integer :: time_index
  real(8) :: capacity_value
  real(8) :: workload_value
  real(8) :: initial_workload_value
  real(8) :: trust_value
  real(8) :: backlog_value
  real(8) :: burnout_value
  real(8) :: pressure_value
  real(8) :: slack_value
  real(8) :: learning_value
  real(8) :: coordination_burden_value
  real(8) :: attrition_value
  real(8) :: effective_capacity_value
  real(8) :: delivery_value

  capacity_value = 100.0d0
  workload_value = 95.0d0
  initial_workload_value = 95.0d0
  trust_value = 0.62d0
  backlog_value = 0.0d0
  burnout_value = 0.10d0

  print '(A)', 'time,capacity,workload,pressure,slack,learning,coordination_burden,burnout,attrition,trust,delivery,backlog'

  do time_index = 0, n_steps - 1
    pressure_value = workload_value / max(capacity_value, 1.0d0)
    slack_value = max(1.0d0 - pressure_value, 0.0d0)
    learning_value = 0.035d0 * capacity_value * slack_value * trust_value
    coordination_burden_value = 0.10d0 * max(pressure_value - 1.0d0, 0.0d0) * capacity_value
    burnout_value = max(0.0d0, burnout_value + 0.090d0 * max(pressure_value - 1.0d0, 0.0d0) - 0.040d0 * slack_value)
    attrition_value = 0.035d0 * burnout_value * capacity_value
    effective_capacity_value = max(0.0d0, capacity_value + 0.65d0 + learning_value - attrition_value - coordination_burden_value)
    delivery_value = min(workload_value, effective_capacity_value)
    backlog_value = max(0.0d0, backlog_value + workload_value - delivery_value)
    trust_value = trust_value + 0.010d0 * slack_value - 0.030d0 * max(pressure_value - 1.0d0, 0.0d0) - 0.005d0 * burnout_value
    trust_value = max(0.0d0, min(1.0d0, trust_value))

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', capacity_value, ',', workload_value, ',', pressure_value, ',', &
      slack_value, ',', learning_value, ',', coordination_burden_value, ',', &
      burnout_value, ',', attrition_value, ',', trust_value, ',', delivery_value, ',', backlog_value

    capacity_value = effective_capacity_value
    workload_value = initial_workload_value + 0.45d0 * dble(time_index + 1) + 0.10d0 * backlog_value
  end do

end program organizational_recurrence_solver
