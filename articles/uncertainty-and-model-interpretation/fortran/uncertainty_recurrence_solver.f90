program uncertainty_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer :: time_index
  integer :: shock_time

  real(8) :: state
  real(8) :: growth_rate
  real(8) :: carrying_capacity
  real(8) :: extraction_pressure
  real(8) :: shock_intensity
  real(8) :: shock_effect

  growth_rate = 0.075d0
  carrying_capacity = 115.0d0
  extraction_pressure = 0.020d0
  shock_intensity = 14.0d0
  shock_time = 42
  state = 10.0d0

  print '(A)', 'time,state,growth_rate,carrying_capacity,extraction_pressure,shock_intensity,shock_time'

  do time_index = 1, n_steps
    if (time_index > 1) then
      if (time_index == shock_time) then
        shock_effect = shock_intensity
      else
        shock_effect = 0.0d0
      end if

      state = state + &
        growth_rate * state * (1.0d0 - state / carrying_capacity) - &
        extraction_pressure * state - &
        shock_effect

      state = max(0.0d0, state)
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,I0)', &
      time_index, ',', state, ',', growth_rate, ',', carrying_capacity, ',', &
      extraction_pressure, ',', shock_intensity, ',', shock_time
  end do

end program uncertainty_recurrence_solver
