program delayed_feedback_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 100
  integer :: time_index
  integer :: observed_index

  real(8) :: target
  real(8) :: state(n_steps)
  real(8) :: perceived(n_steps)
  real(8) :: intervention(n_steps)
  real(8) :: counterresponse(n_steps)
  real(8) :: correction_strength
  real(8) :: counterresponse_strength
  real(8) :: perception_smoothing
  real(8) :: natural_pressure
  real(8) :: observed_gap
  integer :: delay_length

  target = 50.0d0
  delay_length = 6
  correction_strength = 0.24d0
  counterresponse_strength = 0.42d0
  perception_smoothing = 0.55d0

  state = 0.0d0
  perceived = 0.0d0
  intervention = 0.0d0
  counterresponse = 0.0d0

  state(1) = 80.0d0
  perceived(1) = 80.0d0

  print '(A)', 'time,state,perceived_state,target,intervention,counterresponse'

  do time_index = 1, n_steps
    if (time_index > 1) then
      perceived(time_index) = perception_smoothing * state(time_index - 1) + &
        (1.0d0 - perception_smoothing) * perceived(time_index - 1)

      observed_index = time_index - delay_length
      if (observed_index < 1) then
        observed_index = 1
      end if

      observed_gap = perceived(observed_index) - target
      intervention(time_index) = correction_strength * max(0.0d0, observed_gap)
      counterresponse(time_index) = counterresponse_strength * intervention(time_index)
      natural_pressure = 2.0d0 + 0.025d0 * state(time_index - 1)

      state(time_index) = max(0.0d0, state(time_index - 1) + natural_pressure + &
        counterresponse(time_index) - intervention(time_index))
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', state(time_index), ',', perceived(time_index), ',', target, ',', intervention(time_index), ',', counterresponse(time_index)
  end do

end program delayed_feedback_recurrence_solver
