program sensitivity_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer :: time_index
  integer :: delayed_index
  integer :: recovery_delay
  integer :: shock_time

  real(8) :: state(n_steps)
  real(8) :: growth_rate
  real(8) :: carrying_capacity
  real(8) :: extraction_pressure
  real(8) :: feedback_strength
  real(8) :: shock_intensity
  real(8) :: delayed_recovery
  real(8) :: shock_effect
  real(8) :: previous_state
  real(8) :: next_state

  growth_rate = 0.08d0
  carrying_capacity = 100.0d0
  extraction_pressure = 0.025d0
  recovery_delay = 5
  feedback_strength = 0.020d0
  shock_intensity = 8.0d0
  shock_time = n_steps / 2

  state = 0.0d0
  state(1) = 10.0d0

  do time_index = 2, n_steps
    delayed_index = max(1, time_index - recovery_delay)
    delayed_recovery = feedback_strength * state(delayed_index)

    if (time_index == shock_time) then
      shock_effect = shock_intensity
    else
      shock_effect = 0.0d0
    end if

    previous_state = state(time_index - 1)

    next_state = previous_state + &
      growth_rate * previous_state * (1.0d0 - previous_state / carrying_capacity) - &
      extraction_pressure * previous_state + &
      delayed_recovery - &
      shock_effect

    state(time_index) = max(0.0d0, next_state)
  end do

  print '(A)', 'time,state,growth_rate,carrying_capacity,extraction_pressure,recovery_delay,feedback_strength,shock_intensity'

  do time_index = 1, n_steps
    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,I0,A,F12.6,A,F12.6)', &
      time_index, ',', state(time_index), ',', growth_rate, ',', carrying_capacity, ',', &
      extraction_pressure, ',', recovery_delay, ',', feedback_strength, ',', shock_intensity
  end do

end program sensitivity_recurrence_solver
