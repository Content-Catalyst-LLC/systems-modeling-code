program public_policy_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 100
  integer :: time_index
  real(8) :: target_state_value
  real(8) :: system_state_value
  real(8) :: capacity_value
  real(8) :: trust_value
  real(8) :: burden_value
  real(8) :: policy_value
  real(8) :: side_effect_value
  real(8) :: uptake_value
  real(8) :: performance_gap_value
  real(8) :: next_state_value
  real(8) :: next_capacity_value
  real(8) :: next_burden_value
  real(8) :: next_side_effect_value
  real(8) :: next_trust_value

  target_state_value = 16.0d0
  system_state_value = 12.0d0
  capacity_value = 7.0d0
  trust_value = 0.58d0
  burden_value = 0.25d0
  policy_value = 1.0d0
  side_effect_value = 0.0d0

  print '(A)', 'time,system_state,performance_gap,policy_intensity,institutional_capacity,trust,administrative_burden,uptake,side_effect'

  do time_index = 0, n_steps - 1
    uptake_value = 0.42d0 + 0.30d0 * trust_value + 0.035d0 * capacity_value - 0.45d0 * burden_value
    uptake_value = max(0.0d0, min(1.0d0, uptake_value))

    performance_gap_value = target_state_value - system_state_value

    if (performance_gap_value > 0.0d0) then
      policy_value = min(2.0d0, policy_value + 0.08d0)
    else
      policy_value = max(0.25d0, policy_value - 0.05d0)
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', system_state_value, ',', performance_gap_value, ',', &
      policy_value, ',', capacity_value, ',', trust_value, ',', burden_value, ',', &
      uptake_value, ',', side_effect_value

    next_state_value = system_state_value + 0.55d0 * policy_value * uptake_value
    next_state_value = next_state_value - 0.12d0 * system_state_value + 0.05d0 * capacity_value

    next_capacity_value = capacity_value + 0.09d0 * (system_state_value - capacity_value)
    next_burden_value = max(0.0d0, burden_value + 0.05d0 * policy_value - 0.025d0 * capacity_value)
    next_side_effect_value = max(0.0d0, side_effect_value + 0.08d0 * policy_value - 0.06d0 * side_effect_value)
    next_trust_value = trust_value + 0.015d0 * uptake_value - 0.018d0 * next_burden_value - 0.010d0 * next_side_effect_value
    next_trust_value = max(0.0d0, min(1.0d0, next_trust_value))

    system_state_value = max(0.0d0, next_state_value)
    capacity_value = max(0.0d0, next_capacity_value)
    burden_value = next_burden_value
    side_effect_value = next_side_effect_value
    trust_value = next_trust_value
  end do

end program public_policy_recurrence_solver
