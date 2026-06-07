program early_warning_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 320
  integer :: time_index
  real(8) :: state_value
  real(8) :: stability_value
  real(8) :: noise_value
  real(8) :: stability_start
  real(8) :: stability_end
  real(8) :: noise_sd

  state_value = 0.0d0
  stability_start = 0.55d0
  stability_end = 0.985d0
  noise_sd = 1.0d0

  print '(A)', 'time,state,absolute_state,stability,deterministic_noise'

  do time_index = 1, n_steps
    stability_value = stability_start + (stability_end - stability_start) * real(time_index - 1, 8) / real(n_steps - 1, 8)
    noise_value = sin(real(time_index, 8) * 1.61803398875d0) * noise_sd

    if (time_index > 1) then
      state_value = stability_value * state_value + noise_value
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', state_value, ',', abs(state_value), ',', stability_value, ',', noise_value
  end do

end program early_warning_recurrence_solver
