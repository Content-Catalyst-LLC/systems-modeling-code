program resilience_recurrence_solver
  implicit none
  integer, parameter :: n_steps = 180
  integer :: time_index
  real(8) :: state_value, adaptive_capacity, shock_value, performance_value
  real(8) :: erosion_rate, learning_gain, capacity_floor, shock_multiplier
  state_value = 0.0d0
  adaptive_capacity = 0.22d0
  erosion_rate = 0.0009d0
  learning_gain = 0.0007d0
  capacity_floor = 0.03d0
  shock_multiplier = 1.0d0
  print '(A)', 'time,state,absolute_state,adaptive_capacity,shock,performance'
  do time_index = 1, n_steps
    shock_value = 0.0d0
    if (time_index == 25) shock_value = 1.5d0 * shock_multiplier
    if (time_index == 55) shock_value = 1.7d0 * shock_multiplier
    if (time_index == 90) shock_value = 2.0d0 * shock_multiplier
    if (time_index == 125) shock_value = 2.2d0 * shock_multiplier
    if (time_index == 155) shock_value = 2.5d0 * shock_multiplier
    if (time_index > 1) then
      adaptive_capacity = max(capacity_floor, adaptive_capacity - erosion_rate + learning_gain * max(0.0d0, 1.0d0 - abs(state_value)))
      state_value = state_value - adaptive_capacity * state_value + shock_value
    end if
    performance_value = max(0.0d0, 1.0d0 - abs(state_value) / 4.0d0)
    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', time_index, ',', state_value, ',', abs(state_value), ',', adaptive_capacity, ',', shock_value, ',', performance_value
  end do
end program resilience_recurrence_solver
