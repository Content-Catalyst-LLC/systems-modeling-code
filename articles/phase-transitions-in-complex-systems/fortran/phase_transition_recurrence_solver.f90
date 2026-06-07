program phase_transition_recurrence_solver
  implicit none

  integer, parameter :: n_points = 301
  integer :: point_index
  real(8) :: control_parameter
  real(8) :: stable_positive
  real(8) :: stable_negative
  real(8) :: order_magnitude
  character(len=24) :: phase_label

  print '(A)', 'step,control_parameter,stable_state_positive,stable_state_negative,neutral_state,order_parameter_magnitude,phase_label'

  do point_index = 1, n_points
    control_parameter = -1.5d0 + 3.0d0 * real(point_index - 1, 8) / real(n_points - 1, 8)

    if (control_parameter > 0.0d0) then
      stable_positive = sqrt(control_parameter)
      stable_negative = -sqrt(control_parameter)
      order_magnitude = stable_positive
      phase_label = 'two ordered phases'
    else
      stable_positive = 0.0d0
      stable_negative = 0.0d0
      order_magnitude = 0.0d0
      phase_label = 'single neutral phase'
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,A)', &
      point_index, ',', control_parameter, ',', stable_positive, ',', stable_negative, ',', 0.0d0, ',', order_magnitude, ',', trim(phase_label)
  end do

end program phase_transition_recurrence_solver
