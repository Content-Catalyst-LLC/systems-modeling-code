program leverage_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 96
  integer :: time_index

  real(8) :: baseline_state
  real(8) :: parameter_state
  real(8) :: feedback_state
  real(8) :: rule_state
  real(8) :: goal_state

  real(8) :: baseline_pressure
  real(8) :: parameter_pressure
  real(8) :: feedback_pressure
  real(8) :: rule_pressure
  real(8) :: goal_pressure

  baseline_state = 70.0d0
  parameter_state = 70.0d0
  feedback_state = 70.0d0
  rule_state = 70.0d0
  goal_state = 70.0d0

  baseline_pressure = 50.0d0
  parameter_pressure = 50.0d0
  feedback_pressure = 50.0d0
  rule_pressure = 50.0d0
  goal_pressure = 50.0d0

  print '(A)', 'time,baseline_state,parameter_state,feedback_state,rule_state,goal_state'

  do time_index = 1, n_steps
    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', baseline_state, ',', parameter_state, ',', feedback_state, ',', rule_state, ',', goal_state

    call step_system(baseline_state, baseline_pressure, 0.96d0, 2.0d0, 0.0d0)
    call step_system(parameter_state, parameter_pressure, 0.96d0, 5.0d0, 0.0d0)
    call step_system(feedback_state, feedback_pressure, 0.78d0, 2.0d0, 0.0d0)

    if (rule_state > 45.0d0) then
      call step_system(rule_state, rule_pressure, 0.70d0, 2.0d0, 0.0d0)
    else
      call step_system(rule_state, rule_pressure, 0.96d0, 2.0d0, 0.0d0)
    end if

    if (goal_state > 45.0d0) then
      call step_system(goal_state, goal_pressure, 0.72d0, 8.0d0, 0.10d0)
    else
      call step_system(goal_state, goal_pressure, 0.90d0, 8.0d0, 0.10d0)
    end if
  end do

contains

  subroutine step_system(system_state, system_pressure, feedback_gain, correction, goal_weight)
    implicit none
    real(8), intent(inout) :: system_state
    real(8), intent(inout) :: system_pressure
    real(8), intent(in) :: feedback_gain
    real(8), intent(in) :: correction
    real(8), intent(in) :: goal_weight
    real(8) :: resilience
    real(8) :: next_pressure
    real(8) :: next_state
    real(8) :: effective_correction

    resilience = 35.0d0 + 100.0d0 * goal_weight
    effective_correction = correction + 0.05d0 * max(0.0d0, system_state - 40.0d0)

    next_pressure = max(0.0d0, 0.91d0 * system_pressure + 0.07d0 * system_state - 0.30d0 * effective_correction - 0.04d0 * resilience)
    next_state = max(0.0d0, feedback_gain * system_state + 0.24d0 * next_pressure - 0.34d0 * effective_correction - 0.045d0 * resilience)

    system_pressure = next_pressure
    system_state = next_state
  end subroutine step_system

end program leverage_recurrence_solver
