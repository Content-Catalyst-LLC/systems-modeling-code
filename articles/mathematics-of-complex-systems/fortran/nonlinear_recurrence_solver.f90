program nonlinear_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 120
  integer :: time_index
  real(8) :: r_value
  real(8) :: trajectory_one
  real(8) :: trajectory_two
  real(8) :: difference_value

  r_value = 3.9d0
  trajectory_one = 0.4000d0
  trajectory_two = 0.4001d0

  print '(A)', 'time,trajectory_1,trajectory_2,absolute_difference'

  do time_index = 1, n_steps
    if (time_index > 1) then
      trajectory_one = r_value * trajectory_one * (1.0d0 - trajectory_one)
      trajectory_two = r_value * trajectory_two * (1.0d0 - trajectory_two)
    end if

    difference_value = abs(trajectory_one - trajectory_two)

    print '(I0,A,F12.8,A,F12.8,A,F12.8)', &
      time_index, ',', trajectory_one, ',', trajectory_two, ',', difference_value
  end do

end program nonlinear_recurrence_solver
