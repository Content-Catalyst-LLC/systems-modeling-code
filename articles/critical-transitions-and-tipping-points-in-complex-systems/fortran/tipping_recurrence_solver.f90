program tipping_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 300
  integer :: index_value
  integer :: transition_flag
  real(8) :: x_value
  real(8) :: previous_x
  real(8) :: r_value
  real(8) :: dt
  real(8) :: jump_size
  real(8) :: jump_threshold
  real(8) :: r_start
  real(8) :: r_end
  real(8) :: r_step

  x_value = -1.0d0
  dt = 0.05d0
  jump_threshold = 0.15d0
  r_start = -1.20d0
  r_end = 1.20d0
  r_step = (r_end - r_start) / real(n_steps - 1, 8)

  print '(A)', 'step,control_parameter,system_state,jump_size,transition_flag'

  do index_value = 1, n_steps
    r_value = r_start + real(index_value - 1, 8) * r_step
    previous_x = x_value

    if (index_value > 1) then
      x_value = x_value + dt * (r_value + x_value - x_value * x_value * x_value)
    end if

    jump_size = abs(x_value - previous_x)

    if (jump_size > jump_threshold) then
      transition_flag = 1
    else
      transition_flag = 0
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,I0)', &
      index_value, ',', r_value, ',', x_value, ',', jump_size, ',', transition_flag
  end do

end program tipping_recurrence_solver
